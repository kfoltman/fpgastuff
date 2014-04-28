This is my work-in-progress repository for various experiments aimed at learning
to program FPGAs in VHDL using a very nice FPGA board called Terasic DE0-Nano.

At this moment the project contains a single test project, where I'm
experimenting with simple implementations of:

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

# Data encoder for WS2812B LED chain

This is just an initial attempt to implement the control protocol for WS2812B
'intelligent' RGB light emitting diodes. Those diodes are designed to allow
controlling a large number of them with a single control signal by the means
of daisy-chaining. The data are sent as a sequence of pulses with modulated
width. The first LED in the chain receives the first 24 bits and updates its
RGB intensities, then passes the rest of the data stream to the second LED,
which does the same, up until a 50 microsecond pause, which restarts the
whole process.

My WS2812B code takes a 50 MHz master clock and sends five 24-bit words down
the chain on pin A4. The data to send are passed through input signals, and
the current LED index is passed using an output signal. Currently the number
of LEDs is hard-coded, to be used with a single PrSt 5-LED stick. In future,
I will modify the entity to handle an arbitrary (possibly variable) number
of LEDs. The RGB signal is simply a pulsating colour pattern, with five
colours and brightness controlled using a triangle wave. The current
implementation is fairly naive and wastes a number of hardware multiplier
units for something that could be done using a single multiplier and
multiplexing.

# Simple UART

This turns two pins on the extension header (GPIO_024 and GPIO_025) into
receive and transmit pins of a 115200 N-8-1 UART. It's a very basic
implementation - there's no FIFO, no parity handling, baud rate is fixed and
stop bits are not being checked - but it will do the job as the means to
interact with other modules for testing purposes.

