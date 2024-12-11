`timescale 1ns / 1ps

module tb;
/*
    < Module Description: Testbench for top.v.>
    This module is a testbench designed to verify the functionality of the top.v module, 
    which is instantiated within the segment_display.v module.
    In this testbench, the inputs and outputs of the top module are predefined, 
    but you are free to add or remove inputs and outputs as needed. 
    You can test four cases using this module along with the card_generation.v module.
*/

    // Inputs to the top module
    reg clk;    
    reg reset;
    reg next;
    reg hit;
    reg stand;
    reg double;  
    reg split;
    reg bet_8;
    reg bet_4;
    reg bet_2;
    reg bet_1;
    
    // Outputs from the top module
    wire [5:0] player_current_score, player_new_card;
    wire [5:0] player_current_score_split, player_new_card_split;
    wire [5:0] dealer_current_score;
    wire [4:0] current_coin;
    wire can_split;
    wire Win;
    wire Lose;
    wire Draw;
    
    // Instantiate the top module
    top u_top (
        .clk(clk),
        .reset(reset),
        .next(next),
        .hit(hit),
        .stand(stand),
        .double(double),
        .split(split),
        .bet_8(bet_8),
        .bet_4(bet_4),
        .bet_2(bet_2),
        .bet_1(bet_1),
        .player_current_score(player_current_score),
        .player_new_card(player_new_card),
        .player_current_score_split(player_current_score_split),
        .player_new_card_split(player_new_card_split),
        .dealer_current_score(dealer_current_score),
        .current_coin(current_coin),
        .can_split(can_split),
        .Win(Win),
        .Lose(Lose),
        .Draw(Draw)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end
    
    initial begin
        // Initialize signals
        reset = 1;
        next = 0;
        hit = 0;
        stand = 0;
        double = 0;
        split = 0;
        bet_8 = 0;
        bet_4 = 0;
        bet_2 = 0;
        bet_1 = 0;
        
        // Release reset and start the test
        #20 reset = 0;
        
        // Bet coins
        #20 bet_8 = 0;
            bet_4 = 0;
            bet_2 = 1;
            bet_1 = 1;
            
        // Press next button (Betting phase -> Dealer card phase)
        #20 next = 1;
        #20 next = 0;
        
        // Press next button (Dealer card phase -> Player card phase)
        #20 next = 1;
        #20 next = 0;
        
        
        ///////////////////////////////////////////////////////////
        // Test case 1: Simple case 
            // Player's first two cards are 10, 8       
            // Press hit
        #40 hit = 1;           
        #20 hit = 0;
            // New card is 4
            // Player's bust: go directly to result phase
        #40 next = 1;           
        #20 next = 0;
        ///////////////////////////////////////////////////////////
        
        
        #40 reset = 1;
        #20 reset = 0;
        
        
        ///////////////////////////////////////////////////////////
        // Test case 2: Double case 
            // Player's first two cards are 10, 8       
            // Press double
        #40 double = 1;           
        #20 double = 0;
            // New card is 2
            // Press next: go to dealer score phase
        #40 next = 1;           
        #20 next = 0;
            // Press next: go to result phase
        #40 next = 1;           
        #20 next = 0;
        ///////////////////////////////////////////////////////////
        
        
        #40 reset = 1;
        #20 reset = 0;
        
        
        ///////////////////////////////////////////////////////////
        // Test case 3: Blackjack case 
            // Player's first two cards are 10, 11     
            // Press next: go to dealer score phase
        #40 next = 1;           
        #20 next = 0;
            // Press next: go to result phase
        #40 next = 1;           
        #20 next = 0;
        ///////////////////////////////////////////////////////////
        
        
        #40 reset = 1;
        #20 reset = 0;
        
        
        ///////////////////////////////////////////////////////////
        // Test case 4: Split case 
            // Player's first two cards are 10, 10     
            // Press split: go to split phase
        #40 split = 1;           
        #20 split = 0;
            // New card is 8
            // Press hit
        #40 hit = 1;           
        #20 hit = 0;
            // New card is 4
            // Hand1's bust: go to hand2 phase
        #40 next = 1;           
        #20 next = 0;
            // New card is 8
            // Press hit
        #40 hit = 1;           
        #20 hit = 0;
            // New card is 2
            // Hand2's stand: go to dealer phase
        #40 stand = 1;           
        #20 stand = 0;
            // Press next: go to result phase
        #40 next = 1;           
        #20 next = 0;
        ///////////////////////////////////////////////////////////
    end
    
endmodule
