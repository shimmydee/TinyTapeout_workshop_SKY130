`timescale 1ns / 1ps

// THIS MODULE WORKS ON THE FOLLWING IDEA:
// GIVEN THE BUTTON DIRECTION INPUTS AND CURRENT CURSOR POSITION, USES CASE STATEMENTS TO MAP THE INPUTS TO A 5-BIT 'CURSORID' 
// (5-BITS TO ALLOW FOR 28 = 4X7 SEGMENTS FOR ALL 4 DIGITS USING BINARY ENCODING).
// IN ESSENCE, THIS IS A (DEGENERATE) MOORE FSM WHICH DEPENDS CURRENT ON CURSOR POSITION (STATE). 
// THE BUTTON INPUTS INFLUENCE THE OUTPUT COMBINATIONALLY AT THE FOLLOWING CLOCK EDGE. 
// 'DEGENERATE' BECAUSE STATE ENCODING IS ALSO THE OUTPUT (NO OUTPUT LOGIC).
// FURTHER, WE ALLOW FOR AN INPUT SWITCH TO ENABLE THE AUTOLOOP

// It is important to explain the way the cursorID works. In essence, it encodes a 28-bit wide wire "displayPattern" which represents the 28 total segments into 5-bits:

// 28'b/ABCDEFG/ABCDEFG/ABCDEFG/ABCDEFG/ = 28'b/digit1/digit2/digit3/digit4/
// where the big-end represents the right-most digit 1 (anode 3) and the little-end represetns the last digit (anode 0).
// For example, cursorID = 28'd5 corresponds to displayPattern = 28'b0000010000000000000000000000, which will light up segment F1 (segment F of digit 1)
// NOTE that this endianness convention did not match up with that used in TASK 2 (which had digit 1 on the rightmost side) and also did not match its 112-bit wide wire. 
// This had to be compensated in our top modules which required some funky indexing. THIS WILL NEED TO BE OPTIMISED.
//
// It is also important to describe the adjacency (i.e., ordering and numbering) of the segments is presented below (following formatting done by hand):
// A: UP=D     DOWN=G   LEFT=F                            RIGHT=B
// B: UP=A     DOWN=C   LEFT=G                            RIGHT=<F of next digit right>
// C: UP=B     DOWN=D   LEFT=G                            RIGHT=<E of next digit right>
// D: UP=G     DOWN=A   LEFT=E                            RIGHT=C
// E: UP=F     DOWN=D   LEFT=<C of next digit left, wrap> RIGHT=G
// F: UP=A     DOWN=E   LEFT=<B of next digit left, wrap> RIGHT=G
// G: UP=A     DOWN=D   LEFT=F                            RIGHT=B (arbitrary, could have been E and C respectively)
//
// More precisely, horizontal moves that cross a digit boundary:
// B (right-side) of digit N going RIGHT -> F (left-side) of digit N+1
// C (right-side) of digit N going RIGHT -> E (left-side) of digit N+1  (C is lower-right)
// F (left-side)  of digit N going LEFT  -> B (right-side) of digit N-1
// E (left-side)  of digit N going LEFT  -> C (right-side) of digit N-1
// Horizontal boundary condition:
//   Going LEFT  from digit 1 wraps to digit 4's right side.
//   Going RIGHT from digit 4 wraps to digit 1's left side.
// Vertical boundary condition:
//   A UP, D DOWN: no movement (cursor stays put).
//
// NOTE: THE BEAUTY OF THIS 28-WIDE DESIGN IS THAT WE CAN MODIFY THE PATH THE AUTOLOOP TAKES BY GENERATING A SEQUENCE OF BITS THAT GET ADDED TO CURSORID. CURRENTLY, WE ARE JUST ADDING 1 CONSTANTLY (THUS GOING (F1->G1->A2->B2-> ETC.)
//       FURTHER, THE SAME SEGMENT ON A SEPERATE DIGIT IS ALWAYS A MULTIPLE OF 7. HENCE, A SEGMENT'S ABSOLUTE POSITION IS JUST MODULO 7.
//       FINALLY, WE CAN SIMPLY BIT SHIFT BY THE VALUE OF CURSOR ID INTO A 28-BIT WIDE WIRE TO REPRESENT THE TRUE MAPPING (AS ABOVE). This and the autoloop activation is done in the top module        
// NOTE: I CHOSE TO USE 2 COMBINATIONAL BLOCKS AND 1 SEQUENTIAL BLOCK TO SEPERATE THE AUTOLOOP/CASES LOGIC FROM THE NEXT-STATE SEQUENTIAL LOGIC - AIM IS TO MAKE IT EASIER TO DEBUG.


module cursor(
    input wire switchAutoLoop, beatAutoLoop, reset, sysclk, up, down, left, right, 
    output reg [4:0] cursorID
    );
    
    reg [4:0] next_cursorID;

    initial begin cursorID = 5'd5; end

    // AUTOLOOP COMBINATIONAL LOGIC
    reg [4:0] next_auto;
    always @(*) begin
        if (cursorID == 5'd27) next_auto = 5'd0;
        else next_auto = cursorID + 1;  
    end

    // CASES COMBINATIONAL LOGIC
    always @(*) begin
    
        next_cursorID = cursorID; // this makes sure that if nothing happens, that the cursor stays in teh same spot
    
        if (switchAutoLoop) begin // if switchAutoLoop, then autoloop
            if (beatAutoLoop) next_cursorID = next_auto; // might need to implement logic wherein it always starts from F1 when switchAutoLoop does posedge
        end else begin // else, use Moore FSM
            case (cursorID)
                
                // DIGIT 1
                5'd0: begin // A1
                    if (up) next_cursorID = 27'd3;
                    if (left) next_cursorID = 27'd5;
                    if (down) next_cursorID = 27'd6;
                    if (right) next_cursorID = 27'd1;
                end
                5'd1: begin // B1
                    if (up) next_cursorID = 27'd0;
                    if (left) next_cursorID = 27'd6;
                    if (down) next_cursorID = 27'd2;
                    if (right) next_cursorID = 27'd12;
                end
                5'd2: begin // C1
                    if (up) next_cursorID = 27'd1;
                    if (left) next_cursorID = 27'd6;
                    if (down) next_cursorID = 27'd3;
                    if (right) next_cursorID = 27'd11;
                end
                5'd3: begin // D1
                    if (up) next_cursorID = 27'd6;
                    if (left) next_cursorID = 27'd4;
                    if (right) next_cursorID = 27'd2;
                    if (down) next_cursorID = 27'd0;
                end
                5'd4: begin // E1
                    if (up) next_cursorID = 27'd5;
                    if (left) next_cursorID = 27'd23;
                    if (down) next_cursorID = 27'd3;
                    if (right) next_cursorID = 27'd6;
                end
                5'd5: begin // F1
                    if (up) next_cursorID = 27'd0;
                    if (left) next_cursorID = 27'd22;
                    if (down) next_cursorID = 27'd4;
                    if (right) next_cursorID = 27'd6;
                end
                5'd6: begin // G1
                    if (up) next_cursorID = 27'd0;
                    if (left) next_cursorID = 27'd5;
                    if (down) next_cursorID = 27'd3;
                    if (right) next_cursorID = 27'd1;
                end
                
                // DIGIT 2
                5'd7: begin // A2
                    if (up) next_cursorID = 27'd10;
                    if (left) next_cursorID = 27'd12;
                    if (down) next_cursorID = 27'd13;
                    if (right) next_cursorID = 27'd8;
                end
                5'd8: begin // B2
                    if (up) next_cursorID = 27'd7;
                    if (left) next_cursorID = 27'd13;
                    if (down) next_cursorID = 27'd9;
                    if (right) next_cursorID = 27'd19;
                end
                5'd9: begin // C2
                    if (up) next_cursorID = 27'd8;
                    if (left) next_cursorID = 27'd13;
                    if (down) next_cursorID = 27'd10;
                    if (right) next_cursorID = 27'd18;
                end
                5'd10: begin // D2
                    if (up) next_cursorID = 27'd13;
                    if (left) next_cursorID = 27'd11;
                    if (right) next_cursorID = 27'd9;
                    if (down) next_cursorID = 27'd7;
                end
                5'd11: begin // E2
                    if (up) next_cursorID = 27'd12;
                    if (left) next_cursorID = 27'd2;
                    if (down) next_cursorID = 27'd10;
                    if (right) next_cursorID = 27'd13;
                end
                5'd12: begin // F2
                    if (up) next_cursorID = 27'd7;
                    if (left) next_cursorID = 27'd1;
                    if (down) next_cursorID = 27'd11;
                    if (right) next_cursorID = 27'd13;
                end
                5'd13: begin // G2
                    if (up) next_cursorID = 27'd7;
                    if (left) next_cursorID = 27'd12;
                    if (down) next_cursorID = 27'd10;
                    if (right) next_cursorID = 27'd8;
                end
                
                // DIGIT 3
                5'd14: begin // A3
                    if (up) next_cursorID = 27'd17;
                    if (left) next_cursorID = 27'd19;
                    if (down) next_cursorID = 27'd20;
                    if (right) next_cursorID = 27'd15;
                end
                5'd15: begin // B3
                    if (up) next_cursorID = 27'd14;
                    if (left) next_cursorID = 27'd20;
                    if (down) next_cursorID = 27'd16;
                    if (right) next_cursorID = 27'd26;
                end
                5'd16: begin // C3
                    if (up) next_cursorID = 27'd15;
                    if (left) next_cursorID = 27'd20;
                    if (down) next_cursorID = 27'd17;
                    if (right) next_cursorID = 27'd25;
                end
                5'd17: begin // D3
                    if (up) next_cursorID = 27'd20;
                    if (left) next_cursorID = 27'd18;
                    if (right) next_cursorID = 27'd16;
                    if (down) next_cursorID = 27'd14;
                end
                5'd18: begin // E3
                    if (up) next_cursorID = 27'd19;
                    if (left) next_cursorID = 27'd9;
                    if (down) next_cursorID = 27'd17;
                    if (right) next_cursorID = 27'd20;
                end
                5'd19: begin // F3
                    if (up) next_cursorID = 27'd14;
                    if (left) next_cursorID = 27'd8;
                    if (down) next_cursorID = 27'd18;
                    if (right) next_cursorID = 27'd20;
                end
                5'd20: begin // G3
                    if (up) next_cursorID = 27'd14;
                    if (left) next_cursorID = 27'd19;
                    if (down) next_cursorID = 27'd17;
                    if (right) next_cursorID = 27'd15;
                end
                
                // DIGIT 4
                5'd21: begin // A4
                    if (up) next_cursorID = 27'd24;
                    if (left) next_cursorID = 27'd26;
                    if (down) next_cursorID = 27'd27;
                    if (right) next_cursorID = 27'd22;
                end
                5'd22: begin // B4
                    if (up) next_cursorID = 27'd21;
                    if (left) next_cursorID = 27'd27;
                    if (down) next_cursorID = 27'd23;
                    if (right) next_cursorID = 27'd5;
                end
                5'd23: begin // C4
                    if (up) next_cursorID = 27'd22;
                    if (left) next_cursorID = 27'd27;
                    if (down) next_cursorID = 27'd24;
                    if (right) next_cursorID = 27'd4;
                end
                5'd24: begin // D4
                    if (up) next_cursorID = 27'd27;
                    if (left) next_cursorID = 27'd25;
                    if (right) next_cursorID = 27'd23;
                    if (down) next_cursorID = 27'd21;
                end
                5'd25: begin // E4
                    if (up) next_cursorID = 27'd26;
                    if (left) next_cursorID = 27'd16;
                    if (down) next_cursorID = 27'd24;
                    if (right) next_cursorID = 27'd27;
                end
                5'd26: begin // F4
                    if (up) next_cursorID = 27'd21;
                    if (left) next_cursorID = 27'd15;
                    if (down) next_cursorID = 27'd25;
                    if (right) next_cursorID = 27'd27;
                end
                5'd27: begin // G4
                    if (up) next_cursorID = 27'd21;
                    if (left) next_cursorID = 27'd26;
                    if (down) next_cursorID = 27'd24;
                    if (right) next_cursorID = 27'd22;
                end
                
                default: next_cursorID = 5'd5; // fallback to left-most digit top-left (segment F1) if cursorID is invalid 
                
            endcase
        end
    end
    
    // NEXT-STATE SEQUENTIAL LOGIC
    always @(posedge sysclk) begin
        if(reset) cursorID <= 5'd5; // reset to F1
        else cursorID <= next_cursorID;
    end
    
endmodule
