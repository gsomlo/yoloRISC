#include <stdint.h>

#define reg_uart_clkdiv (*(volatile uint32_t*)0x60000000)
#define reg_uart_data   (*(volatile uint32_t*)0x60000004)
#define reg_led         (*(volatile  uint8_t*)0x60000008)

//#define SIMULATION

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
#ifndef SIMULATION
	// FIXME [gls]: minimum value we get away here should inform the
	// size of the buffer we need to use in the mmio behav_sram module!
	for (volatile int i = 0; i < 2000; i++);
#endif
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_uint_bin(unsigned int num)
{
	for (int i = 0; i < 32; i++, num <<= 1)
		putchar((num & 0x80000000) ? '1' : '0');
	putchar('\n');
}

// Simulation is much slower, so we want a much shorter delay.
// Uncomment the following line to see LED activity during simulation:


#ifdef SIMULATION
  #define DELAY 0x05
#else // FPGA synthesis
  #define DELAY 0x200000
#endif
void delay(void)
{
	for (volatile int i = 0; i < DELAY; i++);
}

int main(int argc, char *argv[])
{
	// 115200 baud at 55MHz
	reg_uart_clkdiv = 477;

	for (unsigned int i = 0;; i++) {
		print("Hello world!!!\n");
		reg_led = (i & 0xFF);
		print_uint_bin(i);
		delay();
		reg_led = 0x00;
		delay();
	}
}
