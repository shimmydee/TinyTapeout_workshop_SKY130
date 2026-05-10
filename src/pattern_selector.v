`timescale 1ns / 1ps

// This sub module purely determines the pattern_index based on button inputs, which is required to address the correct pattern from pattern_store
// It takes the SPOT of LEFT and RIGHT buttons, decreasing and increasing pattern_index value respectively
// This sub module enables overflow from NUM_PATTERNS-1 to to 0.
// When reset it resets to pattern_index = 0 (arbitrary, but makes sense)

module pattern_selector #(parameter integer NUM_PATTERNS = 8)( // note that using a parameter of 8 is fine here, it just makes the actualy cody body easier to read.
    input wire clk, reset, btn_left_pulse, btn_right_pulse,
    output reg [2:0] pattern_index
);

    initial pattern_index = 3'd0;

    // Sequential logic because we need our pattern_index to latch and not forget itself (hence the clock and reset inputs too)
    always @(posedge clk) begin
        if (reset) pattern_index <= 2'd0;
        else begin
            case ({btn_left_pulse, btn_right_pulse}) // some clever syntax which reduces previous wire and bitshift logic - suggested by Gemini
                
                2'b10: begin // if only LEFT occurs then perform -1, or overflow if already at zero
                    if (pattern_index == 0) pattern_index <= NUM_PATTERNS - 1;
                    else pattern_index <= pattern_index - 1'b1;
                end

                2'b01: begin // if only RIGHT occurs, then perform +1, or overflow if already at NUM_PATTERNS - 1
                    if (pattern_index == NUM_PATTERNS - 1) pattern_index <= 2'd0;
                    else pattern_index <= pattern_index + 1'b1;
                end
                
                default: pattern_index <= pattern_index; // self-explanatory default case (note that LEFT+RIGHT reset is not handled here, rather it is handled in task1 and task 3 TOP because those are the only ones with cursor logic and hence the only ones that need left+right reset logic)
            endcase
        end
    end

endmodule