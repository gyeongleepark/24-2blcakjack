// module blackjack(
//     // Inputs
//     input clk,    
//     input reset,
//     input next,
//     input hit,
//     input stand,
//     input double,  
//     input split,
//     input bet_8,
//     input bet_4,
//     input bet_2,
//     input bet_1,

//     // Outputs
//     output [5:0] player_current_score, 
//     output [5:0] player_new_card,
//     output [5:0] player_current_score_split, 
//     output [5:0] player_new_card_split,
//     output [5:0] dealer_current_score,
//     output [4:0] current_coin,
//     output can_split,
//     output Win,
//     output Lose,
//     output Draw
// );

//     // Internal signals
//     wire [3:0] card1, card2;

//     reg [5:0] player_hand [1:4];
//     reg [5:0] dealer_hand [1:4];

//     reg [3:0] split_card1, split_card2;
//     reg split_active;
//     reg [5:0] bet_amount;
//     reg [4:0] initial_coin = 5'd30;
 
//     reg [5:0] player_new_card_reg;
//     reg [5:0] player_current_score_split_reg; 
//     reg [5:0] player_new_card_split_reg;
//     reg [4:0] current_coin_reg;

//     reg win_reg;
//     reg lose_reg;
//     reg draw_reg;

//     reg split_pulse;
//     reg first_turn;

//     reg blackjack_win;

//     reg player_score;
//     reg dealer_score;

//     // Card generation instance
//     card_generation u_card (
//         .clk(clk),
//         .reset(reset),
//         .on(1'b1),
//         .test(3'b011),
//         .card1_out(card1),
//         .card2_out(card2)
//     );

//     //-----------------------------------------
//     //               FSM
//     //-----------------------------------------

//     parameter [1:0] BETTING_PHASE = 2'b00, 
//                     DEALER_CARD_PHASE = 2'b01,
//                     PLAYER_CARD_PHASE = 2'b10, 
//                     RESULT_PHASE = 2'b11;
//     reg [1:0] bj_game_state;

//     integer i, j;

//     always @(posedge clk) begin
//         if (reset) begin
//             bj_game_state <= BETTING_PHASE;
//             player_score = 0;
//             dealer_score = 0;
//             current_coin_reg = 0;
//             player_current_score_split_reg <= 0;
//             player_new_card_reg <= 0;
//             player_new_card_split_reg <= 0;
//             win_reg <= 0;
//             lose_reg <= 0;
//             draw_reg <= 0;
//             split_pulse <= 0;
//             split_active <= 0;
//             first_turn <= 1;
//             blackjack_win <= 0;
//             i = 2;
//             j = 2;
//         end else begin
//             case (bj_game_state)
//                 BETTING_PHASE: begin
//                     // initialize signals for a new game 
//                     player_score = 0;
//                     dealer_score = 0;
//                     current_coin_reg = 0;
//                     player_current_score_split_reg <= 0;
//                     player_new_card_reg <= 0;
//                     player_new_card_split_reg <= 0;
//                     win_reg <= 0;
//                     lose_reg <= 0;
//                     draw_reg <= 0;
//                     split_pulse <= 0;
//                     split_active <= 0;
//                     blackjack_win <= 0;

//                     player_hand[1] = card1;
//                     player_hand[2] = card2;
//                     // Initial two cards of the player
//                     player_score <= player_hand[1] + player_hand[2];

//                     // Check the split
//                     if (card1 == card2) begin
//                         split_active <= 1'b1;
//                     end
//                     // Check the aces
//                     if (player_hand[1] == 6'd1 && !split_active) begin
//                         player_score = player_score + 10;
//                     end 
//                     else if (card2 == 6'd1 && !split_active) begin
//                         player_score = player_score + 10;
//                     end
//                     $display("initial player score: %d, %d, %d", player_hand[1], player_hand[2], player_score);

//                     // Turn to dealer state when next is pressed
//                     if (bet_amount > 0 & next) begin
//                         bj_game_state <= DEALER_CARD_PHASE;
//                     end
//                 end

//                 PLAYER_CARD_PHASE: begin
//                     if (player_score >= 21) begin
//                         bj_game_state <= RESULT_PHASE;
//                     end 
//                     else begin
//                         if (!stand && dealer_score < 17) begin
//                             if (split && split_pulse) begin
//                                 split_card1 <= card1;
//                                 split_card2 <= card2;
//                                 player_score <= card1;
//                                 player_current_score_split_reg <= card2;
//                                 split_active <= 1'b1;
//                                 split_pulse <= 1'b0;
//                             end 
//                             else if (hit) begin
//                                 if (!split_active) begin
//                                     player_new_card_reg <= card1;
//                                     player_hand[i+1] <= player_new_card_reg; 
//                                     // check if there's ace in the deck and the sum is over 21
//                                     if (player_score + player_new_card_reg > 21) begin
//                                         if (player_hand[1] == 4'd11) begin
//                                             player_hand[1] <= 4'd1;
//                                         end
//                                         else if (player_hand[2] == 4'd11) begin
//                                             player_hand[2] <= 4'd1;
//                                         end
//                                         player_score <= player_hand[1] + player_hand[2] + player_new_card_reg;
//                                         i = i + 1;
//                                     end else begin
//                                         player_score <= player_score + player_new_card_reg;
//                                     end
//                                     bj_game_state <= PLAYER_CARD_PHASE;
//                                 end else begin
//                                     player_new_card_split_reg <= card2;
//                                     player_current_score_split_reg <= player_current_score_split_reg + card2;
//                                 end
//                             end 
//                             else if (double) begin
//                                 player_new_card_reg <= card1;
//                                 player_score <= player_score + player_new_card_reg;
//                                 bj_game_state <= DEALER_CARD_PHASE;
//                             end
//                         end else if (stand && dealer_score >= 17) begin
//                             bj_game_state <= RESULT_PHASE;
//                         end else begin
//                             bj_game_state <= DEALER_CARD_PHASE;
//                         end
//                     end
//                 end

//                 DEALER_CARD_PHASE: begin
//                     if (first_turn) begin
//                         // reveal one of the cards
//                         // dealer_hand[1] <= card1;
//                         // dealer_hand[2] <= card2;
//                         // dealer_score <= dealer_hand[1] + dealer_hand[2];
//                         // $display("initial dealer score: %d, %d, %d", dealer_hand[1], dealer_hand[2], dealer_score);
//                         if (next) begin
//                             if (dealer_score == 21) begin
//                                 bj_game_state <= RESULT_PHASE;
//                                 first_turn = 1'b0;
//                             end else begin
//                                 bj_game_state <= PLAYER_CARD_PHASE;
//                                 first_turn = 1'b0;
//                             end
//                         end
//                     end 
//                     else if (!first_turn && dealer_score < 17) begin
//                         // dealer_hand[j+1] <= card1; 
//                         // dealer_score <= dealer_score + dealer_hand[j+1];
//                         bj_game_state <= PLAYER_CARD_PHASE;
//                     end
//                     else begin
//                         bj_game_state <= RESULT_PHASE;
//                     end
//                 end

//                 RESULT_PHASE: begin
//                     if ((player_score < dealer_score && dealer_score <= 21) 
//                         || player_score > 21) begin
//                         win_reg  <= 1'b0;
//                         lose_reg <= 1'b1;
//                         draw_reg <= 1'b0;
//                         $display("you lose");
//                     end 
//                     else if ((player_score > dealer_score && player_score <= 21) 
//                         || dealer_score > 21) begin
//                         if (player_score == 21) begin
//                             blackjack_win <= 1'b1;
//                         end
//                         win_reg  <= 1'b1;
//                         lose_reg <= 1'b0;
//                         draw_reg <= 1'b0;
//                         $display("you won!");
//                     end 
//                     else begin
//                         win_reg  <= 1'b0;
//                         lose_reg <= 1'b0;
//                         draw_reg <= 1'b1;
//                         $display("draw");
//                     end
//                     split_active <= 0;
//                     if (next) begin
//                         bj_game_state <= BETTING_PHASE;
//                         first_turn <= 1;
//                     end
//                 end
//             endcase
//         end
//     end

//     assign player_current_score = player_score;
//     assign dealer_current_score = dealer_score;
//     assign player_current_score_split = player_current_score_split_reg;
//     assign player_new_card = player_new_card_reg;
//     assign player_new_card_split = player_new_card_split_reg;
//     assign current_coin = current_coin_reg;
//     assign can_split = split_pulse;

//     assign Win = win_reg;
//     assign Lose = lose_reg;
//     assign Draw = draw_reg;

//     //-----------------------------------------
//     //             Coin Calculation
//     //-----------------------------------------
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             current_coin_reg <= initial_coin;
//         end else begin
//             if (bj_game_state == BETTING_PHASE) begin
//                 // how can I turn this into shift operation
//                 bet_amount <= (bet_8 * 8) + (bet_4 * 4) + (bet_2 * 2) + (bet_1 * 1);
//             end
//             current_coin_reg <= current_coin_reg - bet_amount;

//             if (win_reg) begin
//                 if (blackjack_win) begin
//                     current_coin_reg <= current_coin_reg + 4 * bet_amount;
//                     blackjack_win <= 1'b0;
//                 end else begin
//                     current_coin_reg <= current_coin_reg + 2 * bet_amount; 
//                 end
//             end else if (lose_reg) begin
//                 current_coin_reg <= current_coin_reg;
//             end else if (draw_reg) begin
//                 current_coin_reg <= current_coin_reg + bet_amount;
//             end
//         end
//     end
// endmodule

module blackjack(
    // Inputs
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

    // Outputs
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

    // Internal signals
    wire [3:0] card1, card2, card_value;

    reg [5:0] player_hand [1:4];
    reg [5:0] dealer_hand [1:4];

    reg [3:0] split_card1, split_card2;
    reg split_active;
    reg [5:0] bet_amount;
    reg [4:0] initial_coin = 5'd30;
 
    reg [5:0] player_new_card_reg;
    reg [5:0] player_current_score_split_reg; 
    reg [5:0] player_new_card_split_reg;
    reg [4:0] current_coin_reg;

    reg win_reg;
    reg lose_reg;
    reg draw_reg;

    reg split_pulse;
    reg first_turn;

    reg blackjack_win;

    reg [5:0] player_score;
    reg [5:0] dealer_score;
    // player_score가 int라서 이전 state를 불러올 수 없는듯

    // Card generation instance
    card_generation u_card (
        .clk(clk),
        .reset(reset),
        .on(1'b1),
        .test(3'b001),
        .card1_out(card1),
        .card2_out(card2)
    );

    //-----------------------------------------
    //               FSM
    //-----------------------------------------

    parameter [1:0] BETTING_PHASE = 2'b00, 
                    DEALER_CARD_PHASE = 2'b01,
                    PLAYER_CARD_PHASE = 2'b10, 
                    RESULT_PHASE = 2'b11;
    reg [1:0] bj_game_state;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            bj_game_state <= BETTING_PHASE;
            player_score = 0;
            dealer_score = 0;
            current_coin_reg = 0;
            player_current_score_split_reg <= 0;
            player_new_card_reg <= 0;
            player_new_card_split_reg <= 0;
            win_reg <= 0;
            lose_reg <= 0;
            draw_reg <= 0;
            split_pulse <= 0;
            split_active <= 0;
            first_turn <= 1;
            blackjack_win <= 0;
        end else begin
            case (bj_game_state)
                BETTING_PHASE: begin
                    current_coin_reg <= initial_coin;
                    player_hand[1] <= card1;
                    player_hand[2] <= card2;
                    player_score <= player_hand[1] + player_hand[2];
                    if (player_hand[1] == 6'd1) begin
                        player_score <= player_hand[1] + player_hand[2] + 10;
                    end else if (player_hand[2] == 6'd1) begin
                        player_score <= player_hand[1] + player_hand[2] + 10;
                    end

                    if (bet_amount > 0 & next) begin
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                end

                PLAYER_CARD_PHASE: begin
                    if (player_score >= 21) begin
                        bj_game_state <= RESULT_PHASE;
                    end 
                    else begin
                        if (!stand && dealer_score < 17) begin
                            if (split && split_pulse) begin
                                split_card1 <= card1;
                                split_card2 <= card2;
                                player_score <= card1;
                                player_current_score_split_reg <= card2;
                                split_active <= 1'b1;
                                split_pulse <= 1'b0;
                            end 
                            else if (hit) begin
                                if (!split_active) begin
                                    player_new_card_reg <= card1;
                                    player_score <= player_score + player_new_card_reg;
                                    bj_game_state <= PLAYER_CARD_PHASE;
                                end else begin
                                    player_new_card_split_reg <= card2;
                                    player_current_score_split_reg <= player_current_score_split_reg + card2;
                                end
                            end 
                            else if (double) begin
                                player_new_card_reg <= card1;
                                player_score <= player_score + player_new_card_reg;
                                bj_game_state <= DEALER_CARD_PHASE;
                            end
                        end else if (stand && dealer_score >= 17) begin
                            bj_game_state <= RESULT_PHASE;
                        end else begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                    end
                end

                DEALER_CARD_PHASE: begin
                    if (first_turn) begin
                        // reveal one of the cards
                        if (next) begin
                            bj_game_state <= PLAYER_CARD_PHASE;
                            first_turn = 1'b0;
                        end
                    end 
                    else if (!first_turn && dealer_score < 17) begin
                        dealer_score <= dealer_score + card1;
                        bj_game_state <= PLAYER_CARD_PHASE;
                    end
                    else begin
                        bj_game_state <= RESULT_PHASE;
                    end
                end

                RESULT_PHASE: begin
                    if ((player_score < dealer_score && dealer_score <= 21) 
                        || player_score > 21) begin
                        win_reg  <= 1'b0;
                        lose_reg <= 1'b1;
                        draw_reg <= 1'b0;
                    end 
                    else if ((player_score > dealer_score && player_score <= 21) 
                        || dealer_score > 21) begin
                        if (player_score == 21) begin
                            blackjack_win <= 1'b1;
                        end
                        win_reg  <= 1'b1;
                        lose_reg <= 1'b0;
                        draw_reg <= 1'b0;
                    end 
                    else begin
                        win_reg  <= 1'b0;
                        lose_reg <= 1'b0;
                        draw_reg <= 1'b1;
                    end
                    split_active <= 0;
                    if (next) begin
                        bj_game_state <= BETTING_PHASE;
                        first_turn <= 1;
                    end
                end
            endcase
        end
    end

    assign player_current_score = player_score;
    assign dealer_current_score = dealer_score;
    assign player_current_score_split = player_current_score_split_reg;
    assign player_new_card = player_new_card_reg;
    assign player_new_card_split = player_new_card_split_reg;
    assign current_coin = current_coin_reg;
    assign can_split = split_pulse;

    assign Win = win_reg;
    assign Lose = lose_reg;
    assign Draw = draw_reg;

    //-----------------------------------------
    //               Coin Calculation
    //-----------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_coin_reg <= initial_coin;
        end else begin
            if (bj_game_state == BETTING_PHASE) begin
                bet_amount <= (bet_8 * 8) + (bet_4 * 4) + (bet_2 * 2) + (bet_1 * 1);
                current_coin_reg <= current_coin_reg - bet_amount;
            end

            if (win_reg) begin
                if (blackjack_win) begin
                    current_coin_reg <= current_coin_reg + 4 * bet_amount;
                    blackjack_win <= 1'b0;
                end else begin
                    current_coin_reg <= current_coin_reg + 2 * bet_amount; 
                end
            end else if (lose_reg) begin
                current_coin_reg <= current_coin_reg;
            end else if (draw_reg) begin
                current_coin_reg <= current_coin_reg + bet_amount;
            end
        end
    end
endmodule

