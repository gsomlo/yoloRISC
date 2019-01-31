#define REG_LED   0x60000008
#define STACK_PTR 0x80000400 /* code is cca. 512 bytes, so let's do 1K total */

.section .text
start:

  # Update LEDs
  li a0, REG_LED
  li a1, 0xAA
  sb a1, 0(a0)

  # Set stack pointer to end of *usable* RAM:
  li sp, STACK_PTR

  call main

loop:
  j loop
