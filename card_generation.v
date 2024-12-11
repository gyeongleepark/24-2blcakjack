`timescale 1ns / 1ps

module card_generation(
/*
    < Module Description: card_generation >
    This module generates one or two cards in various scenarios.
    You can test four cases using the testbench provided with this module. 
    This code is provided to assist with project implementation, and using this module is up to you..
    - Inputs
        on: control signal to enable card generation. 
        test: 3-bit input defining the test scenario or mode. 
            BASE: if test == BASE, this module generates cards randomly.
            TEST_SIMPLE (testing simple case): if test == T_SIMPLE, this module generates 10, 8 for the first "on", and generates 4 for the second "on".
            TEST_DOUBLE (testing double case): if test == T_DOUBLE, this module generates 10, 8 for the first "on", and generates 2 for the second "on".
            TEST_BLACKJACK (testing blackjack case): if test == T_BLACKJACK, this module generates 10, 11 for the first "on".
            TEST_SPLIT (testing split case): if test == T_SPLIT, this module generates 10, 10 for the first "on", and generates 8 for the second "on", 4 for the third "on", 8 for the fourth, and 2 for the fifth "on".
    - Outputs
        card1_out, card2_out: 4-bit output representing the value of the first card. If the value exceeds 10, it is clamped to 10. 
                              The output range is from 1 to 10, so map A to 1.      
*/
        input clk,
        input reset,
        input on, 
        input [2:0] test,
        output [3:0] card1_out,
        output [3:0] card2_out
    );
    
    reg [3:0] card1, card2;
    
    reg [47:0] rand1;
    reg [47:0] rand2;
    
    localparam BASE = 3'b000,
               TEST_SIMPLE = 3'b001, 
               TEST_DOUBLE = 3'b010, 
               TEST_BLACKJACK = 3'b011, 
               TEST_SPLIT = 3'b100; 
               
    // These variables are used to count the number of times on is enabled for each test.
    reg [3:0] counter_simple,
              counter_double,
              counter_blackjack,
              counter_split;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            card1 <= 0;
            card2 <= 0;
            counter_simple <= 0;
            counter_double <= 0;
            counter_blackjack <= 0;
            counter_split <= 0;
            /* 
               This module outputs the LSB 4 bits of the rand1 and rand2 variables as card numbers. 
               Each time a number is output, the rand variables are shifted to the right by one bit. 
               These numbers can be freely modified for testing and verification purposes.
            */
            rand1 <= 48'b11100101_10011101_11110000_00110000_00111011_00101101;
            rand2 <= 48'b11110000_00110000_00111111_01101101_11100101_10011101;
        end
        else begin
            case (test) 
                BASE: 
                        begin
                            if (on) begin
                                card1 <= rand1[3:0];
                                card2 <= rand2[3:0];
                                rand1 <= rand1 >> 1;
                                rand2 <= rand2 >> 1;
                            end
                        end
                TEST_SIMPLE: 
                        begin
                            case (counter_simple)
                                4'b0000: if (on) begin card1 <= 4'd10; card2 <= 4'd8; counter_simple <= counter_simple + 4'd1; end
                                4'b0001: if (on) begin card1 <= 4'd4; card2 <= 4'd0; counter_simple <= 4'd0; end
                                default: begin card1 <= 4'd0; card2 <= 4'd0; end
                            endcase
                        end
                TEST_DOUBLE: 
                        begin
                            case (counter_double)
                                4'b0000: if (on) begin card1 <= 4'd10; card2 <= 4'd8; counter_double <= counter_double + 4'd1; end
                                4'b0001: if (on) begin card1 <= 4'd2; card2 <= 4'd0; counter_double <= 4'd0; end
                                default: begin card1 <= 4'd0; card2 <= 4'd0; end
                            endcase
                        end
                TEST_BLACKJACK: 
                        begin
                            case (counter_blackjack)
                                4'b0000: if (on) begin card1 <= 4'd10; card2 <= 4'd1; counter_blackjack <= counter_blackjack + 4'd1; end
                                4'b0001: if (on) begin card1 <= 4'd0; card2 <= 4'd0; counter_blackjack <= 4'd0; end
                                default: begin card1 <= 4'd0; card2 <= 4'd0; end
                            endcase
                        end
                TEST_SPLIT: 
                        begin
                            case (counter_split)
                                4'b0000: if (on) begin card1 <= 4'd10; card2 <= 4'd10; counter_split <= counter_split + 4'd1; end
                                4'b0001: if (on) begin card1 <= 4'd8; card2 <= 4'd0; counter_split <= counter_split + 4'd1; end
                                4'b0010: if (on) begin card1 <= 4'd4; card2 <= 4'd0; counter_split <= counter_split + 4'd1; end
                                4'b0011: if (on) begin card1 <= 4'd8; card2 <= 4'd0; counter_split <= counter_split + 4'd1; end
                                4'b0100: if (on) begin card1 <= 4'd2; card2 <= 4'd0; counter_split <= 4'd0; end
                                default: begin card1 <= 4'd0; card2 <= 4'd0; end
                            endcase
                        end
                default: begin
                                card1 <= 0;
                                card2 <= 0;
                          end
            endcase
        end
    end
    
    // The output range is set from 0 to 10, where 0 indicates no card was generated. Ace (A) is mapped to 1.
    assign card1_out = (card1 > 4'd10) ? 4'd10 : card1;
    assign card2_out = (card2 > 4'd10) ? 4'd10 : card2;
    
endmodule
