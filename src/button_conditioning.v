`timescale 1ns / 1ps

// This is a button conditioning module that implements: syncrhonisers, debouncer (w/ instantiated 1kHz beat),
// and SPOT modules for all 5 buttons. This is kind of unecessary to individual instantiations, but does make
// the 'Sources' view nicer to read.

module button_conditioning (
    input wire sysclk, reset, // SPOT reset: tie to 1'b0 if not needed
    input wire btnC, btnL, btnR, btnU, btnD,
    output wire btnC_level, btnL_level, btnR_level, btnU_level, btnD_level,
    output wire btnC_pulse, btnL_pulse, btnR_pulse, btnU_pulse, btnD_pulse,
    output wire beat_out    // shared 1kHz beat, usable by parent for switch debouncers
);

    // Synchronisers (used only two flip flops)
    reg [1:0] ff_C, ff_U, ff_D, ff_L, ff_R;
    initial begin
        ff_C = 2'b00; ff_U = 2'b00; ff_D = 2'b00; ff_L = 2'b00; ff_R = 2'b00;
    end
    always @(posedge sysclk) begin
        ff_C <= {ff_C[0], btnC};
        ff_U <= {ff_U[0], btnU};
        ff_D <= {ff_D[0], btnD};
        ff_L <= {ff_L[0], btnL};
        ff_R <= {ff_R[0], btnR};
    end
    wire sC = ff_C[1];
    wire sU = ff_U[1];
    wire sD = ff_D[1];
    wire sL = ff_L[1];
    wire sR = ff_R[1];

    // 1 kHz beat used for all debouncers
    wire beat;
    heartbeat #(.THRESHOLD(12_500)) u_beat (
        .sysclk(sysclk), .enable(1'b1), .reset(1'b0),
        .beat(beat), .dividedClk()
    );
    assign beat_out = beat;

    // DEBOUNCER instantiations
    wire debC, debU, debD, debL, debR;
    debouncer u_debC (.deb_in(sC), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debC));
    debouncer u_debU (.deb_in(sU), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debU));
    debouncer u_debD (.deb_in(sD), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debD));
    debouncer u_debL (.deb_in(sL), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debL));
    debouncer u_debR (.deb_in(sR), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debR));

    // Button level outputs (which are equivalent to their continuous debounced values)
    assign btnC_level = debC;
    assign btnU_level = debU;
    assign btnD_level = debD;
    assign btnL_level = debL;
    assign btnR_level = debR;

    // SPOT instantiations
    spot u_spotC (.spot_in(debC), .sysclk(sysclk), .reset(reset), .spot_out(btnC_pulse));
    spot u_spotU (.spot_in(debU), .sysclk(sysclk), .reset(reset), .spot_out(btnU_pulse));
    spot u_spotD (.spot_in(debD), .sysclk(sysclk), .reset(reset), .spot_out(btnD_pulse));
    spot u_spotL (.spot_in(debL), .sysclk(sysclk), .reset(reset), .spot_out(btnL_pulse));
    spot u_spotR (.spot_in(debR), .sysclk(sysclk), .reset(reset), .spot_out(btnR_pulse));

endmodule