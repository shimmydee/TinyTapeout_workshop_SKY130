`timescale 1ns / 1ps

// THIS MODULE ACTUATES OUR BLINKING FUNCTION.
// IT GETS FED A 'PAINTING' - I.E., OUR SAVED PATTERN
// IT THEN USES OUR CURSORID TO 'DRAW' I.E., BLINK UPON THE PAINTING/SAVED PATTERN
// THIS DRAWING IS COMBINATIONALLY OUTPUT AS OUR DISPLAYPATTERN, WHICH GOES ONTO OUR DISPLAY DRIVERS

// BIG NOTE: AGAIN, OUR ENDIANESS CONVENTION (THIS USES BIG-ENDIAN VERSUS TASK 2'S LITTLE-ENDIAN) AND BUS WIDTH (28 VS 112) DO NOT MATCH UP, HOWEVER THIS IS 
// ALL DEALT IN THE TOP MODULE BECAUSE A) 

// NOTE: THE BLINKING EFFECT SWITCHES BETWEEN 4HZ AND 8HZ WHEN THE CURSOR HOVERS OVER A SELECTED SEGMENET OR AN UNSELECTED SEGMENT RESPECTIVELY
// NOTE: WE CREATE A BITMASK TO ACT AS OUT CURSOR LOCATION LOGIC
// NOTE: THIS IS AN ENTIRELY COMBIANTIONAL BLOCK BECAUSE THE UPSTREAM TOGGLE.V PUSHES OUT SYNCHRONOUSLY AND THE DOWNSTREAM DISPLAY_DRIVER.V IS ALSO COMBINATIONAL (AT LEAST ITS displayPattern PARTS ARE)
// note that the above note is old, WE INSTEAD PUSH displayPattern OUT AS USUAL BUT THE TOP MODULE DEALS WITH OUR ENDINANESS AND CHANNEL WIDTH

module blink(
    input wire [27:0] savedPattern,
    input wire [4:0] cursorID,
    input wire dividedClk4Hz, dividedClk8Hz,
    output wire [27:0] displayPattern
    );
    
    // Bitmask creation - see toggle.v
    wire [27:0] cursorMask = (28'h8000000 >> cursorID); 

    // bitwise AND and then OR operation allows us to easily check if the cursor is hovering over an active segment or not
    wire cursorOnActiveSegment = |(savedPattern & cursorMask);
    
    // We then pick the dividedClk frequency using a multiplexer
    // currentBlinkState will then be a 1-bit wire which connects to one of the two dividedClk's. We can widen this wire to help with the downstream operation (seen in the assign statement below)
    reg currentBlinkState;
    always @(*) begin
        if (cursorOnActiveSegment) currentBlinkState = dividedClk4Hz;
        else currentBlinkState = dividedClk8Hz;
    end
    
    // 'Draw' the painting based off where the cursor is, what its blink state is (note the replication syntax, learnt from Google), and the XOR operation (which performs our blink).
    assign displayPattern = savedPattern ^ (cursorMask & {28{currentBlinkState}});
    
endmodule
