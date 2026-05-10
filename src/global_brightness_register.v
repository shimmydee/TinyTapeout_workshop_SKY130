`timescale 1ns / 1ps

// This module implements the logic and storage of the GLOBAL brightness level, and is only used to action Task 2 Level 1.
// It takes in the current value of the centre button (i.e., its level) as well a heartbeat that determines how quick the brightness ramps when centre is held
// Importantly, the global_brightness variables describes the 16 brightness levels, and is multiplexed in with pattern_data in task2_frame_source s.t. it is only used when in level 1.

module global_brightness_register(
    input wire clk, reset, btn_center_level, step_tick,         
     output reg [3:0] global_brightness
);

    // SPOT LOGIC FOR NEW BUTTON PRESS
    reg btn_center_prev; // this is a one-clock cycle delayed reg of what the button was doing - this allows us to compare with the current button level to determine if it is a 'new hold'
    wire new_hold;

    initial begin btn_center_prev = 1'b0; global_brightness = 4'd0; end

    // sequentially update the previous value of the centre button. This is the flip flop of the SPOT below.
    always @(posedge clk) begin
        if (reset) btn_center_prev <= 1'b0;
        else btn_center_prev <= btn_center_level; 
    end
    
    assign new_hold = btn_center_level && ~btn_center_prev; // Does a SPOT if the center button is on a rising edge (therefore, a new hold = a pulse delivered), but without instantiating another SPOT module which would be a waste of hardware.

    // LOGIC FOR THE GLOBAL BRIGHTNESS INCREASE
    always @(posedge clk) begin
        if (reset) global_brightness <= 4'd0;
        else begin
            if (new_hold) global_brightness <= 4'd1; // use the SPOT new_hold to set the start of our ramp to a brightness of 1.
            else if (btn_center_level && step_tick) begin // Then for each continuing btn_center_level & step_tick, increase global_brightness by 1 
                if (global_brightness < 4'd15) global_brightness <= global_brightness + 1'b1; // until it hits 15, at which point it maxes out and DOES NOT overflow (design choice)
                else global_brightness <= global_brightness; 
            end
            // On release, hold global_brightness at current state
            else global_brightness <= global_brightness;
        end
    end

endmodule