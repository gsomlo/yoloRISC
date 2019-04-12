# verilog source files (other than "tb.v" and/or "top.v")
verilog_src = behav_srams.v dtm_stub.v simpleuart.v

# rocket-chip variant to build:
#rkt_config = DefaultConfig # too big even for 85k ECP5, b/c of FPU logic
rkt_config = DefaultFPGASmallConfig

# rocket-chip test harness top module:
rkt_topmod = TestHarness

gen_src_dir = rocket-chip/vsim/generated-src

rkt_vlg_pfx = rocket-chip/src/main/resources/vsrc
rkt_gen_pfx = $(gen_src_dir)/freechips.rocketchip.system

# rocket-chip dependencies provided as verilog source:
rkt_vlg_src = $(addprefix $(rkt_vlg_pfx)/, \
		AsyncResetReg.v EICG_wrapper.v plusarg_reader.v)

# rocket-chip scala-generated verilog files:
rkt_gen_src = $(addprefix $(rkt_gen_pfx)., \
		$(rkt_config).v $(rkt_config).behav_srams.v)

rocket-chip:
	# grab the upstream sources:
	git clone --recursive https://github.com/freechipsproject/$@
	# get bootrom to jump to DRAM_BASE (instead of spinning inside _hang):
	sed -i '/^_hang:/a \ \ j _start' $@/bootrom/bootrom.S
	make -C $@/bootrom

$(gen_src_dir): rocket-chip
	# generate verilog from chisel:
	make RISCV=${HOME}/RISCV -C $</vsim verilog CONFIG=$(rkt_config)
	# we want to use our own "module mem_(0_)?ext" behavioral srams:
	sed -ri 's/module mem_(0_)?ext/module disabled_mem_\1ext/' \
		$(rkt_gen_pfx).$(rkt_config).behav_srams.v
	# pass uart & led signals through MMIO module hierarchy:
	for i in TestHarness AXI4RAM_1 SimAXIMem_1 mem_0; do \
		sed -i \
	"/^module $$i(/a input uart_rx, output uart_tx, output [7:0] led," \
		$(rkt_gen_pfx).$(rkt_config).v ; \
	done
	for i in AXI4RAM_1 SimAXIMem_1 mem_0 mem_0_ext; do \
		sed -i \
	"/^  $$i /a .uart_rx(uart_rx), .uart_tx(uart_tx), .led(led)," \
		$(rkt_gen_pfx).$(rkt_config).v ; \
	done
	# some of the modules also need the reset signal:
	for i in mem_0; do \
		sed -i "/^module $$i(/a input reset," \
		$(rkt_gen_pfx).$(rkt_config).v ; \
	done
	for i in mem_0 mem_0_ext; do \
		sed -i "/^  $$i /a .reset(reset)," \
		$(rkt_gen_pfx).$(rkt_config).v ; \
	done

$(rkt_vlg_src): rocket-chip

$(rkt_gen_src): $(gen_src_dir)

%.elf: %.c start.S sections.lds
	riscv64-unknown-elf-gcc -mcmodel=medany -ffreestanding -nostdlib \
		-Wl,-Bstatic,-T,sections.lds,--strip-debug -o $@ \
		start.S $<  # NOTE: start.S MUST go before all other sources!

%.bin: %.elf
	riscv64-unknown-elf-objcopy -O binary $< $@

%.hex: %.bin
	python3 bin2hex64.py $^ 128 > $@

# inhibit step-by-step simulation register printouts:
sim_defs = -DPRINTF_COND=0

obj_dir = obj_dir
obj_lib = $(obj_dir)/V$(rkt_topmod)__ALL.a

$(obj_lib): $(rkt_vlg_src) $(rkt_gen_src) $(verilog_src)
	verilator --cc $(sim_defs) --trace --top-module $(rkt_topmod) $^
	make -C $(obj_dir) -f V$(rkt_topmod).mk

verilator_incdir = /usr/share/verilator/include

%.vrl: %.cpp $(obj_lib)
	g++ -o $@ -I $(obj_dir) -I $(verilator_incdir) \
		$< $(verilator_incdir)/verilated.cpp \
		$(verilator_incdir)/verilated_vcd_c.cpp $(obj_lib)

# run verilator simulation:
sim: tb.vrl firmware.hex
	./$<

trellis_dir = /usr/share/trellis

%.json: %.v $(rkt_vlg_src) $(rkt_gen_src) $(verilog_src) firmware.hex
	yosys -ql $*_synth.log -p "synth_ecp5 -json $@ -top chip_top" \
		$(filter %.v, $^)

%.config: %.json versa.lpf
	nextpnr-ecp5 --json $< --lpf $(word 2, $^) \
		--um5g-45k --freq 20 --textcfg $@

%.svf: %.config
	ecppack $< --svf $@

# program board (via jtag):
prog: top.svf
	openocd -f $(trellis_dir)/misc/openocd/ecp5-versa5g.cfg \
		-c "transport select jtag; init; svf $<; exit"

# no implicit removal of intermediate targets (.elf .bin .json .config):
.SECONDARY:

# explicitly clean intermediate targets only:
clean:
	rm -rf $(obj_dir) \
		$(addprefix firmware., elf bin) \
		$(addprefix top., json config)

cleaner: clean
	rm -rf tb.vrl tb.vcd firmware.hex top.svf top_synth.log

cleanall: cleaner
	make RISCV=${HOME}/RISCV -C rocket-chip/vsim clean

distclean: cleaner
	rm -rf rocket-chip

.PHONY: sim prog clean cleaner cleanall distclean
