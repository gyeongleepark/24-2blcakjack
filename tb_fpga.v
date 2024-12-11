`timescale 1ns / 1ps

module tb_fpga;

    ////////////////////////////////////////////////////////////////////////
    // This testbench works like an FPGA.
    // The top module segment_display.v instantiated in this tb is a module for interfacing FPGA. 
    // You should design your own modules INSIDE the segment_display.v to play blackjack.
    ////////////////////////////////////////////////////////////////////////

    // inputs from the FPGA; ** DO NOT CHANGE **
    reg clk = 0;
    reg reset = 0;
    reg next = 0;
    reg hit = 0;
    reg stand = 0;
    reg double = 0;
    reg split = 0;
    reg bet_8 = 0;
    reg bet_4 = 0;
    reg bet_2 = 0;
    reg bet_1 = 0;
    
    // outputs to the FPGA; ** DO NOT CHANGE **
    wire LED_split;
    wire LED_Win;
    wire LED_Lose;
    wire LED_Draw;
    wire [3:0] Anode_Activate;
    wire [6:0] LED_out;
    
    
    segment_display uut (
        .clk (clk),
        .reset (reset),
        .next (next),
        .hit (hit),
        .stand (stand),
        .double (double),
        .split (split),
        .bet_8 (bet_8),
        .bet_4 (bet_4),
        .bet_2 (bet_2),
        .bet_1 (bet_1),
        .Anode_Activate (Anode_Activate),
        .LED_out (LED_out),
        .LED_split (LED_split),
        .LED_Win (LED_Win),
        .LED_Lose (LED_Lose),
        .LED_Draw (LED_Draw)
    );
    
    
    localparam period = 0.5;

    // Create fake clock  
    always
    begin
        clk = 1'b0;
        #period;
        clk = 1'b1;
        #period;
    end
    
    
    // Play blackjack! 
    // You can freely modify this part to test the operations you implemented. (You may need to implement additional cases as well.)
    // These are just some Examples.
    initial
    begin
        // reset
        reset = 1;
        #100;
        reset = 0;
        #100;
        
        // Coin betting
        bet_8 = 0;
        bet_4 = 1;
        bet_2 = 1;
        bet_1 = 0;
        #100;
        bet_4 = 0;
        bet_2 = 0;
        bet_1 = 0;
        
        // Press the "Next" button: one of the dealer's cards will be revealed.
        next = 1;
        #100;
        next = 0;
        #100;
        
        // Press the "Next" button: the phase will change to the Player Card phase.
        next = 1;
        #100;
        next = 0;
        #100;
        
        // Assume you are lucky; you can hit (unless you bust).
        hit = 1;
        #100;
        hit = 0;
        #100;
        
        // You would stand now.
        stand = 1;
        #100;
        stand = 0;
        #100;
        
        // The dealer's card is revealed! Press "Next" to proceed to the result.
        next = 1;
        #100;
        next = 0;
        #100;
	
	   // Proceed to the next betting phase.
	    next = 1;
        #100;
        next = 0;
        #100;
        
        $finish;
    end
    
    
endmodule