`timescale 1ns / 1ps

// Task 1 combined top-level module
// The buttons are first conditioned, and other switches synchornised + debbed + level selector logic implemented
// Then instantiate cursor and toggle modules, and assign the wires which are the display frames for the 7SD - then multiplexes them depending on mode.
// Then uses a 'generate' function (based off of Gemini recommendation) to expand a 28-bit map to 112-bit brightness_map_t1 which allows it to be inputted into the PWM driver.

module Task_1_TOP (
    input wire sysclk,
    input wire btnC, btnU, btnD, btnL, btnR,
    input wire [15:0] sw,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire dp
);

    assign dp = 1'b1; // hardcode to stop decimal points from floating

    // BUTTON CONDITIONING
    wire beat;
    wire debC, debU, debD, debL, debR;
    wire spotC, spotU, spotD, spotL, spotR;
    
    button_conditioning u_btns (.sysclk(sysclk),
        .reset(levelSysReset),  // assigned see below
        .btnC(btnC), .btnU(btnU), .btnD(btnD), .btnL(btnL), .btnR(btnR),
        .btnC_level(debC), .btnU_level(debU),  .btnD_level(debD),
        .btnL_level(debL), .btnR_level(debR),
        .btnC_pulse(spotC), .btnU_pulse(spotU), .btnD_pulse(spotD),
        .btnL_pulse(spotL), .btnR_pulse(spotR),
        .beat_out(beat)
    );

    // SYNCHRONISERS AND DEBOUCNERS FOR SWITCHES. This definetely could have been done in button_conditionign module, but we didn't realise whilst writing it and it was easy enough to put in.
    reg [1:0] ff_rst, ff_lvl, ff_auto;
    initial begin ff_rst = 2'b00; ff_lvl = 2'b00; ff_auto = 2'b00; end
    always @(posedge sysclk) begin
        ff_rst <= {ff_rst[0], sw[15]};
        ff_lvl <= {ff_lvl[0], sw[0]};
        ff_auto <= {ff_auto[0], sw[3]};
    end

    wire debSysReset, debLevelSel, debAutoLoop; // devLevelSel = 0 for level 1
    debouncer u_debRst (.deb_in(ff_rst[1]), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debSysReset));
    debouncer u_debLvl (.deb_in(ff_lvl[1]), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debLevelSel));
    debouncer u_debAuto (.deb_in(ff_auto[1]), .sysclk(sysclk), .reset(1'b0), .beat(beat), .deb_out(debAutoLoop));

    // Autolooper and LEFT+RIGHT system reset
    wire autoloopActive = debAutoLoop & ~debLevelSel; // i.e., only on in level 2
    wire levelSysReset  = debSysReset | ((debL & debR) & debLevelSel); // note that this is a level-sensitive reset, not an edge sensitive one!

    // Heartbeat instantiations
    wire dividedClk4Hz, dividedClk8Hz, beatAutoLoop; //autoloop is at 2Hz, but this can be changed easily
    heartbeat #(.THRESHOLD(3_125_000)) u_beat4Hz (.sysclk(sysclk), .enable(1'b1), .reset(1'b0), .beat(), .dividedClk(dividedClk4Hz));
    heartbeat #(.THRESHOLD(1_562_500)) u_beat8Hz (.sysclk(sysclk), .enable(1'b1), .reset(1'b0), .beat(), .dividedClk(dividedClk8Hz));
    heartbeat #(.THRESHOLD(6_250_000)) u_beatAutoLoop(.sysclk(sysclk), .enable(debAutoLoop), .reset(1'b0), .beat(beatAutoLoop), .dividedClk());

    // Cursor instantiation
    wire [4:0] cursorID;
    cursor u_cursor (.switchAutoLoop(autoloopActive), .beatAutoLoop(beatAutoLoop), .reset(levelSysReset), .sysclk(sysclk),
        .up(spotU), .down(spotD), .left(spotL), .right(spotR),
        .cursorID(cursorID)
    );

    // Toggle instantiation
    wire [27:0] savedPattern;
    toggle u_toggle (.spotCentre(spotC & debLevelSel), // only active in level 2
        .sysclk(sysclk), .reset(levelSysReset | ~debLevelSel), // resets also if in level 1 as we don't want to ever toggle
        .cursorID(cursorID), .savedPattern(savedPattern)
    );

    // Display frames for Level 1 and Level 2 (w/ Blink instantiation)
    wire [27:0] displayPattern_L1 = (28'h8000000 >> cursorID); // MAGIC SAUCE of bit shifting in our cursorID to get our 28-segment one-hot

    wire [27:0] displayPattern_L2;
    blink u_blink (.savedPattern(savedPattern), .cursorID(cursorID), .dividedClk4Hz(dividedClk4Hz), .dividedClk8Hz(dividedClk8Hz), .displayPattern(displayPattern_L2));

    wire [27:0] displayPattern = debLevelSel ? displayPattern_L2 : displayPattern_L1; // multiplexes our displayPattern depending on level

    // 28-bit to 112-bit brightness_map expansion to drive SevenSegement_PWM
    // IMPORTANT: Task 1 segment index i (0=A of Digit1/AN3/leftmost, 27=G of Digit4/AN0)
    // And displayPattern bit: [27-i]  (cursorMask = 28'h8000000 >> i convention)
    // Thus brightness_map index base: ((3-i/7)*7 + i%7) * 4. We need to fill up the remaining 4 as well
    // NOTE:(3-i/7) converts Task1 digit index to PWM digit index (0=rightmost)
    wire [111:0] brightness_map_t1;
    genvar j;
    generate // using a generate function was a suggestion by Gemini to our previous hardcoded version: e.g., assign brightness_map_t1[84  +: 4] = displayPattern[27] ? 4'd15 : 4'd0; (for j=0)
        for (j = 0; j < 28; j = j + 1) begin : gen_bmap
            assign brightness_map_t1[((3-j/7)*7+j%7)*4 +: 4] = // THIS FIXES OUR ENDIANNESS AND BUS-WIDTH PROBLEM, THUS ALLOWING US TO USE THE SAME PWM MODULE FOR TASK 1
                   displayPattern[27-j] ? 4'd15 : 4'd0;        // since we do not care about brightness levels, we use ternary operator to force either high or low if a value exists in the 4 selected bits
        end
    endgenerate

    // SevenSegmentPWM Driver Instantiation
    SevenSegement_PWM u_pwm (.clk(sysclk), .reset(levelSysReset), .brightness_map(brightness_map_t1), .seg(seg), .an(an));

endmodule