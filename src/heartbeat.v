`default_nettype none
`timescale 1ns / 1ps

// Parameterised clock divider used throughout the FPGA design (was missing
// from the original FPGA repo; recreated here from its instantiation pattern).
//
// Generates a single-cycle pulse `beat` every THRESHOLD sysclk cycles, and a
// square-wave `dividedClk` that toggles on each beat (so its period is
// 2*THRESHOLD sysclk cycles).

module heartbeat #(parameter integer THRESHOLD = 50_000) (
    input  wire sysclk,
    input  wire enable,
    input  wire reset,
    output wire beat,
    output reg  dividedClk
);

    localparam integer W = 32;
    reg [W-1:0] counter;
    wire        terminal = (counter == THRESHOLD - 1);

    // Power-on initialisation so that simulation (and ASIC POR) start in a
    // defined state when `reset` is hard-tied to 0 by some callers.
    initial begin
        counter    = {W{1'b0}};
        dividedClk = 1'b0;
    end

    always @(posedge sysclk) begin
        if (reset) begin
            counter    <= {W{1'b0}};
            dividedClk <= 1'b0;
        end else if (enable) begin
            if (terminal) begin
                counter    <= {W{1'b0}};
                dividedClk <= ~dividedClk;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

    assign beat = enable & terminal;

endmodule
