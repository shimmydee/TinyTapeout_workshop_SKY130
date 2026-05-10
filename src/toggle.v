`timescale 1ns / 1ps

// THIS MODULE ACTS AS THE MEMORY AS WELL AS ACTIONS THE TOGGLE LOGIC WHEN ACTIVATED BY spotCentre.
// IN ESSENCE, IT CREATES A BITMASK USING CURSORID THAT WILL BE USED TO PARITY CHECK (XOR) THE SAVEDPATTERN. 
// I.E., PARTIY CHECK = XOR OPERATION WHICH WILL FLIP THE MASKED BIT IF THE BITMASK AND THE SAVEDPATTERN IS DIFFERENT AT THAT LOCATION - HENCE OUR 'TOGGLE' LOGIC
// IT STORES THIS INTO A HOLD REGISTER AT EVERY CLOCK EDGE, WHICH HAS ITS DATA PUSHED OUT INTO DOWNSTREAM MODULES TO BE PROCESSED (I.E., BLINK USES savedPattern TO ACTION IS 'BLINK' FUNCTIONALITY)

module toggle(
    input wire spotCentre, sysclk, reset,
    input wire [4:0] cursorID,
    output reg [27:0] savedPattern
    );

    initial savedPattern = 28'd0;

    // Bitmask creation (identical to cursor displayPattern from task 1.1, however since task 1.2's "displayPattern" is now the output of the blink module, it cannot function as our bitmask, hence the creation of this new wire
    wire [27:0] cursorMask = (28'h8000000 >> cursorID);
    
    always @(posedge sysclk) begin
        if (reset) begin
            savedPattern <= 28'd0; // clears display completely, this works because it hands this off to blink as its 'painting' to draw ('blink') on - which in this case is just blank
        end else if (spotCentre) begin
            savedPattern <= savedPattern ^ cursorMask; // XOR operation here, with logic explained above.
        end
    end
    
endmodule
