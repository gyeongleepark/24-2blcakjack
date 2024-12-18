module top(
    input clk,    
    input reset,
    input next,
    input hit,
    input stand,
    input double,  
    input split,
    input bet_8,
    input bet_4,
    input bet_2,
    input bet_1,

    output [5:0] player_current_score, 
    output [5:0] player_new_card,
    output [5:0] player_current_score_split, 
    output [5:0] player_new_card_split,
    output [5:0] dealer_current_score,
    output [4:0] current_coin,
    output can_split,
    output Win,
    output Lose,
    output Draw
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