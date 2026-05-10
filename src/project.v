/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * TinyTapeout wrapper for the seven-segment display project ported from
 * the Basys 3 FPGA design at https://github.com/shimmydee/FPGA_project.
 *
 * Pin mapping (all 24 user IO bits used):
 *
 *   clk            : 25 MHz system clock
 *   rst_n          : active-low reset (replaces Basys3 sw[15])
 *
 *   ui_in[0]       : btnC
 *   ui_in[1]       : btnU
 *   ui_in[2]       : btnD
 *   ui_in[3]       : btnL
 *   ui_in[4]       : btnR
 *   ui_in[5]       : sw[0]  - level select (1 = level 2)
 *   ui_in[6]       : sw[1]  - task active select (low bit)
 *   ui_in[7]       : sw[2]  - task active select (high bit)
 *
 *   uio_in[0]      : sw[3]  - autoloop enable (Task 1 level 2)
 *   uio_in[1]      : sw[4]  - Task 3 page bit 0
 *   uio_in[2]      : sw[5]  - Task 3 page bit 1
 *   uio_in[3]      : sw[6]  - Task 3 page bit 2
 *   uio_out[4]     : an[0]  - 7seg digit 0 anode (active-low)
 *   uio_out[5]     : an[1]  - 7seg digit 1 anode (active-low)
 *   uio_out[6]     : an[2]  - 7seg digit 2 anode (active-low)
 *   uio_out[7]     : an[3]  - 7seg digit 3 anode (active-low)
 *
 *   uo_out[6:0]    : seg[6:0] - 7seg cathodes (active-low, Basys3 convention)
 *   uo_out[7]      : dp       - decimal point (active-low)
 *
 * Dropped from the FPGA design (pin budget): sw[7], sw[14] (load), sw[8..13]
 * (unused on Basys3 anyway), and all 16 LEDs.
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

    // uio[3:0] = inputs (switches), uio[7:4] = outputs (anodes)
    assign uio_oe = 8'b1111_0000;

    // Reconstruct the original 16-bit switch bus from the available pins.
    // Unused bits are tied to 0 except sw[15] which is the global reset
    // routed through the dedicated rst_n.
    wire [15:0] sw;
    assign sw[0]    = ui_in[5];
    assign sw[1]    = ui_in[6];
    assign sw[2]    = ui_in[7];
    assign sw[3]    = uio_in[0];
    assign sw[4]    = uio_in[1];
    assign sw[5]    = uio_in[2];
    assign sw[6]    = uio_in[3];
    assign sw[7]    = 1'b0;
    assign sw[13:8] = 6'b0;
    assign sw[14]   = 1'b0;
    assign sw[15]   = ~rst_n;

    wire [6:0]  seg;
    wire [3:0]  an;
    wire        dp;
    wire [15:0] led;

    master_top u_master (
        .sysclk (clk),
        .btnC   (ui_in[0]),
        .btnU   (ui_in[1]),
        .btnD   (ui_in[2]),
        .btnL   (ui_in[3]),
        .btnR   (ui_in[4]),
        .sw     (sw),
        .seg    (seg),
        .an     (an),
        .dp     (dp),
        .led    (led)
    );

    assign uo_out[6:0]  = seg;
    assign uo_out[7]    = dp;
    assign uio_out[3:0] = 4'b0;
    assign uio_out[4]   = an[0];
    assign uio_out[5]   = an[1];
    assign uio_out[6]   = an[2];
    assign uio_out[7]   = an[3];

    // Suppress unused-signal lint warnings (ena is always 1; led[15:0] is
    // intentionally not exposed - no pin budget for status LEDs).
    wire _unused = &{ena, led, 1'b0};

endmodule
