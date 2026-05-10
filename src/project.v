/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * TinyTapeout wrapper for the Task 1 portion of the seven-segment display
 * project ported from https://github.com/shimmydee/FPGA_project. Earlier
 * iterations included Tasks 2 and 3 but they were dropped because the
 * 8-page brightness RAM and 8-pattern ROM together pushed the design to
 * ~7x the area of a 1x1 SKY130 tile.
 *
 * What's kept:
 *   - Cursor navigation across all 28 segments (4 digits x 7 segments)
 *   - Centre-button toggle in level 2
 *   - 4 Hz / 8 Hz blinking cursor
 *   - Autoloop mode that auto-advances the cursor
 *   - 16-level PWM digit-mux driver (left as-is though only on/off is used)
 *
 * Pin mapping:
 *
 *   clk            : 25 MHz system clock
 *   rst_n          : active-low reset
 *
 *   ui_in[0]       : btnC (centre - toggle in level 2)
 *   ui_in[1]       : btnU
 *   ui_in[2]       : btnD
 *   ui_in[3]       : btnL
 *   ui_in[4]       : btnR
 *   ui_in[5]       : sw0 - level select (0 = level 1 cursor only, 1 = level 2 toggle)
 *   ui_in[6]       : sw3 - autoloop enable (only meaningful in level 2)
 *   ui_in[7]       : unused
 *
 *   uio_in[3:0]    : unused (reserved)
 *   uio_out[4]     : an[0]   digit 0 anode (active-low)
 *   uio_out[5]     : an[1]
 *   uio_out[6]     : an[2]
 *   uio_out[7]     : an[3]
 *
 *   uo_out[6:0]    : seg[6:0] cathodes (active-low)
 *   uo_out[7]      : dp (always 1 - inactive)
 */

`default_nettype none

module tt_um_shimmydee_sevenseg (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // uio[3:0] = inputs (reserved), uio[7:4] = outputs (anodes)
    assign uio_oe = 8'b1111_0000;

    // Synthesise the original 16-bit switch bus from available pins. Only
    // sw[0], sw[3], and sw[15] are read by Task_1_TOP - the rest are tied
    // off so they synthesise away.
    wire [15:0] sw;
    assign sw[0]    = ui_in[5];
    assign sw[1]    = 1'b0;
    assign sw[2]    = 1'b0;
    assign sw[3]    = ui_in[6];
    assign sw[14:4] = 11'b0;
    assign sw[15]   = ~rst_n;

    wire [6:0] seg;
    wire [3:0] an;
    wire       dp;

    Task_1_TOP u_task1 (
        .sysclk (clk),
        .btnC   (ui_in[0]),
        .btnU   (ui_in[1]),
        .btnD   (ui_in[2]),
        .btnL   (ui_in[3]),
        .btnR   (ui_in[4]),
        .sw     (sw),
        .seg    (seg),
        .an     (an),
        .dp     (dp)
    );

    assign uo_out[6:0]  = seg;
    assign uo_out[7]    = dp;
    assign uio_out[3:0] = 4'b0;
    assign uio_out[4]   = an[0];
    assign uio_out[5]   = an[1];
    assign uio_out[6]   = an[2];
    assign uio_out[7]   = an[3];

    // Suppress unused-signal lint warnings.
    wire _unused = &{ena, ui_in[7], uio_in, 1'b0};

endmodule
