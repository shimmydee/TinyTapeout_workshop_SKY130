`timescale 1ns / 1ps

// Master top-level module: instantiates Task 1, 2, 3 and routes between them.
// Importantly, this design uses gated wires and buttons that mean only one task is active at a time. 
// This probably wastes hardware, but was easier to visualise and implement.
// NOTE the decimal point wire could immediately be hardcoded as 0, but in the off case this code is used again in the future 
// we could make it active instead, thus having them linked in top module is helpful

module master_top (
    input  wire        sysclk,
    input  wire        btnC, btnU, btnD, btnL, btnR,
    input  wire [15:0] sw,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp,
    output wire [15:0] led
);

    // Mode gating to ensure only one task is active at a time
    wire task1_active = sw[1] & ~sw[2];
    wire task2_active = ~sw[1] & sw[2];
    wire task3_active = sw[1] & sw[2];

    // Button input gating using the active logic above
    wire btnC_t1 = btnC & task1_active;
    wire btnU_t1 = btnU & task1_active;
    wire btnD_t1 = btnD & task1_active;
    wire btnL_t1 = btnL & task1_active;
    wire btnR_t1 = btnR & task1_active;
    wire btnC_t2 = btnC & task2_active;
    wire btnU_t2 = btnU & task2_active;
    wire btnD_t2 = btnD & task2_active;
    wire btnL_t2 = btnL & task2_active;
    wire btnR_t2 = btnR & task2_active;
    wire btnC_t3 = btnC & task3_active;
    wire btnU_t3 = btnU & task3_active;
    wire btnD_t3 = btnD & task3_active;
    wire btnL_t3 = btnL & task3_active;
    wire btnR_t3 = btnR & task3_active;

    // Task 1 instantiation
    wire [6:0] seg_t1;
    wire [3:0] an_t1;
    wire dp_t1;

    Task_1_TOP u_task1 (.sysclk (sysclk), .btnC(btnC_t1), .btnU(btnU_t1), .btnD(btnD_t1), .btnL(btnL_t1), .btnR(btnR_t1), .sw(sw), .seg(seg_t1), .an(an_t1), .dp(dp_t1));

    // Task 2 instantiation
    wire [6:0] seg_t2;
    wire [3:0] an_t2;
    wire dp_t2;
    wire [15:0] led_t2;

    Task_2_TOP u_task2 (.clk(sysclk), .reset(sw[15]), .btnC(btnC_t2), .btnL(btnL_t2), .btnR(btnR_t2), .btnU(btnU_t2), .btnD(btnD_t2), .sw(sw), .seg(seg_t2), .an(an_t2), .dp(dp_t2), .led(led_t2));

    wire [2:0] t2_pattern_index = led_t2[3:1]; // hardcode. probably a bit awkward

    // Task 2 Level 2 last pattern index memory
    reg [2:0] last_t2_index;
    initial last_t2_index = 3'd0;
    always @(posedge sysclk) begin
        if (task1_active) last_t2_index <= 3'd0;
        else if (task2_active && sw[0]) last_t2_index <= t2_pattern_index;
    end

    // Task 3 instantiation
    wire [6:0] seg_t3;
    wire [3:0] an_t3;
    wire dp_t3;
    wire [2:0] led_page_t3;

    Task_3_TOP u_task3 (.sysclk(sysclk), .btnC(btnC_t3), .btnU(btnU_t3), .btnD(btnD_t3), .btnL(btnL_t3), .btnR(btnR_t3), .sw(sw), .last_t2_index(last_t2_index), .seg(seg_t3), .an(an_t3), .dp(dp_t3), .led_page(led_page_t3));

    // Outut mux that drives the final output
    // Uses ternary operators instead of if-else statements for neatness sake.
    assign seg = task1_active ? seg_t1 :
                 task2_active ? seg_t2 :
                 task3_active ? seg_t3 :
                 7'b1111111;

    assign an  = task1_active ? an_t1 :
                 task2_active ? an_t2 :
                 task3_active ? an_t3 :
                 4'b1111;

    assign dp  = task1_active ? dp_t1 : // note again that this is not totally necessary and can be hardcoded to 1'b1. However, we leave it wired up in case we want to activate the DP at some point
                 task2_active ? dp_t2 :
                 task3_active ? dp_t3 :
                 1'b1;

    // LED assignments
    assign led[0] = (task1_active | task2_active) ? sw[0] : 1'b0; // makes sure it is off in task 3
    assign led[3:1] = task2_active ? t2_pattern_index :
                       task3_active ? last_t2_index : 3'b0; // ensures that the visualisation is open no matter in task 2 or 3. Is off in task 1 because irrelevant
    assign led[6:4] = task1_active ? 3'b0 : sw[6:4]; // only relevant for task 2 and 3, shows which page task 3 is on
    assign led[8:7] = 2'b0; // hardcode
    assign led[12:9] = task2_active ? led_t2[7:4] : 4'b0; // tasks 2 brightness. Is only on in task 2. Stays lit no matter waht level in task 2.
    assign led[13] = task1_active;
    assign led[14] = task2_active;
    assign led[15] = task3_active;

endmodule