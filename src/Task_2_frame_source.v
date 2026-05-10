`timescale 1ns / 1ps

// This sub module alternates brightness_map outputs depending on mode_level selection
// If mode_level is true, then brightness_map = pattern_data from the selected from pattern_store by pattern_selector
// Else if model_level is false, then brightness_map = globalbrightness value populated within 112-bit brightness map

// NOTE mode_level is renamed to mode_level2 in the Verilog because it makes it easier to read in the top level

module task2_frame_source(
    input wire mode_level2, 
    input wire [3:0] global_brightness,   
    input wire [111:0] pattern_data,   
    output reg [111:0] brightness_map
);

    integer i;

    always @(*) begin
        if (mode_level2) begin
        
            // Level 2 Selected - Use selected pattern_store data directly
            brightness_map = pattern_data;
            
        end else begin
        
            // Level 1 Selected - Apply the same selected 0-15 brightness level to all 28 unique segments
            // This loops through all 28 unique segments, setting the bits[X:X-3] = global_brightness
            // For example, when i = 2 then brightness_map[2*4+:4] = brightness_map[8+4+:4] = bits[11:8]
            
            brightness_map = 112'd0;
            for (i = 0; i < 28; i = i + 1) begin
                brightness_map[i*4 +: 4] = global_brightness; // maps 4-bits to 112-bits
            end
        end
    end

endmodule
