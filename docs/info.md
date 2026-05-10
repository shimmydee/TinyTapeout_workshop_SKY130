<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This tile is a port of a Basys 3 FPGA project (https://github.com/shimmydee/FPGA_project)
that drives a four-digit common-anode seven-segment display with three modes
selected by `sw[2:1]`:

- **Task 1** – Cursor navigation across all 28 segments. Buttons U/D/L/R move
  the cursor through a hand-built adjacency map. Level 1 just lights the
  cursor; Level 2 lets the centre button toggle each segment on/off, with the
  cursor blinking at 4 Hz over selected segments and 8 Hz over unselected ones.
  An autoloop mode (sw3) can step the cursor automatically.
- **Task 2** – Eight hardcoded brightness patterns selectable with L/R. Level 1
  uses the centre button to ramp a global brightness 0–15 at 8 Hz. Level 2
  pages through the eight stored patterns.
- **Task 3** – Per-segment 4-bit brightness memory across 8 pages selected by
  `sw[6:4]`. Tap centre to toggle a segment between off and full brightness;
  hold centre for ≥500 ms to ramp brightness up at 8 Hz. The cursor blinks
  on top of the stored brightness map.

A 16-level PWM driver multiplexes the four digits at ~1 kHz and modulates each
segment independently. The whole pipeline runs from a single 25 MHz clock; all
heartbeat divisors that targeted the Basys 3's 100 MHz clock have been
rescaled by ¼.

## How to test

The tile expects a 25 MHz clock on `clk` and an active-low reset on `rst_n`.
Connect five momentary buttons to `ui_in[4:0]` (C/U/D/L/R) and seven slide
switches to `ui_in[7:5]` and `uio[3:0]` (sw0..sw6). Wire a common-anode
4-digit seven-segment display module to:

- `uo_out[6:0]` → segments CA..CG (active-low)
- `uo_out[7]`   → DP (active-low)
- `uio[4]`      → AN0 (digit 0 anode, active-low)
- `uio[5]`      → AN1
- `uio[6]`      → AN2
- `uio[7]`      → AN3

To exercise each mode, set `sw[2:1]` accordingly:

- `01` → Task 1 (cursor / toggle)
- `10` → Task 2 (patterns / global brightness)
- `11` → Task 3 (per-segment brightness memory)

Within each task `sw0` selects between Level 1 and Level 2 behaviour.

## External hardware

- Common-anode 4-digit seven-segment display module (e.g. a generic 12-pin
  module with current-limiting resistors). Drive segment cathodes from
  `uo_out[6:0]` and digit anodes through PNP transistors from `uio[7:4]` (or
  use a display module that already includes anode drivers).
- Five push-buttons for the C/U/D/L/R inputs.
- Up to seven slide switches for sw0..sw6.

## Notes for the implementer

- The original FPGA design used 49 IOs (16 switches, 5 buttons, 7+1+4 display,
  16 LEDs). To fit TinyTapeout's 24 user IOs we dropped `sw[7]`, `sw[14]` (the
  Task 3 load signal), unused `sw[8..13]`, and all 16 status LEDs. The
  Basys 3 global reset (`sw[15]`) is now routed through the dedicated `rst_n`
  pin.
- The design contains an 8 × 28 × 4-bit segment-brightness RAM (~900 flip
  flops) plus a combinational 8-pattern ROM. This may be tight on a 1×1
  SKY130 tile; if hardening fails on area, increase `tiles:` in `info.yaml`
  to `2x2` or reduce scope to a single task.

I created this as part of the TT Workshop at FOSSi Down Underflow 2026.
