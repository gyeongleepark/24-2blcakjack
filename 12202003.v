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

    // output regs
    reg [5:0] player_new_card_reg;
    reg [5:0] dealer_new_card_reg;
    reg [5:0] player_new_card_split_reg;
    reg [4:0] current_coin_reg;

    reg win_reg;
    reg lose_reg;
    reg draw_reg;
    reg 1_win_reg;
    reg 1_lose_reg;
    reg 1_draw_reg;
    reg 2_win_reg;
    reg 2_lose_reg;
    reg 2_draw_reg;

    reg 1_double;
    reg 2_double;

    // card generation instance
    wire [3:0] card1, card2;
    // hands
    reg [5:0] player_hand [1:4];
    reg [5:0] dealer_hand [1:4];
    reg [5:0] split1_hand [1:4];
    reg [5:0] split2_hand [1:4];

    integer split1_count;
    integer split2_count;

    reg [1:0] hand_count;
    integer player_card_count, dealer_card_count, split_card_count;

    // reg [3:0] split_card1, split_card2;
    // coin calculation
    reg [5:0] bet_amount;
    reg [4:0] initial_coin = 5'd30;

    reg split_able;       // condition check card1 = card2
    reg split_active;    // if split done raise 1
    reg split_complete;  // split complete
    reg first_turn;

    reg blackjack_win;

    reg [5:0] player_score;
    reg [5:0] dealer_score;
    reg [5:0] split_score;
    reg [5:0] split1_score;
    reg [5:0] split2_score;

    // card pulse
    wire newcard_pulse;
    reg newcard_ff, newcard_ff2;
    reg trigger_newcard;


    function [7:0] calculate_score_with_ace;
        input [5:0] card1, card2, card3, card4;
        input integer card_count;   // current number of cards

        integer i;                // loop index
        reg [7:0] score;
        reg [3:0] ace_count;      
        reg [5:0] cards [1:4];                 

        begin
            score = 0;
            ace_count = 0;

            // initialize cards
            cards[1] = card1;
            cards[2] = card2;
            cards[3] = card3;
            cards[4] = card4;

            for (i = 1; i <= card_count; i = i + 1) begin
                if (cards[i] == 6'd1) begin
                    ace_count = ace_count + 1;
                end
                score = score + cards[i]; // sum of the cards
            end

            if (ace_count > 0) begin
                // if busts, calculate A as 1
                if ((score + 10) <= 21) begin
                    score = score + 10;
                    ace_count = ace_count - 1;
                end

                // rest of the A are all 1
                score = score + ace_count;
            end
            calculate_score_with_ace = score;
        end
    endfunction    

    // Card generation instance
    card_generation u_card (
        .clk(clk),
        .reset(reset),
        .on(newcard_pulse),
        .test(3'b100),
        .card1_out(card1),
        .card2_out(card2)
    );

    //-----------------------------------------
    //       Card generation pulse
    //-----------------------------------------
    assign newcard_pulse = !newcard_ff2 && trigger_newcard;

    always @(posedge clk) begin
        if (reset) begin
            newcard_ff <= 1'b0;
            newcard_ff2 <= 1'b0;
        end else begin
            // Update flip-flops for pulse generation
            if (newcard_pulse) begin
                trigger_newcard <= 0;  // Turn off trigger
            end
            newcard_ff <= trigger_newcard;
            newcard_ff2 <= newcard_ff;
        end
    end


    //-----------------------------------------
    //               FSM
    //-----------------------------------------

    parameter [2:0] BETTING_PHASE = 3'b000,
                    DEALER_CARD_PHASE = 3'b001,
                    PLAYER_CARD_PHASE = 3'b010,
                    RESULT_PHASE = 3'b011,
                    SPLIT1_PHASE=3'b100, 
                    SPLIT2_PHASE=3'b101;
    reg [2:0] bj_game_state;

    always @(posedge clk) begin
        if (reset) begin
            bj_game_state <= BETTING_PHASE;
            player_score <= 0;
            dealer_score <= 0;
            split_score <= 0;
            split1_score <= 0;
            split2_score <= 0;
            player_card_count <= 0;
            dealer_card_count <= 0;
            split_card_count <= 0;
            hand_count <= 1;
            current_coin_reg = 0;
            player_new_card_reg <= 0;
            player_new_card_split_reg <= 0;
            win_reg <= 0;
            lose_reg <= 0;
            draw_reg <= 0;
            split_active <= 1;
            split_complete <= 0;
            split_able <= 0;
            first_turn <= 1;
            blackjack_win <= 0;
            trigger_newcard <= 0;
            split1_count <= 2;
            split2_count <= 2;
        end else begin
            case (bj_game_state)
                BETTING_PHASE: begin
                    current_coin_reg <= initial_coin;
                    // hand over two cards to the player
                    if (!newcard_pulse) begin
                        trigger_newcard <= 1;
                        player_hand[1] <= card1;
                        player_hand[2] <= card2;
                        player_hand[3] <= 0;
                        player_hand[4] <= 0;
                    end else begin
                        trigger_newcard <= 0;  // Deassert after one pulse
                        if((card1 != 0) && (card2 != 0) && (card1 == card2)) begin
                            split_able <= 1'b1;
                        end
                        player_score <= calculate_score_with_ace(player_hand[1], player_hand[2], player_hand[3], player_hand[4], 2);   // 이거 함수로 바꿈
                    end
                    // move on to dealer phase
                    if (bet_amount > 0 && next) begin
                        player_card_count <= 3; // initialize to 3 so that we won't caculate in the index
                        split_card_count <= 2;
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                end
                PLAYER_CARD_PHASE: begin
                    // player bust
                    if (player_score >= 21 || dealer_score == 21) begin
                        bj_game_state <= RESULT_PHASE;
                    end 
                    else begin
                        if (!stand) begin
                            if (split_able && split && split_active) begin
                                hand_count <= 2;
                                // initialize split1_hand 
                                split1_hand[1] <= player_hand[1];
                                split1_hand[2] <= 0;
                                split1_hand[3] <= 0;
                                split1_hand[4] <= 0;
                                // initialize split2_hand
                                split2_hand[1] <= player_hand[2];
                                split2_hand[2] <= 0;
                                split2_hand[3] <= 0;
                                split2_hand[4] <= 0;
                                // calcualte split score
                                split1_score <= player_hand[1];
                                split2_score <= player_hand[2];
                                // you cannot split more, split is completed
                                split_active <= 0;
                                split_complete <= 1;
                                // move on to split1 phase
                                bj_game_state <= SPLIT1_PHASE;
                            end 
                            else if (hit && !split_complete) begin
                                if (!newcard_pulse) begin
                                    trigger_newcard <= 1;
                                    player_new_card_reg <= card1;
                                    player_hand[player_card_count] <= card1;
                                end else begin
                                    trigger_newcard <= 0;  // Deassert after one pulse
                                    // $display("player_score before: %d", player_score);
                                    player_score <= calculate_score_with_ace(player_hand[1], player_hand[2], player_hand[3], player_hand[4], player_card_count);
                                    // $display("player_score after: %d", player_score);
                                    player_card_count <= player_card_count + 1;
                                end
                                bj_game_state <= PLAYER_CARD_PHASE;
                            end 
                            else if (double && !split_complete) begin
                                if (!newcard_pulse) begin
                                    trigger_newcard <= 1;
                                    player_new_card_reg <= card1;
                                    player_hand[player_card_count] <= player_new_card_reg;
                                end else begin
                                    trigger_newcard <= 0;  // Deassert after one pulse
                                    // $display("player_score before: %d", player_score);
                                    player_score <= calculate_score_with_ace(player_hand[1], player_hand[2], player_hand[3], player_hand[4], player_card_count);
                                    // $display("player_score after: %d", player_score);
                                    player_card_count <= player_card_count + 1;
                                end
                                bj_game_state <= DEALER_CARD_PHASE;
                            end
                            else if (stand && !split_complete) begin
                                if (dealer_score >= 17) begin
                                    bj_game_state <= RESULT_PHASE;
                                end else begin
                                    bj_game_state <= DEALER_CARD_PHASE;
                                end
                            end
                        end 
                        else if (stand && dealer_score >= 17) begin
                            bj_game_state <= RESULT_PHASE;
                        end 
                        else begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                    end
                end

                DEALER_CARD_PHASE: begin
                    if (first_turn) begin
                        // hand over two cards to the dealer
                        if (!newcard_pulse) begin
                            trigger_newcard <= 1;
                            dealer_hand[1] <= card1;
                            dealer_hand[2] <= card2;
                            dealer_hand[3] <= 0;
                            dealer_hand[4] <= 0;
                        end else begin
                            trigger_newcard <= 0;  // Deassert after one pulse
                            // $display("dealer_score before: %d", dealer_score);
                            dealer_score <= calculate_score_with_ace(dealer_hand[1], dealer_hand[2], dealer_hand[3], dealer_hand[4], 2);
                            // $display("dealer_score after: %d", dealer_score);
                        end
                        // reveal one of the cards
                        if (next) begin
                            if (dealer_score >= 21) begin
                                bj_game_state <= RESULT_PHASE;
                            end else begin
                                bj_game_state <= PLAYER_CARD_PHASE;
                            end
                            first_turn = 1'b0;
                        end
                    end
                    // after player stands
                    else if (!first_turn && dealer_score < 17) begin
                        if (!newcard_pulse) begin
                            trigger_newcard <= 1;
                            dealer_new_card_reg <= card1;
                            dealer_hand[dealer_card_count] <= card1;
                        end else begin
                            trigger_newcard <= 0;
                            dealer_card_count <= dealer_card_count + 1;
                            dealer_score <= calculate_score_with_ace(dealer_hand[1], dealer_hand[2], dealer_hand[3], dealer_hand[4], dealer_card_count);
                        end
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                    else begin
                        bj_game_state <= RESULT_PHASE;
                    end
                end

                SPLIT1_PHASE: begin
                    if (split1_score > 21) begin
                        if (next) begin
                            bj_game_state <= SPLIT2_PHASE;
                        end
                    end
                    else begin
                        // initialize split1_hand with two cards
                        if (split1_hand[1] != 0 && split1_hand[2] == 0) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split1_hand[split1_count] <= card1;
                                split1_count <= split1_count + 1;
                            end else begin
                                trigger_newcard <= 0;
                                split1_score <= calculate_score_with_ace(split1_hand[1], split1_hand[2], split1_hand[3], split1_hand[4], 2);
                            end
                        end
                        // hit
                        else if (hit && split_complete) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split1_hand[split1_count] <= card1;
                                player_new_card_split_reg <= card1;
                                split1_count <= split1_count + 1;
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                // $display("player_score before: %d", player_score);
                                split1_score <= calculate_score_with_ace(split1_hand[1], split1_hand[2], split1_hand[3], split1_hand[4], split1_count);
                                // $display("player_score after: %d", player_score);
                            end
                            bj_game_state <= SPLIT1_PHASE;
                        end
                        else if (double && split_complete) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split1_hand[split1_count] <= card1;
                                player_new_card_split_reg <= card1;
                                split1_count <= split1_count + 1;
                                1_double <= 1;      // 1_double
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                // $display("player_score before: %d", player_score);
                                split1_score <= calculate_score_with_ace(split1_hand[1], split1_hand[2], split1_hand[3], split1_hand[4], split1_count);
                                // $display("player_score after: %d", player_score);
                            end
                            if (next) begin
                                bj_game_state <= SPLIT2_PHASE;
                            end
                        end
                        else if (stand && split_complete) begin
                            if (next) begin
                                bj_game_state <= SPLIT2_PHASE;
                            end
                        end
                        else if (next) begin
                            bj_game_state <= SPLIT2_PHASE;
                        end
                    end 
                end 
                SPLIT2_PHASE: begin
                    if (split2_score >= 21) begin
                        if (next) begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                    end   
                    else begin
                        // initialize split1_hand with two cards
                        if (split2_hand[1] != 0 & split2_hand[2] == 0) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split2_hand[split2_count] <= card1;
                                split2_count <= split2_count + 1;
                            end else begin
                                trigger_newcard <= 0;
                                split2_score <= calculate_score_with_ace(split2_hand[1], split2_hand[2], split2_hand[3], split2_hand[4], 2);
                            end
                        end
                        else if (hit && split_complete) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split2_hand[split2_count] <= card1;
                                player_new_card_split_reg <= card1;
                                split2_count <= split2_count + 1;
                            end else begin
                                trigger_newcard <= 0; 
                                split2_score <= calculate_score_with_ace(split2_hand[1], split2_hand[2], split2_hand[3], split2_hand[4], split2_count);
                            end
                            bj_game_state <= SPLIT2_PHASE;
                        end
                        else if (double && split_complete) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split2_hand[split2_count] <= card1;
                                player_new_card_split_reg <= card1;
                                split2_count <= split2_count + 1;
                                2_double <= 1;      // 2_double
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                split2_score <= calculate_score_with_ace(split2_hand[1], split2_hand[2], split2_hand[3], split2_hand[4], split2_count);
                            end
                            if (next) begin
                                bj_game_state <= DEALER_CARD_PHASE;
                            end
                        end
                        else if (stand && split_complete) begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                        // else if (next) begin
                            // bj_game_state <= DEALER_CARD_PHASE;
                        // end
                    end  
                end 
                RESULT_PHASE: begin
                    if (!split_complete) begin
                        // player result
                        if ((player_score < dealer_score && dealer_score <= 21) 
                            || player_score > 21) begin
                            win_reg  <= 1'b0;
                            lose_reg <= 1'b1;
                            draw_reg <= 1'b0;
                            $display("you lose");
                        end 
                        else if ((player_score > dealer_score && player_score <= 21) 
                            || dealer_score > 21) begin
                            if (player_score == 21) begin
                                blackjack_win <= 1'b1;
                            end
                            win_reg  <= 1'b1;
                            lose_reg <= 1'b0;
                            draw_reg <= 1'b0;
                            $display("you win!");
                        end 
                        else begin
                            win_reg  <= 1'b0;
                            lose_reg <= 1'b0;
                            draw_reg <= 1'b1;
                            $display("draw");
                        end
                        // split_active <= 0;
                        if (next) begin
                            bj_game_state <= BETTING_PHASE;
                            first_turn <= 1;
                        end
                    // if split done
                    end else begin
                        // split1 result
                        if ((split1_score < dealer_score && dealer_score <= 21) 
                            || split1_score > 21) begin
                            1_win_reg  <= 1'b0;
                            1_lose_reg <= 1'b1;
                            1_draw_reg <= 1'b0;
                            lose_reg <= 1'b1;
                            $display("split hand1 lose");
                        end 
                        else if ((split1_score > dealer_score && split1_score <= 21) 
                            || dealer_score > 21) begin
                            if (split1_score == 21) begin
                                blackjack_win <= 1'b1;
                            end
                            1_win_reg  <= 1'b1;
                            1_lose_reg <= 1'b0;
                            1_draw_reg <= 1'b0;
                            win_reg <= 1'b1;
                            $display("split hand1 win!");
                        end 
                        else begin
                            1_win_reg  <= 1'b0;
                            1_lose_reg <= 1'b0;
                            1_draw_reg <= 1'b1;
                            draw_reg <= 1'b1;
                            $display("split hand1 draw");
                        end
                        // split2 result
                        if ((split2_score < dealer_score && dealer_score <= 21) 
                            || split2_score > 21) begin
                            2_win_reg  <= 1'b0;
                            2_lose_reg <= 1'b1;
                            2_draw_reg <= 1'b0;
                            lose_reg <= 1'b1;
                            $display("split hand2 lose");
                        end 
                        else if ((split2_score > dealer_score && split2_score <= 21) 
                            || dealer_score > 21) begin
                            if (split2_score == 21) begin
                                blackjack_win <= 1'b1;
                            end
                            2_win_reg  <= 1'b1;
                            2_lose_reg <= 1'b0;
                            2_draw_reg <= 1'b0;
                            win_reg <= 1'b1;
                            $display("split hand2 win!");
                        end 
                        else begin
                            2_win_reg  <= 1'b0;
                            2_lose_reg <= 1'b0;
                            2_draw_reg <= 1'b1;
                            draw_reg <= 1'b1;
                            $display("split hand2 draw");
                        end
                    end
                end
            endcase
        end
    end

    assign player_current_score = player_score;
    assign dealer_current_score = dealer_score;
    assign player_current_score_split = split_score;
    assign player_new_card = player_new_card_reg;
    assign player_new_card_split = player_new_card_split_reg;
    assign current_coin = current_coin_reg;
    assign can_split = split_able;

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
            current_coin_reg <= initial_coin;
            if (bj_game_state == BETTING_PHASE) begin
                bet_amount <= (bet_8 << 3) | (bet_4 << 2) | (bet_2 << 1) | bet_1;
                current_coin_reg <= current_coin_reg - bet_amount;
            end

            if (!split_complete && double) begin        // revised
                current_coin_reg <= current_coin_reg - bet_amount;
                bet_amount <= bet_amount * 2;
            end

            if (bj_game_state == RESULT_PHASE) begin
                if (!split_complete) begin
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
                else begin
                    if (1_win_reg && 2_win_reg) begin
                        if (1_double && 2_double) begin
                            current_coin_reg <= current_coin_reg + (-1 + 3 + 3) * bet_amount;
                        end else if ((1_double && !2_double) || (!1_double && 2_double)) begin
                            current_coin_reg <= current_coin_reg + (-1 + 3 + 2) * bet_amount;
                        end else if (!1_double && !2_double) begin
                            current_coin_reg <= current_coin_reg + (-1 + 2 + 2) * bet_amount;
                        end 
                    end else if ((1_win_reg && 2_lose_reg) || (1_lose_reg && 2_win_reg)) begin
                        if (1_win_reg && 1_double || 2_win_reg && 2_double) begin
                            current_coin_reg <= current_coin_reg + (-1 + 3) * bet_amount;
                        end else begin
                            current_coin_reg <= current_coin_reg + (-1 + 2) * bet_amount;
                        end
                    end else if ((1_win_reg && 2_draw_reg) || (1_draw_reg && 2_win_reg)) begin
                        if (1_win_reg && 1_double || 2_win_reg && 2_double) begin
                            current_coin_reg <= current_coin_reg + (-1 + 3 + 1) * bet_amount;
                        end else begin
                            current_coin_reg <= current_coin_reg + (-1 + 2 + 1) * bet_amount;
                        end
                    end else if (1_lose_reg && 2_lose_reg) begin
                        current_coin_reg <= current_coin_reg + (-1) * bet_amount;
                    end else if ((1_lose_reg && 2_draw_reg) || (1_draw_reg && 2_lose_reg)) begin
                        current_coin_reg <= current_coin_reg + (-1 + 1) * bet_amount;
                    end else if (1_draw_reg && 2_draw_reg) begin
                        current_coin_reg <= current_coin_reg + (-1 + 1 + 1) * bet_amount;
                    end
                end
            end
        end
    end
endmodule