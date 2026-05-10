`timescale 1ns / 1ps

// This module takes the stored brightness data from seg_brightness_mem and builds 
// the final 112-bit brightness_map for the PWM driver, adding a blinking cursor on top

// Beauty of this module is that we reuse the blink module from task 1, but because that module takes in and outputs
// only 28-bit masks then we have to do some manipulation of the seg_brightness_flat

module task3_frame_source (
    input wire [111:0] seg_brightness_flat,
    input wire [4:0] cursorID,
    input wire btnC_level, // HIGH while centre button held
    input wire dividedClk4Hz, dividedClk8Hz, // blink rates
    output reg [111:0] brightness_map
);

    // Creates the 28-bit wide mask down from the 112-bit wide mask. This syntax could be reduced using a 'generate'.
    wire [27:0] on_off_mask;
    assign on_off_mask[27] = |seg_brightness_flat[3:0]; //i.e., for the big-end segment of our mask (first digit for blink = A of leftmost), take the 4-bit brightness of the little-end of our seg_brightness_flat (corresponding to segment A of leftmost) and assert if there is a non-zero brightness there.
    assign on_off_mask[26] = |seg_brightness_flat[7:4];
    assign on_off_mask[25] = |seg_brightness_flat[11:8];
    assign on_off_mask[24] = |seg_brightness_flat[15:12];
    assign on_off_mask[23] = |seg_brightness_flat[19:16];
    assign on_off_mask[22] = |seg_brightness_flat[23:20];
    assign on_off_mask[21] = |seg_brightness_flat[27:24];
    assign on_off_mask[20] = |seg_brightness_flat[31:28];
    assign on_off_mask[19] = |seg_brightness_flat[35:32];
    assign on_off_mask[18] = |seg_brightness_flat[39:36];
    assign on_off_mask[17] = |seg_brightness_flat[43:40];
    assign on_off_mask[16] = |seg_brightness_flat[47:44];
    assign on_off_mask[15] = |seg_brightness_flat[51:48];
    assign on_off_mask[14] = |seg_brightness_flat[55:52];
    assign on_off_mask[13] = |seg_brightness_flat[59:56];
    assign on_off_mask[12] = |seg_brightness_flat[63:60];
    assign on_off_mask[11] = |seg_brightness_flat[67:64];
    assign on_off_mask[10] = |seg_brightness_flat[71:68];
    assign on_off_mask[9]  = |seg_brightness_flat[75:72];
    assign on_off_mask[8]  = |seg_brightness_flat[79:76];
    assign on_off_mask[7]  = |seg_brightness_flat[83:80];
    assign on_off_mask[6]  = |seg_brightness_flat[87:84];
    assign on_off_mask[5]  = |seg_brightness_flat[91:88];
    assign on_off_mask[4]  = |seg_brightness_flat[95:92];
    assign on_off_mask[3]  = |seg_brightness_flat[99:96];
    assign on_off_mask[2]  = |seg_brightness_flat[103:100];
    assign on_off_mask[1]  = |seg_brightness_flat[107:104];
    assign on_off_mask[0]  = |seg_brightness_flat[111:108];

    // blink module insantiation that feeds in our mask and outputs a blinking cursor where cursorID specifies!
    wire [27:0] blink_display;
    blink u_blink (
        .savedPattern (on_off_mask),
        .cursorID (cursorID),
        .dividedClk4Hz (dividedClk4Hz),
        .dividedClk8Hz (dividedClk8Hz),
        .displayPattern(blink_display)
    );

    // WIRES USED TO DETERMINE WHETHER THE CURSOR IS ON OR OFF, AND BASED OFF THAT ASSIGN A BRIGHTNESS VALUE OF EITHER 0 (OFF) OR 15 (ON). Arbitrary design choice, but we wanted our cursor to be maximum brightness.
    wire [27:0] cursorMask = 28'h8000000 >> cursorID;
    wire cursor_on_phase = |(blink_display & cursorMask); // note the bitwise-or operator
    wire [3:0] cursor_bval = cursor_on_phase ? 4'd15 : 4'd0;

    // Using all of this, build the final brightness map which will be fed into our PWM driver
    integer i;
    always @(*) begin

        // Pass 1: fill everything from stored brightness
        for (i = 0; i < 28; i = i + 1)
            brightness_map[((3-i/7)*7 + i%7)*4 +: 4] = seg_brightness_flat[i*4 +: 4];

        // Pass 2: override just the cursor position
        if (!btnC_level) begin
            case (cursorID)
                5'd0:  brightness_map[84 +: 4] = cursor_bval;
                5'd1:  brightness_map[88 +: 4] = cursor_bval;
                5'd2:  brightness_map[92 +: 4] = cursor_bval;
                5'd3:  brightness_map[96 +: 4] = cursor_bval;
                5'd4:  brightness_map[100+: 4] = cursor_bval;
                5'd5:  brightness_map[104+: 4] = cursor_bval;
                5'd6:  brightness_map[108+: 4] = cursor_bval;
                5'd7:  brightness_map[56 +: 4] = cursor_bval;
                5'd8:  brightness_map[60 +: 4] = cursor_bval;
                5'd9:  brightness_map[64 +: 4] = cursor_bval;
                5'd10: brightness_map[68 +: 4] = cursor_bval;
                5'd11: brightness_map[72 +: 4] = cursor_bval;
                5'd12: brightness_map[76 +: 4] = cursor_bval;
                5'd13: brightness_map[80 +: 4] = cursor_bval;
                5'd14: brightness_map[28 +: 4] = cursor_bval;
                5'd15: brightness_map[32 +: 4] = cursor_bval;
                5'd16: brightness_map[36 +: 4] = cursor_bval;
                5'd17: brightness_map[40 +: 4] = cursor_bval;
                5'd18: brightness_map[44 +: 4] = cursor_bval;
                5'd19: brightness_map[48 +: 4] = cursor_bval;
                5'd20: brightness_map[52 +: 4] = cursor_bval;
                5'd21: brightness_map[0  +: 4] = cursor_bval;
                5'd22: brightness_map[4  +: 4] = cursor_bval;
                5'd23: brightness_map[8  +: 4] = cursor_bval;
                5'd24: brightness_map[12 +: 4] = cursor_bval;
                5'd25: brightness_map[16 +: 4] = cursor_bval;
                5'd26: brightness_map[20 +: 4] = cursor_bval;
                5'd27: brightness_map[24 +: 4] = cursor_bval;
                default: ; // invalid cursorID - no override. this should never happen!
            endcase
        end
        // else (btnC_level=1, HELD): no Pass 2 override.
        // Cursor shows stored brightness from Pass 1: solid, non-blinking.
    end

endmodule