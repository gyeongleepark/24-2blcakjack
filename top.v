module top(
    input wire clk,    
    input wire reset,
    input wire next,
    input wire hit,
    input wire stand,
    input wire double,  
    input wire split,
    input wire bet_8,
    input wire bet_4,
    input wire bet_2,
    input wire bet_1,

    output wire [5:0] player_current_score, 
    output wire [5:0] player_new_card,
    output wire [5:0] player_current_score_split, 
    output wire [5:0] player_new_card_split,
    output wire [5:0] dealer_current_score,
    output wire [4:0] current_coin,
    output wire can_split,
    output wire Win,
    output wire Lose,
    output wire Draw
);

    blackjack dut(
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

endmodule
