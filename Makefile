# verilog source files (other than "tb.v" and/or "top.v")
verilog_src = behav_srams.v dtm_stub.v

# rocket-chip variant to build:
rkt_config = DefaultConfig

# rocket-chip test harness top module:
rkt_topmod = TestHarness

rkt_vlg_pfx = rocket-chip/src/main/resources/vsrc
rkt_gen_pfx = rocket-chip/vsim/generated-src/freechips.rocketchip.system

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
	#sed -i '/^_hang:/a \ \ j _start' $@/bootrom/bootrom.S
	#make -C $@/bootrom

$(rkt_vlg_src): rocket-chip

$(rkt_gen_src): rocket-chip
	# generate verilog from chisel:
	make RISCV=${HOME}/RISCV -C $</vsim verilog CONFIG=$(rkt_config)
	# we want to use our own "module mem_(0_)?ext" behavioral srams:
	sed -ri 's/module mem_(0_)?ext/module disabled_mem_\1ext/' \
		$(rkt_gen_pfx).$(rkt_config).behav_srams.v

# inhibit step-by-step simulation register printouts:
#sim_defs = -DPRINTF_COND=0

obj_dir = obj_dir
obj_lib = $(obj_dir)/V$(rkt_topmod)__ALL.a

$(obj_lib): $(rkt_vlg_src) $(rkt_gen_src) $(verilog_src)
	verilator_bin --cc $(sim_defs) --top-module $(rkt_topmod) $^
	make -C $(obj_dir) -f V$(rkt_topmod).mk

verilator_incdir = /usr/share/verilator/include

%.vrl: %.cpp $(obj_lib)
	g++ -o $@ -I $(obj_dir) -I $(verilator_incdir) \
		$< $(verilator_incdir)/verilated.cpp $(obj_lib)

# run iverilog simulation:
sim: tb.vrl
	./$<

# no implicit removal of intermediate targets (.elf .bin .json .config .bit):
.SECONDARY:

# explicitly clean intermediate targets only:
clean:
	rm -rf $(obj_dir)

cleaner: clean
	rm -rf tb.vrl

cleanall: cleaner
	make RISCV=${HOME}/RISCV -C rocket-chip/vsim clean

distclean: cleaner
	rm -rf rocket-chip

.PHONY: sim clean cleaner cleanall distclean
