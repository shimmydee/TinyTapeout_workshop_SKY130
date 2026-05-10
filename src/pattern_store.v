`timescale 1ns / 1ps

// THIS MODULE ACTS AS OUR STORAGE FOR 8 PATTERNS.
// PUT SIMPLY, 8 PATTERNS CONTAINIGN DIFFERENT 2 SEGMENTS WITH BRIGHTNESS LEVELS VARYING FROM 0(OFF) TO 15(MAX HIGH) ARE HARDCODED
// THIS MODULE GETS FED AN ADDRESS pattern_index, AND SPITS OUT THE 112-bit DATA pattern_data

// NOTE THE LITTLE-ENDIAN CONVENTION. THIS POSED NO PROBLEMS SINCE THIS MODULE IS ONLY USED IN TASK 2 AND TASK 3 WHICH ALSO USED LITTLE-ENDIAN CONVENTION

module pattern_store (
    input wire [2:0] pattern_index,
    output reg [111:0] pattern_data
);

    task set_seg;
        inout [111:0] frame;
        input integer digit, segment;
        input [3:0] value;
        begin
            frame[(((digit * 7) + segment) * 4) +: 4] = value;
        end
    endtask

    always @(*) begin
        case (pattern_index)

            // Pattern_0: Full gradient
            3'd0: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 0, 4'd15); 
                set_seg(pattern_data, 3, 1, 4'd15);
                set_seg(pattern_data, 3, 2, 4'd15); 
                set_seg(pattern_data, 3, 3, 4'd15);
                set_seg(pattern_data, 3, 4, 4'd15); 
                set_seg(pattern_data, 3, 5, 4'd15);
                set_seg(pattern_data, 3, 6, 4'd15);
                set_seg(pattern_data, 2, 0, 4'd10); 
                set_seg(pattern_data, 2, 1, 4'd10);
                set_seg(pattern_data, 2, 2, 4'd10); 
                set_seg(pattern_data, 2, 3, 4'd10);
                set_seg(pattern_data, 2, 4, 4'd10); 
                set_seg(pattern_data, 2, 5, 4'd10);
                set_seg(pattern_data, 2, 6, 4'd10);
                set_seg(pattern_data, 1, 0, 4'd5);  
                set_seg(pattern_data, 1, 1, 4'd5);
                set_seg(pattern_data, 1, 2, 4'd5);  
                set_seg(pattern_data, 1, 3, 4'd5);
                set_seg(pattern_data, 1, 4, 4'd5);  
                set_seg(pattern_data, 1, 5, 4'd5);
                set_seg(pattern_data, 1, 6, 4'd5);
                set_seg(pattern_data, 0, 0, 4'd1);  
                set_seg(pattern_data, 0, 1, 4'd1);
                set_seg(pattern_data, 0, 2, 4'd1);  
                set_seg(pattern_data, 0, 3, 4'd1);
                set_seg(pattern_data, 0, 4, 4'd1);  
                set_seg(pattern_data, 0, 5, 4'd1);
                set_seg(pattern_data, 0, 6, 4'd1);
            end

            // Pattern_1: ANU - horizontal bars bright
            3'd1: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 0, 4'd15);
                set_seg(pattern_data, 3, 1, 4'd1);
                set_seg(pattern_data, 3, 2, 4'd1);
                set_seg(pattern_data, 3, 3, 4'd0);
                set_seg(pattern_data, 3, 4, 4'd1);
                set_seg(pattern_data, 3, 5, 4'd1);
                set_seg(pattern_data, 3, 6, 4'd15);
                set_seg(pattern_data, 2, 0, 4'd15);
                set_seg(pattern_data, 2, 1, 4'd1);
                set_seg(pattern_data, 2, 2, 4'd1);
                set_seg(pattern_data, 2, 3, 4'd0);
                set_seg(pattern_data, 2, 4, 4'd1);
                set_seg(pattern_data, 2, 5, 4'd1);
                set_seg(pattern_data, 2, 6, 4'd0);
                set_seg(pattern_data, 1, 0, 4'd0);
                set_seg(pattern_data, 1, 1, 4'd1);
                set_seg(pattern_data, 1, 2, 4'd1);
                set_seg(pattern_data, 1, 3, 4'd15);
                set_seg(pattern_data, 1, 4, 4'd1);
                set_seg(pattern_data, 1, 5, 4'd1);
                set_seg(pattern_data, 1, 6, 4'd0);
                set_seg(pattern_data, 0, 0, 4'd0);
                set_seg(pattern_data, 0, 1, 4'd0);
                set_seg(pattern_data, 0, 2, 4'd0);
                set_seg(pattern_data, 0, 3, 4'd0);
                set_seg(pattern_data, 0, 4, 4'd0);
                set_seg(pattern_data, 0, 5, 4'd0);
                set_seg(pattern_data, 0, 6, 4'd0);
            end

            // Pattern_2: ENGN - right-to-left dimming
            3'd2: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 0, 4'd1);
                set_seg(pattern_data, 3, 1, 4'd0);
                set_seg(pattern_data, 3, 2, 4'd0);
                set_seg(pattern_data, 3, 3, 4'd1);
                set_seg(pattern_data, 3, 4, 4'd1);
                set_seg(pattern_data, 3, 5, 4'd1);
                set_seg(pattern_data, 3, 6, 4'd1);
                set_seg(pattern_data, 2, 0, 4'd5);
                set_seg(pattern_data, 2, 1, 4'd5);
                set_seg(pattern_data, 2, 2, 4'd5);
                set_seg(pattern_data, 2, 3, 4'd0);
                set_seg(pattern_data, 2, 4, 4'd5);
                set_seg(pattern_data, 2, 5, 4'd5);
                set_seg(pattern_data, 2, 6, 4'd0);
                set_seg(pattern_data, 1, 0, 4'd10);
                set_seg(pattern_data, 1, 1, 4'd10);
                set_seg(pattern_data, 1, 2, 4'd10);
                set_seg(pattern_data, 1, 3, 4'd10);
                set_seg(pattern_data, 1, 4, 4'd0);
                set_seg(pattern_data, 1, 5, 4'd10);
                set_seg(pattern_data, 1, 6, 4'd10);
                set_seg(pattern_data, 0, 0, 4'd15);
                set_seg(pattern_data, 0, 1, 4'd15);
                set_seg(pattern_data, 0, 2, 4'd15);
                set_seg(pattern_data, 0, 3, 4'd0);
                set_seg(pattern_data, 0, 4, 4'd15);
                set_seg(pattern_data, 0, 5, 4'd15);
                set_seg(pattern_data, 0, 6, 4'd0);
            end

            // Pattern_3: 4213 - top-to-bottom gradient within each digit
            // TEST - LEFT SOME PINS FLOATIN
            3'd3: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 1, 4'd10);
                set_seg(pattern_data, 3, 5, 4'd10); 
                set_seg(pattern_data, 3, 6, 4'd10);
                set_seg(pattern_data, 3, 2, 4'd5);
                set_seg(pattern_data, 2, 0, 4'd15);
                set_seg(pattern_data, 2, 1, 4'd10); 
                set_seg(pattern_data, 2, 6, 4'd10);
                set_seg(pattern_data, 2, 4, 4'd5);
                set_seg(pattern_data, 2, 3, 4'd1);
                set_seg(pattern_data, 1, 1, 4'd10);
                set_seg(pattern_data, 1, 2, 4'd5);
                set_seg(pattern_data, 0, 0, 4'd15); 
                set_seg(pattern_data, 0, 1, 4'd10);
                set_seg(pattern_data, 0, 6, 4'd5);
                set_seg(pattern_data, 0, 2, 4'd5);
                set_seg(pattern_data, 0, 3, 4'd1);
            end

            // Pattern_4: FPGA - radial gradient
            // TEST: LEFT SOME PINS FLOATING
            3'd4: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 0, 4'd9);
                set_seg(pattern_data, 3, 4, 4'd15);
                set_seg(pattern_data, 3, 5, 4'd15);
                set_seg(pattern_data, 3, 6, 4'd9);
                set_seg(pattern_data, 2, 0, 4'd3);
                set_seg(pattern_data, 2, 1, 4'd1);
                set_seg(pattern_data, 2, 4, 4'd5);
                set_seg(pattern_data, 2, 5, 4'd5);
                set_seg(pattern_data, 2, 6, 4'd3);
                set_seg(pattern_data, 1, 0, 4'd3);
                set_seg(pattern_data, 1, 1, 4'd5);
                set_seg(pattern_data, 1, 2, 4'd5);
                set_seg(pattern_data, 1, 3, 4'd3);
                set_seg(pattern_data, 1, 5, 4'd1);
                set_seg(pattern_data, 1, 6, 4'd3);
                set_seg(pattern_data, 0, 0, 4'd10);
                set_seg(pattern_data, 0, 1, 4'd15);
                set_seg(pattern_data, 0, 2, 4'd15); 
                set_seg(pattern_data, 0, 4, 4'd7);
                set_seg(pattern_data, 0, 5, 4'd7);
                set_seg(pattern_data, 0, 6, 4'd10);
            end

            // Pattern_5: LOUU - lowest brightness
            3'd5: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 0, 4'd0); 
                set_seg(pattern_data, 3, 1, 4'd0);
                set_seg(pattern_data, 3, 2, 4'd0); 
                set_seg(pattern_data, 3, 3, 4'd1);
                set_seg(pattern_data, 3, 4, 4'd1);
                set_seg(pattern_data, 3, 5, 4'd1);
                set_seg(pattern_data, 3, 6, 4'd0);
                set_seg(pattern_data, 2, 0, 4'd1);
                set_seg(pattern_data, 2, 1, 4'd1); 
                set_seg(pattern_data, 2, 2, 4'd1); 
                set_seg(pattern_data, 2, 3, 4'd1); 
                set_seg(pattern_data, 2, 4, 4'd1); 
                set_seg(pattern_data, 2, 5, 4'd1);
                set_seg(pattern_data, 2, 6, 4'd0);
                set_seg(pattern_data, 1, 0, 4'd0);
                set_seg(pattern_data, 1, 1, 4'd1); 
                set_seg(pattern_data, 1, 2, 4'd1);
                set_seg(pattern_data, 1, 3, 4'd1);
                set_seg(pattern_data, 1, 4, 4'd1); 
                set_seg(pattern_data, 1, 5, 4'd1);
                set_seg(pattern_data, 1, 6, 4'd0);
                set_seg(pattern_data, 0, 0, 4'd0);
                set_seg(pattern_data, 0, 1, 4'd1);
                set_seg(pattern_data, 0, 2, 4'd1); 
                set_seg(pattern_data, 0, 3, 4'd1);
                set_seg(pattern_data, 0, 4, 4'd1);
                set_seg(pattern_data, 0, 5, 4'd1);
                set_seg(pattern_data, 0, 6, 4'd0);
            end

            // Pattern 6: tO - middle brightness
            3'd6: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 0, 4'd0);
                set_seg(pattern_data, 3, 1, 4'd0);
                set_seg(pattern_data, 3, 2, 4'd0); 
                set_seg(pattern_data, 3, 3, 4'd0); 
                set_seg(pattern_data, 3, 4, 4'd0); 
                set_seg(pattern_data, 3, 5, 4'd0); 
                set_seg(pattern_data, 3, 6, 4'd0);
                set_seg(pattern_data, 2, 0, 4'd0);
                set_seg(pattern_data, 2, 1, 4'd0); 
                set_seg(pattern_data, 2, 2, 4'd0);
                set_seg(pattern_data, 2, 3, 4'd3);
                set_seg(pattern_data, 2, 4, 4'd3);
                set_seg(pattern_data, 2, 5, 4'd3); 
                set_seg(pattern_data, 2, 6, 4'd3);
                set_seg(pattern_data, 1, 0, 4'd3);
                set_seg(pattern_data, 1, 1, 4'd3);
                set_seg(pattern_data, 1, 2, 4'd3);
                set_seg(pattern_data, 1, 3, 4'd3);
                set_seg(pattern_data, 1, 4, 4'd3);
                set_seg(pattern_data, 1, 5, 4'd3);
                set_seg(pattern_data, 1, 6, 4'd0);
                set_seg(pattern_data, 0, 0, 4'd0); // there is a problem with this digit.. cannot figure out
                set_seg(pattern_data, 0, 1, 4'd0);
                set_seg(pattern_data, 0, 2, 4'd0);
                set_seg(pattern_data, 0, 3, 4'd0);
                set_seg(pattern_data, 0, 4, 4'd0);
                set_seg(pattern_data, 0, 5, 4'd0);
                set_seg(pattern_data, 0, 6, 4'd0);
            end

            // Pattern_7: HIGH - max brightness
            3'd7: begin
                pattern_data = 112'd0;
                set_seg(pattern_data, 3, 0, 4'd0);
                set_seg(pattern_data, 3, 1, 4'd15);
                set_seg(pattern_data, 3, 2, 4'd15);
                set_seg(pattern_data, 3, 3, 4'd0);
                set_seg(pattern_data, 3, 4, 4'd15);
                set_seg(pattern_data, 3, 5, 4'd15);
                set_seg(pattern_data, 3, 6, 4'd15); 
                set_seg(pattern_data, 2, 0, 4'd0); 
                set_seg(pattern_data, 2, 1, 4'd15);
                set_seg(pattern_data, 2, 2, 4'd15);
                set_seg(pattern_data, 2, 3, 4'd0);
                set_seg(pattern_data, 2, 4, 4'd0);
                set_seg(pattern_data, 2, 5, 4'd0); 
                set_seg(pattern_data, 2, 6, 4'd0); 
                set_seg(pattern_data, 1, 0, 4'd15);
                set_seg(pattern_data, 1, 1, 4'd15);
                set_seg(pattern_data, 1, 2, 4'd15);
                set_seg(pattern_data, 1, 3, 4'd15);
                set_seg(pattern_data, 1, 4, 4'd0); 
                set_seg(pattern_data, 1, 5, 4'd15);
                set_seg(pattern_data, 1, 6, 4'd15);
                set_seg(pattern_data, 0, 0, 4'd0);
                set_seg(pattern_data, 0, 1, 4'd15);
                set_seg(pattern_data, 0, 2, 4'd15);
                set_seg(pattern_data, 0, 3, 4'd0);
                set_seg(pattern_data, 0, 4, 4'd15);
                set_seg(pattern_data, 0, 5, 4'd15);
                set_seg(pattern_data, 0, 6, 4'd15);
            end

            default: pattern_data = 112'd0;
        endcase
    end

endmodule