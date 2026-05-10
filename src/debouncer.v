`timescale 1ns / 1ps

// DEBOUNCER MODULE that is largeley adapted from double_debounce.v, Lab 05.
// given 1 kHz beat, this takes 3ms to output a debounced signal.

module debouncer (
    input  wire deb_in, sysclk, reset, beat,
    output wire deb_out
);
    reg [2:0] ffdeb;

    initial ffdeb = 3'b000; // power-on init (callers tie .reset to 1'b0)

    always @(posedge sysclk) begin
        if (reset) ffdeb <= 3'b000;
        else if (beat) begin
            ffdeb[0] <= deb_in;
            ffdeb[1] <= ffdeb[0];
            ffdeb[2] <= ffdeb[1];
        end
    end

    assign deb_out = &ffdeb;
endmodule