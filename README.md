This is my work-in-progress repository for various experiments aimed at learning
to program FPGAs in VHDL using a very nice FPGA board called Terasic DE0-Nano.

At this moment the project contains a single test project, where I'm experimenting with simple implementations of:

# Key matrix scanner

This connects to a 4-row 4-column keypad bought for peanuts on eBay, and
works by pulling rows to 0 in a sequence and reading the columns after each
row is activated. The output is a vector with 1 bit per key.

# Key debouncer

This module takes the output from the scanner, and outputs a debounced copy.
Unfortunately, this is not enough to completely eliminate the mechanical
'wobbliness' of the keys, particularly on release.

# PWM LED controller

This allows smooth brightness control for the built in LEDs on the DE0-Nano,
using pulse-width modulation. Fairly mundane, but very helpful for testing.

# Simple UART

This turns two pins on the extension header (GPIO_024 and GPIO_025) into
receive and transmit pins of a 115200 N-8-1 UART. It's a very basic
implementation - there's no FIFO, no parity handling, baud rate is fixed and
stop bits are not being checked - but it will do the job as the means to
interact with other modules for testing purposes.

