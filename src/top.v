// Inputs
input reg clk;    
input reg reset;
input reg next;
input reg hit;
input reg stand;
input reg double;  
input reg split;
input reg bet_8;
input reg bet_4;
input reg bet_2;
input reg bet_1;

// Outputs
output wire [5:0] player_current_score, player_new_card;
output wire [5:0] player_current_score_split, player_new_card_split;
output wire [5:0] dealer_current_score;
output wire [4:0] current_coin;
output wire can_split;
output wire Win;
output wire Lose;
output wire Draw;