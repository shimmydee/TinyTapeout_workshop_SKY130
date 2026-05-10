`timescale 1ns / 1ps

// THIS IS A PWM DRIVER FOR THE 7SD WHICH TAKES IN THE BRIGHTNESS_MAP THAT STORES THE (16) BRIGHTNESS VALUES OF EACH SEGMENT AND DOES TIME-MULTIPLEXING + PWM 
// TO DRIVE THE SEGMENT (SEG) AND ANODE (AN).
// IMPORTANTLY, IT USES A PARAMETER DIGIT_RATE_HZ WHICH DEFINES HOW MANY TIMES A SECOND THE FULL SET OF FOUR DIGITS COMPLETES ONE SCAN CYCLE. THIS MEANS
// EACH DIGIT TURNS ON DIGIT_RATE_HZ * 4 TIMES A SECOND, AND WHICH WILL THEN ALLOW US TO COMPARE IT WITH A FREERUNNING PWM COUNT WHICH WILL THEN DEFINE WHICH SEGMENT IS ON IN THAT DIGIT
// NOTE THE BEAUTY OF THIS IS THAT WE DON'T USE DUTY RATE AS A PARAMETER ADN THUS CAN MORE EASILY DEFINE 16 BRIGHTNESS LEVELS - PURELY THROUGH CHANGING DIGIT_RATE_HZ DO WE CHANGE THE MAX BRIGHTNESS, AND PURELY THROUGH PWM_COUNT DO WE DETERMINE THE NUMBER OF BRIGHTNESS LEVELS

module SevenSegement_PWM #(parameter integer CLK_FREQ_HZ = 25_000_000, parameter integer DIGIT_RATE_HZ = 256)(
    input wire clk, reset,
    input wire [111:0] brightness_map,
    output reg [6:0] seg,
    output reg [3:0] an
);

    localparam integer SCAN_DIV = CLK_FREQ_HZ / (DIGIT_RATE_HZ * 4); // HOW MANY CLOCK CYCLES PER DIGIT = 24,414 (arbitrary)
    localparam integer SCAN_DIV_W = 32; // ARBITRARY LARGE SIZE - DECOUPLES THE NEED TO CHANGE IT IF WE CHOOSE A DIFFERENT COUNT

    reg [SCAN_DIV_W-1:0] scan_count; // THIS REG ACTS AS THE THRESHOLD FOR OUR 4 COUNT-UP
    reg [1:0] digit_idx; // 4 COUNT-UP THAT GETS PASSES TO SSDANODE (IS EQUIVALENT TO SAYING WHICH DIGIT IS ON)

    initial begin scan_count = {SCAN_DIV_W{1'b0}}; digit_idx = 2'd0; end

    // SEQUENTIAL BLOCK THAT DOES OUR LOGIC TO DRIVE SSDANODE/SELECTION OF WHICH DIGIT IS ON
    always @(posedge clk) begin
        if (reset) begin
            scan_count <= 0;
            digit_idx  <= 2'd0;
        end else begin
            if (scan_count == SCAN_DIV - 1) begin // NOTE THAT IT COUNTS UP TO SCAN_DIV - I.E., THIS MAKES SURE EACH DIGIT IS ON FOR SCAN_DIV
                scan_count <= 0;
                digit_idx  <= digit_idx + 1'b1;
            end else begin
                scan_count <= scan_count + 1'b1;
            end
        end
    end

    reg [3:0] pwm_count; // FREE RUNNING COUNTER DEFINES HOW MANY LEVELS OF BRIGHTNESS WE GET. INCREASE THIS TO [4:0] TO GET 32 LEVELS OF BRIGHTNESS. NOTE WE CHOSE FREERUNNIGN BECAUSE IT WAS EASIER THAN COUNTING WITHIN EACH SCAN_DIV CLOCK CYCLES - HOWEVER PROBABLY COULD BE OPTIMISED.
    initial pwm_count = 4'd0;
    always @(posedge clk) begin
        if (reset) pwm_count <= 4'd0;
        else pwm_count <= pwm_count + 1'b1;
    end

    // FUNCTION THAT RETURNS THE BRIGHTNESS FOR A PARTICULAR DIGIT'S SEGMENT - THIS IS PURELY COMBINATIONAL WCHIH IS AWESOME
    function [3:0] get_level;
        input [1:0] digit;
        input [2:0] segment;
        begin
            // THE INDEX IS CALCULATED BY: FIND THE DIGIT SEGMENT START (DIGIT*7) AND ADDS THE SEGMENT WE ARE ON (HARDCODE) USING AN OFFSET, THEN TIMES BY 4 TO OBTAIN THE BASE FROM WHICH TO COUNT THE BRIGHTNESS MAP
            get_level = brightness_map[(((digit * 7) + segment) * 4) +: 4]; //SINCE WE ARE ONLY CONCERNED WITH SELECTING 4 BITS AT A TIME, WE CAN USE THIS 'INDEXED PART-SELECT' OPERATOR
        end
    endfunction

    // BRIGHTNESS COMPARISON LOGIC. THIS IS WHERE THE PWM EXECUTES!
    reg [3:0] level_a, level_b, level_c, level_d, level_e, level_f, level_g;
    always @(*) begin // CALCULATES THE BRIGHTNESS OF ALL THE SEGMENTS FOR THE CURRENT ACTIVE DIGIT
        level_a = get_level(digit_idx, 3'd0);
        level_b = get_level(digit_idx, 3'd1);
        level_c = get_level(digit_idx, 3'd2);
        level_d = get_level(digit_idx, 3'd3);
        level_e = get_level(digit_idx, 3'd4);
        level_f = get_level(digit_idx, 3'd5);
        level_g = get_level(digit_idx, 3'd6);
    end

    // THIS IS THE CORE MECHANISM FOR PWM, IF THE CALCUALTED BRIGHTNESS VALUE IS GREATER THAN THE PWM_COUNT DURING ITS COUNT, THEN IT WILL BE ON.
    // E.G., IF level_a = 12, THEN seg_a_on is HIGH for pwm_count = 0-11 (12 total cycles). THIS GIVES A DUTY RATE OF 12/16 = 75%
    wire seg_a_on = (level_a > pwm_count);
    wire seg_b_on = (level_b > pwm_count);
    wire seg_c_on = (level_c > pwm_count);
    wire seg_d_on = (level_d > pwm_count);
    wire seg_e_on = (level_e > pwm_count);
    wire seg_f_on = (level_f > pwm_count);
    wire seg_g_on = (level_g > pwm_count);

    // OUTPUT LOGIC THAT DRIVES THE 7SD'S CATHODE AND ANODE
    always @(*) begin
        case (digit_idx)
            2'd0: an = 4'b1110; // AN0
            2'd1: an = 4'b1101; // AN1
            2'd2: an = 4'b1011; // AN2
            2'd3: an = 4'b0111; // AN3
            default: an = 4'b1111;
        endcase

        // RECALL NEGATIVE LOGIC
        seg[6] = ~seg_a_on;
        seg[5] = ~seg_b_on;
        seg[4] = ~seg_c_on;
        seg[3] = ~seg_d_on;
        seg[2] = ~seg_e_on;
        seg[1] = ~seg_f_on;
        seg[0] = ~seg_g_on;
    end

endmodule