`timescale 1ns / 1ps

// SPOT module which is adapted from reset_sync.v / spot.v, Lab 05.
// IMPORTANT: levelSysReset is fed in as the reset signal. Deliberately chose to put no reset condition on the flip flops,
// and rather to combinationally assign it on spot_out so that no spurios edge is detected
// This isuseful for the LEFT+RIGHT reset because it means no pulse is generated because 
// spot_in is already LOW when reset releases

module spot (
    input  wire spot_in, sysclk, reset,
    output wire spot_out
);
    reg ffspot;

    initial ffspot = 1'b0; // power-on init - register has no reset by design

    always @(posedge sysclk)
        ffspot <= spot_in; // deliberatly no reset so that it continuously tracks physical state

    assign spot_out = spot_in & ~ffspot & ~reset; 
endmodule