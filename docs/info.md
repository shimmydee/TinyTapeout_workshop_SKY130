<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This tile is a port of Task 1 from a Basys 3 FPGA project
(https://github.com/shimmydee/FPGA_project) that drives a four-digit
common-anode seven-segment display. The cursor (`cursorID` 0..27) navigates
all 28 individual segments via a hand-built adjacency map that knows about
horizontal wraparound between digits and vertical bounds within each digit.

Two levels of operation are selected by `sw0`:

- **Level 1** — The cursor simply lights one segment at a time. Buttons
  U/D/L/R move the cursor; the centre button does nothing.
- **Level 2** — The centre button toggles segments on/off. The cursor blinks
  at 4 Hz when hovering over a "selected" (lit) segment and 8 Hz over an
  unselected one, so you can always see where you are while drawing.

When `sw3` is asserted in Level 2, the cursor auto-advances at 2 Hz instead
of waiting for button presses.

A 16-level PWM driver multiplexes the four digit anodes at ~1 kHz; the
brightness map for Task 1 is forced to either full-on or full-off per
segment (no per-segment brightness control in this tile - that was Task 3
in the original FPGA project, dropped here for area reasons).

The whole pipeline runs from a single 25 MHz clock; all heartbeat divisors
that targeted the Basys 3's 100 MHz clock have been rescaled by ¼.

## How to test

Connect:

- 25 MHz clock to `clk`
- Active-low reset to `rst_n`
- Five momentary buttons to `ui_in[4:0]` for C/U/D/L/R
- Two slide switches: `sw0` to `ui_in[5]` (level select), `sw3` to `ui_in[6]`
  (autoloop)
- A common-anode 4-digit seven-segment display:
  - `uo_out[6:0]` → CA..CG (active-low)
  - `uo_out[7]`   → DP (active-low; always inactive)
  - `uio[7:4]`    → AN0..AN3 (active-low)

Sequence:

1. Pulse `rst_n` low for several milliseconds, then release. The cursor
   resets to segment F of digit 1.
2. With `sw0=0` (Level 1): one segment glows steadily. Press U/D/L/R to
   move the cursor.
3. With `sw0=1` (Level 2): the cursor blinks. Press centre to toggle the
   current segment on/off. Press LEFT+RIGHT together to clear the canvas
   (a level-sensitive reset).
4. With `sw0=1` and `sw3=1`: cursor auto-advances at 2 Hz.

## External hardware

- Common-anode 4-digit seven-segment display module with current-limiting
  resistors and (optionally) anode-driver transistors.
- Five push-buttons for C/U/D/L/R.
- Two slide switches for sw0 and sw3.

## History

The original FPGA project covered three tasks: cursor + toggle (Task 1),
brightness pattern store (Task 2), and per-segment brightness memory across
8 pages (Task 3). The full design was ~7× the area of a 1×1 SKY130 tile,
so only Task 1 fits at this tile size.

I created this as part of the TT Workshop at FOSSi Down Underflow 2026.
