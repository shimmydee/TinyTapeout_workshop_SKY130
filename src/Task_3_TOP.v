`timescale 1ns / 1ps

// TASK 3 TOP MODULE
// This module first conditions the buttons, then syncs and debbs (and SPOTs a) the switches.
// then instantiates heartbeats, before INSTANTIATING SEG_BRIGHTNESS_MEM WHICH IS THE MAIN LOGIC FOR THIS MODULE.
// This brightness map then gets fed to a frame sourcer which adds blinking logic, before outputting to a hold register
// which was necessitated by timing violations encountered in earlier designs.
// Finally, this hold register is consitently exposed to the sevenSegmentPWM Driver

module Task_3_TOP (
    input wire sysclk,
    input wire btnC, btnU, btnD, btnL, btnR,
    input wire [15:0] sw,
    input wire [2:0] last_t2_index, // last Task 2 Level 2 page fed in from master top
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire dp,
    output wire [2:0] led_page
);

    assign dp = 1'b1; //hardcoded
    assign led_page = sw[6:4]; //hardcoded assignment

    // Button conditionin
    wire beat;
    wire debC, debL, debR;
    wire btnU_pulse, btnD_pulse, btnL_pulse, btnR_pulse;

    button_conditioning u_btns (
        .sysclk(sysclk),
        .reset(levelSysReset), // assigned see below
        .btnC(btnC), .btnU(btnU), .btnD(btnD), .btnL(btnL), .btnR(btnR),
        .btnC_level(debC), // used for seg_brightness_mem
        .btnU_level(), .btnD_level(), // unused (pulses used for cursor)
        .btnL_level(debL), .btnR_level(debR), // used for levelSysReset
        .btnC_pulse(),  // debC level is used for tap/hold logic
        .btnU_pulse(btnU_pulse), .btnD_pulse(btnD_pulse), .btnL_pulse(btnL_pulse), .btnR_pulse(btnR_pulse),
        .beat_out(beat) // shared 1kHz beat for debouncers below
    );

    // Synchronisers and debbing for swithches
    reg [1:0] ff_load, ff_rst;
    initial begin ff_load = 2'b00; ff_rst = 2'b00; end
    always @(posedge sysclk) begin
        ff_load <= {ff_load[0], sw[14]};
        ff_rst <= {ff_rst[0],  sw[15]};
    end

    wire debLoadSw, debGlobalReset;
    debouncer u_debLoad (.deb_in(ff_load[1]), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debLoadSw));
    debouncer u_debRst (.deb_in(ff_rst[1]), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debGlobalReset));

    // Level reset that is either the gloval reset (switch) or LEFT+RIGHT
    wire levelSysReset = debGlobalReset | (debL & debR);

    // SPOT for (debbed) load signal. 
    wire spotLoad;
    spot u_spotLoad (.spot_in(debLoadSw), .sysclk(sysclk), .reset(levelSysReset), .spot_out(spotLoad));

    // Cursor instantiation
    wire [4:0] cursorID;
    cursor u_cursor (
        .switchAutoLoop(1'b0), .beatAutoLoop  (1'b0), //not needed
        .reset(levelSysReset), .sysclk(sysclk),
        .up(btnU_pulse), .down(btnD_pulse), .left(btnL_pulse), .right(btnR_pulse),
        .cursorID(cursorID)
    );

    // Heartbeat instantiations for blinker
    wire dividedClk4Hz, dividedClk8Hz;
    heartbeat #(.THRESHOLD(3_125_000)) u_beat4Hz (.sysclk(sysclk), .enable(1'b1), .reset(1'b0),.beat(), .dividedClk(dividedClk4Hz));
    heartbeat #(.THRESHOLD(1_562_500)) u_beat8Hz (.sysclk(sysclk), .enable(1'b1), .reset(1'b0), .beat(), .dividedClk(dividedClk8Hz));

    // 8Hz brightness step tick (hopefully this jsut knows the 8Hz wires are the same... but I need this for the different wire name
    wire brightness_step_tick;
    heartbeat #(.THRESHOLD(1_562_500)) u_brightTick (.sysclk(sysclk), .enable(1'b1), .reset(levelSysReset), .beat(brightness_step_tick), .dividedClk());

    // pattern_store instantiation and memory (uses last_t2_index from master top)
    wire [111:0] last_t2_pattern_data;
    pattern_store u_loadSrc (.pattern_index(last_t2_index),.pattern_data(last_t2_pattern_data));

    // SEGMENT BRIGHTNESS MEMORY INSTANTIATION
    // THIS IS THE GLUE FOR TASK 3, AND IS 1/2 UNIQUE MODULES
    wire [111:0] seg_brightness_flat;
    seg_brightness_mem u_mem (.sysclk(sysclk), .reset(levelSysReset), .task3_page(sw[6:4]), .cursorID(cursorID), .btnC_level(debC), .brightness_step_tick(brightness_step_tick), .load_pulse(spotLoad), .pattern_data(last_t2_pattern_data), .seg_brightness_flat(seg_brightness_flat));

    // Task 3 Frame Source instantiation
    // THIS IS THE 2/2 UNIQUE MODULE FOR TASK 3
    wire [111:0] brightness_map_comb;
    task3_frame_source u_frame (.seg_brightness_flat(seg_brightness_flat), .cursorID(cursorID), .btnC_level(debC), .dividedClk4Hz(dividedClk4Hz), .dividedClk8Hz(dividedClk8Hz), 
                                .brightness_map(brightness_map_comb));

    // HOLD REGISTER for the combinational source frame. This breaks up a very long combiantional path of :
    // seg_brightness_mem (reads RAM) -> task3_frame_source (28 MUXs + blink combinational logic) ->
    // THIS HOLD REGISTER (has added due to timing violations) -> SevenSegement_PWM
    reg [111:0] brightness_map_r;
    initial brightness_map_r = 112'd0;
    always @(posedge sysclk)
        brightness_map_r <= brightness_map_comb;

    // SevenSegmentPWM Driver
    SevenSegement_PWM u_pwm (.clk(sysclk), .reset(levelSysReset), .brightness_map(brightness_map_r), .seg(seg), .an(an));

endmodule