// module blackjack( 
//     // Inputs
//     input reg clk;    
//     input reg reset;
//     input reg next;
//     input reg hit;
//     input reg stand;
//     input reg double;  
//     input reg split;
//     input reg bet_8;
//     input reg bet_4;
//     input reg bet_2;
//     input reg bet_1;

//     // Outputs
//     output wire [5:0] player_current_score, player_new_card;
//     output wire [5:0] player_current_score_split, player_new_card_split;
//     output wire [5:0] dealer_current_score;
//     output wire [4:0] current_coin;
//     output wire can_split;
//     output wire Win;
//     output wire Lose;
//     output wire Draw;
// );

//     reg hit_before;
//     reg hit_after = 1'b0;
//     reg hit_pulse;

//     reg stand_before;
//     reg stand_after = 1'b0;
//     reg stand_pulse;

//     reg double_before;
//     reg double_after = 1'b0;
//     reg double_pulse;

//     reg next_before;
//     reg next_after = 1'b0;
//     reg next_pulse;

//     reg on;
//     reg [2:0] test = 3'b000;
//     reg [3:0] card1;
//     reg [3:0] card2;
//     reg [3:0] card_value;

//     reg hit_reg;
//     reg next_reg;
//     reg rst_reg;
//     reg stand_reg;
//     reg double_reg;

//     // card generation - for test
//     card_generation u_card (
//         .clk(clk),
//         .reset(reset),
//         .on(on), 
//         .test(test),
//         .card1_out(card1),
//         .card2_out(card2)
//     );

//     debouncer db_next(next, clk, next_reg);
//     debouncer db_rst(reset, clk, rst_reg);
//     debouncer db_hit(hit, clk, hit_reg);
//     debouncer db_stand(stand, clk, stand_reg);
//     debouncer db_double(double, clk, double_reg);


//     //-----------------------------------------
//     //               FSM
//     //-----------------------------------------

//     parameter integer C_BIT_WIDTH = 2;

//     parameter [C_BIT_WIDTH-1:0] BETTING_PHASE = 2'b00,
//                 DEALER_CARD_PHASE   = 2'b01,
//                 PLAYER_CARD_PHASE   = 2'b10,
//                 RESULT_PHASE        = 2'b11;

//     reg [C_BIT_WIDTH-1:0] bj_game_state;
//     reg GAME_FIN;
//     integer k;

//     always @ (posedge clk) begin
//         if (reset == 1'b0) begin
//             bj_game_state      <= BETTING_PHASE;
//             on <= 1'b1;
//             k = 0;
//         end
//         else begin
//             case (bj_game_state)
//                 BETTING_PHASE:
//                     if (next_pulse) begin
//                         bj_game_state <= DEALER_CARD_PHASE;
//                     end
//                 PLAYER_CARD_PHASE:
//                     // initial two cards condition
//                     if (stand_pulse || player_current_score == 21 || dealer_current_score == 21 || player_current_score > 21) 
//                     begin
//                         bj_game_state <= DEALER_CARD_PHASE;
//                         k = k + 1;
//                     end
//                     // hit
//                     else if (hit_pulse) begin
//                         player_current_score = player_current_score + card_value;
//                     end
//                     // double
//                     else if (double_pulse) begin
//                         bet_amount = bet_amount + (bet_amount * 2);
//                         stand_pulse = 1'b1;
//                         bj_game_state <= DEALER_CARD_PHASE;
//                     end
//                     // stand
//                     else if (stand_pulse) begin
//                         bj_game_state <= DEALER_CARD_PHASE;
//                     end
//                     // bust
//                     else if (player_current_score + card_value > 21 && k > 0) begin
//                         bj_game_state <= RESULT_PHASE;
//                     end
//                 DEALER_CARD_PHASE:
//                     if (GAME_FIN) begin
//                         bj_game_state <= RESULT_PHASE;
//                     end
//                     // dealer stand
//                     else if (dealer_current_score > 17) begin
//                         bj_game_state <= PLAYER_CARD_PHASE;
//                     end
//                     else begin
//                         bj_game_state <= PLAYER_CARD_PHASE;
//                     end
//                 RESULT_PHASE:
//                     if ((player_current_score < dealer_current_score && dealer_current_score <= 21) 
//                         || player_current_score > 21) begin
//                             Win     = 1'b0;
//                             Lose    = 1'b1;
//                             Draw    = 1'b0;
//                     end
//                     else if ((player_current_score > dealer_current_score && player_current_score <= 21) 
//                         || dealer_current_score > 21) begin 
//                             Win     = 1'b1;
//                             Lose    = 1'b0;
//                             Draw    = 1'b0;
//                     end 
//                     else begin
//                         Win    = 1'b0;
//                         Lose    = 1'b0;
//                         Draw    = 1'b1;
//                     end 
//             endcase
//         end
//     end

//     //-----------------------------------------
//     //               Coin
//     //-----------------------------------------

//     reg bet_amount;

//     always @(posedge clk) begin
//         if (reset == 1'b0) begin
//             bet_amount <= 0;
//         end
//         else begin
//             bet_amount <= bet_8*8 + bet_4*4 + bet_2*2 + bet_1*1;
//         end
//     end

//     //-----------------------------------------
//     //               Pulse
//     //-----------------------------------------

//     always @ (posedge clk) begin
//         `   // Create reset pulse
//             reset_before <= reset_reg;
//             reset_after <= reset_before;
//             if (reset_before != reset_after && reset_before) begin
//                 reset_pulse <= 1'b1;
//             end
//             else begin
//                 reset_pulse <= 1'b0;
//             end

//             // Create hit pulse
//             hit_before <= hit_reg;
//             hit_after <= hit_before;
//             if (hit_before != hit_after && hit_before) begin
//                 hit_pulse <= 1'b1;
//             end
//             else begin
//                 hit_pulse <= 1'b0;
//             end

//             // Create Stand pulse
//             stand_before <= stand_reg;
//             stand_after <= stand_before;
//             if (stand_before != stand_after && stand_before) begin
//                 stand_pulse <= 1'b1;
//             end
//             else begin
//                 stand_pulse <= 1'b0;
//             end

//             // Create Double pulse
//             double_before <= double_reg;
//             double_after <= double_before;
//             if (double_before != double_after && double_before) begin
//                 double_pulse <= 1'b1;
//             end
//             else begin
//                 double_pulse <= 1'b0;
//             end

//             // Create next pulse
//             next_before <= next_reg;
//             next_after <= next_before;
//             if (next_before != next_after && next_before) begin
//                 next_pulse <= 1'b1;
//             end
//             else begin
//                 next_pulse <= 1'b0;
//             end
//     end

//     //-----------------------------------------
//     //               Score
//     //-----------------------------------------

//     always @(posedge clk) begin
//         card_value = card1 + card2;
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

    integer player_score;
    integer dealer_score;

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


