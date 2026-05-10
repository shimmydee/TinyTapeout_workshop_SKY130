`timescale 1ns / 1ps

// Task 2 combined top-module.
// First conditions the buttons, then instantiates heartbeat and performs either global brightness register mdoule 
// or pattern_index (and pattern_data retrieval) depending on mode (thanks to gated inputs using mode_level2).
// Then calls the multiplexer frame source task 2 module which thus drives the PWM modeul


module Task_2_TOP(
    input wire clk, reset,
    input wire btnC, btnL, btnR, btnU, btnD,
    input wire [15:0] sw,
    output wire [15:0] led,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire dp
);

    assign dp = 1'b1; // hardcode

    // mode/level selector
    wire mode_level2 = sw[0];

    // Button conditioning
    wire btnC_level, btnL_level, btnR_level, btnU_level, btnD_level;
    wire btnC_pulse, btnL_pulse, btnR_pulse, btnU_pulse, btnD_pulse;

    button_conditioning u_btns (.sysclk(clk),
        .reset(reset), // sw[15] from master top
        .btnC(btnC), .btnL(btnL), .btnR(btnR), .btnU(btnU), .btnD(btnD),
        .btnC_level(btnC_level), .btnL_level(btnL_level), .btnR_level(btnR_level),
        .btnU_level(btnU_level), .btnD_level(btnD_level),
        .btnC_pulse(btnC_pulse), .btnL_pulse(btnL_pulse), .btnR_pulse(btnR_pulse),
        .btnU_pulse(btnU_pulse), .btnD_pulse(btnD_pulse),
        .beat_out()
    );

    // 8Hz heartbeat instantiation
    wire brightness_step_tick;
    heartbeat #(.THRESHOLD(1_562_500)) u_brightTick (.sysclk(clk), .enable(1'b1), .reset(reset), .beat(brightness_step_tick), .dividedClk());

    // Global brightness register instantiation
    wire [3:0] global_brightness;
    global_brightness_register u_brightness (.clk(clk), .reset(reset),
        .btn_center_level(btnC_level & ~mode_level2),  // only active in level 1
        .step_tick(brightness_step_tick), .global_brightness(global_brightness));

    // Pattern selector (only active in level 2)
    wire [2:0] pattern_index;
    pattern_selector #(.NUM_PATTERNS(8)) u_patSel (.clk(clk), .reset(reset), .btn_left_pulse(btnL_pulse & mode_level2), .btn_right_pulse(btnR_pulse & mode_level2), .pattern_index(pattern_index));

    // extract pattern_data from memory
    wire [111:0] pattern_data;
    pattern_store u_patterns (.pattern_index(pattern_index), .pattern_data(pattern_data));

    // Frame source selector
    wire [111:0] brightness_map;
    task2_frame_source u_frame (.mode_level2(mode_level2), .global_brightness(global_brightness), .pattern_data(pattern_data), .brightness_map(brightness_map));

    // sevenSegmentPWM instantiation
    SevenSegement_PWM u_pwm (.clk(clk), .reset(reset), .brightness_map(brightness_map), .seg(seg), .an(an));

    // LED outputs: please note that these should instead be done in master_TOP by exposing global_brightness and pattern_index, but oh well too late now
    assign led[0] = mode_level2;
    assign led[3:1] = pattern_index;
    assign led[7:4] = global_brightness;
    assign led[15:8] = 8'b0;

endmodule