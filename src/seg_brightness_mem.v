`timescale 1ns / 1ps

// This module predominantly functions as the glue between task 1 and task 2, which have some of their task-specific module outputs (i.e., cursorID from task 1,
// task3_page and pattern_data from task 2) linked together with buttons (centre for toggling and brightness control) and switches (sw[15] for loading).
// Importantly, it also performs logic to determine whether the centre button is being "rapidly pressed/tapped" or held, thus determinign whether it should toggle the segment
// or ramp its brightness. We decide to implement all this logic in this module because this specific hold + press logic is unique to task 3, and won't need to be called elsewhere.
// The output is 112-bit wide reg that is the pattern of that page in task 3. This gets processed by task 3 frame source, which adds a blinking cursor, and then onto the PWM driver.

module seg_brightness_mem (
    input wire sysclk, reset,
    input wire [2:0] task3_page,
    input wire [4:0] cursorID,
    input wire btnC_level, // HIGH while centre button held
    input wire brightness_step_tick, // ~8Hz from tick_generator
    input wire load_pulse, // sw[14] load T2 pattern
    input wire [111:0] pattern_data, // from pattern_store (last T2 L2)
    output reg [111:0] seg_brightness_flat // the 112-bit word representign page i
);

    reg [3:0] mem [0:7][0:27]; // this is a 8 page, 28-segment memory with an addressability of 4-bits (brightness). 
                               // We write to this depending on the button and switch inputs, as well as the last viewed pattern in Task 2 Level 2.

    // This loops through all 28 segments of whichever page task3_page currently selects, and packs each 4-bit brightness value into the flat 112-bit output bus
    integer rd;
    always @(*) begin // combinational = means an instant exposure of the wanted page to output downstream to task 3 frame source. Good!
        for (rd = 0; rd < 28; rd = rd + 1)
            seg_brightness_flat[rd*4 +: 4] = mem[task3_page][rd];
    end

    // Defines the 500ms threshold constant and declares the three state registers that drive the FSM. hold_counter is 26 bits because 2^26 = 67M which is large enough to count to 50M without overflow
    localparam integer HOLD_THRESH = 12_500_000; // this is equivalent to 500ms @ 100MHz
    reg [23:0] hold_counter; // 2^26 = 67M > 50M
    reg hold_mode; // Helps us understand whether it was a tap or a hold. It goes HIGH when hold_counter crosses the 500ms threshold and stays HIGH until release.
                   // i.e., hold_mode=0 on release -> it was a short press -> fire TAP. hold_mode=1 on release -> it was a long press -> do nothing (ramp already happened)
    reg was_pressing; // It goes HIGH the moment btnC_level goes HIGH and stays HIGH until the button is released and the state resets. Its sole purpose is to prevent a false TAP firing on the very first release after reset.

    integer init_i, init_j;
    initial begin
        hold_counter = 24'd0;
        hold_mode    = 1'b0;
        was_pressing = 1'b0;
        for (init_i = 0; init_i < 8; init_i = init_i + 1)
            for (init_j = 0; init_j < 28; init_j = init_j + 1)
                mem[init_i][init_j] = 4'd0;
    end

    integer i; // declare an index for our for loops
    always @(posedge sysclk) begin

        // RESET BRANCH
        // Resets the FSM state and clears all 28 segments of the currently active page to 0. Other pages are untouched.
        if (reset) begin // clear only the active page and keeps other pages are preserved
            hold_counter <= 0;
            hold_mode <= 0;
            was_pressing <= 0;
            for (i = 0; i < 28; i = i + 1) // loops through all of the 28 memory cells, probably could be done more elegantly.
                mem[task3_page][i] <= 4'd0;

        // LOAD BRANCH (also a reset branch)
        // When sw[14] fires a single-cycle pulse, copies the last viewed Task 2 Level 2 pattern into the active page. The address remapping formula converts between Task 1/3 and Task 2 digit ordering conventions. Also resets FSM state since a load is treated as a fresh start.
        end else if (load_pulse) begin  // copy last-viewed Task 2 Level 2 pattern into active page.
            hold_counter <= 0;
            hold_mode <= 0;
            was_pressing <= 0;
            for (i = 0; i < 28; i = i + 1)
                mem[task3_page][i] <= pattern_data[((3 - i/7)*7 + i%7)*4 +: 4]; // 3 - i/7 flips the digit ordering (Task 1 leftmost=0, Task 2 rightmost=0)

        // BUTTON HELD BRANCH
        end else if (btnC_level) begin 
            was_pressing <= 1; // record that the button was pressed!
            
            // If not yet in hold mode (i.e., button not presed for 500ms): counts up hold_counter each cycle until 500ms is reached, then enters hold mode and snaps brightness to 1 (unless already mid-range)
            if (!hold_mode) begin 
                if (hold_counter < HOLD_THRESH - 1) hold_counter <= hold_counter + 1; // up-counter with the 500ms threshold
                else begin // once threshold has been reached, set the starting brightness to 1 if extreme, or start from the current otherwise
                    hold_mode <= 1; // record that we have entered hold mode
                    if (mem[task3_page][cursorID] == 4'd0 || mem[task3_page][cursorID] == 4'd15) 
                        mem[task3_page][cursorID] <= 4'd1;
                    // else: do nothing and keep current value. If a new hold mode comes through then we ramp from this brightness value. This does cause a 1 second lag if the segment is at an extreme, but this can be optimised in the future.
                end
            end else begin // If already in hold mode: increments the cursor segment's brightness by 1 on each 8Hz tick, clamping at 15
                if (brightness_step_tick) begin
                    if (mem[task3_page][cursorID] < 4'd15) 
                        mem[task3_page][cursorID] <= mem[task3_page][cursorID] + 1'b1;
                end
            end
        
        // TAP BRANCH    
        // This is the TAP handler - it only fires if was_pressing=1 (a real press occurred) and hold_mode=0 (it was short enough to be a tap). If both conditions are met it toggles the cursor segment between 0 and 15. Then regardless of whether a TAP fired, it resets all three FSM state registers ready for the next press.
        end else begin
            // Button not held/released
            if (was_pressing && !hold_mode) begin // thus, if a TAP happened then do a toggle
                if (mem[task3_page][cursorID] == 4'd0)
                    mem[task3_page][cursorID] <= 4'd15;
                else
                    mem[task3_page][cursorID] <= 4'd0; // turns off if the segment has a brightness
            end
            // always reset hold state on release, regardless of whether TAP fired
            hold_counter <= 0;
            hold_mode <= 0;
            was_pressing <= 0;
        end
    end

endmodule