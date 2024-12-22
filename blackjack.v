`timescale 1ns / 1ps
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
    output [5:0] player_hand1_out,
    output [5:0] player_hand2_out,
    output [5:0] player_new_card,
    output [5:0] dealer_new_card,
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
    reg split_reg;
    
    reg hit_before;
    reg hit_after = 1'b0;
    reg hit_pulse;

    reg stand_before;
    reg stand_after = 1'b0;
    reg stand_pulse;

    reg rst_before;
    reg rst_after = 1'b0;
    reg rst_pulse;

    reg next_before;
    reg next_after = 1'b0;
    reg next_pulse;

    reg double_before;
    reg double_after = 1'b0;
    reg double_pulse;

    reg split_before;
    reg split_after = 1'b0;
    reg split_pulse;

    // card generation instance
    wire [3:0] card1, card2;
    reg [1:0] sum;
    
    // hands
    reg [5:0] player_hand1 = 0;
    reg [5:0] player_hand2 = 0;
    reg [5:0] dealer_hand1 = 0;
    reg [5:0] dealer_hand2 = 0;
    reg [5:0] player_hand;
    // reg [5:0] dealer_hand [1:4];
    reg [5:0] split1_hand1 = 0;
    reg [5:0] split1_hand2 = 0;
    reg [5:0] split2_hand1 = 0;
    reg [5:0] split2_hand2 = 0;

    integer split1_count;
    integer split2_count;
    reg[3:0] ace_num_p;
    reg[3:0] ace_num_d;

    reg [1:0] hand_count;
    integer player_card_count, dealer_card_count, split_card_count;

    // reg [3:0] split_card1, split_card2;
    // coin calculation
    reg [5:0] bet_amount;
    reg [4:0] initial_coin = 5'd30;

    reg split_able;      // condition check card1 = card2
    reg split_active;    // if split done raise 1
    reg split_complete;  // split complete
    reg first_turn;

    reg blackjack_win;
    reg [1:0] new_game = 1'd0;
    reg [2:0] test_signal = 3'd0;

    reg [5:0] player_score;
    reg [5:0] dealer_score;
    reg [5:0] split_score;
    reg [5:0] split1_score;
    reg [5:0] split2_score;
    reg [1:0] split1_active;
    reg [1:0] split2_active;

    deck u_deck(
        .clk(clk),
        .reset(reset),
        .num(sum),
        .card1(card1),
        .card2(card2)
    );  

    debouncer db_rst(reset, clk, rst_reg);
    debouncer db_next(next, clk, nxt_reg);
    debouncer db_hit(hit, clk, hit_reg);
    debouncer db_stand(stand, clk, stand_reg);
    debouncer db_double(double, clk, double_reg);


    //-----------------------------------------
    //       Button input pulse
    //-----------------------------------------
    always @ (posedge clk) 
    begin
        // Create hit pulse
        hit_before <= hit_reg;
        hit_after <= hit_before;
        if (hit_before != hit_after && hit_before) 
        begin
            hit_pulse <= 1'b1;
        end
        else
        begin
            hit_pulse <= 1'b0;
        end

        // Create Stand pulse
        stand_before <= stand_reg;
        stand_after <= stand_before;
        if (stand_before != stand_after && stand_before) 
        begin
            stand_pulse <= 1'b1;
        end
        else
        begin
            stand_pulse <= 1'b0;
        end

        // Create Rst pulse
        rst_before <= rst_reg;
        rst_after <= rst_before;
        if (rst_before != rst_after && rst_before) 
        begin
            rst_pulse <= 1'b1;
        end
        else
        begin
            rst_pulse <= 1'b0;
        end

         // Create double pulse
        double_before <= double_reg;
        double_after <= double_before;
        if (double_before != double_after && double_before) 
        begin
            double_pulse <= 1'b1;
        end
        else
        begin
            double_pulse <= 1'b0;
        end

         // Create next pulse
        next_before <= nxt_reg;
        next_after <= next_before;
        if (next_before != next_after && next_before) 
        begin
            next_pulse <= 1'b1;
        end
        else
        begin
            next_pulse <= 1'b0;
        end

        // Create split pulse
        split_before <= split_reg;
        split_after <= split_before;
        if (split_before != split_after && split_before) 
        begin
            split_pulse <= 1'b1;
        end
        else
        begin
            split_pulse <= 1'b0;
        end
    end

    //-----------------------------------------
    //               FSM
    //-----------------------------------------

    parameter [3:0] BETTING_PHASE = 4'b0000,
                    DEALER_CARD_PHASE = 4'b0001,
                    PLAYER_CARD_PHASE = 4'b0010,
                    RESULT_PHASE = 4'b0011,
                    SPLIT1_PHASE= 4'b0100, 
                    SPLIT2_PHASE= 4'b0101,
                    HIT_PHASE = 4'b0110,
                    DOUBLE_PHASE = 4'b0111,
                    DEALER_SCORE_PHASE = 4'b1000,
                    SPLIT1_HIT_PHASE = 4'b1001,
                    SPLIT1_DOUBLE_PHASE = 4'b1010,
                    SPLIT2_HIT_PHASE = 4'b1011,
                    SPLIT2_DOUBLE_PHASE = 4'b1100;
    reg [3:0] bj_game_state;
    reg [2:0] card_get_counter;
    reg [1:0] score_calculated, split_lose, split_win, split_draw;

    always @(posedge clk) begin
        if (rst_pulse) begin
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
//            trigger_newcard <= 0;
            ace_num_p <= 0;
            ace_num_d <= 0;
            split1_count <= 2;
            split2_count <= 2;
            card_get_counter <= 0;
            score_calculated <= 0;
            split1_active <= 0;
            split2_active <= 0;
            sum <= 0;
        end else begin
            case (bj_game_state)
                BETTING_PHASE: begin
                    // hand over two cards to the player
                    sum <= 2'b10;
                    player_hand1 <= card1;
                    player_hand2 <= card2;
                    if((player_hand1 != 0) && (player_hand2 != 0) && (player_hand1 == player_hand2)) begin
                        split_able <= 1'b1;
                    end
                    if (player_hand1 + player_hand2 + 10 > 21) begin
                        player_score <= player_hand1 + player_hand2;
                    end else begin
                        if (player_hand1 != player_hand2) begin
                            if (player_hand1 == 4'd1 || player_hand2 == 4'd1) begin
                                player_score <= player_hand1 + player_hand2 + 10;
                                ace_num_p <= 4'd1;
                            end else begin
                                player_score <= player_hand1 + player_hand2;
                            end
                        end else begin
                            if (player_hand1 == 4'd1) begin
                                player_score <= player_hand1 + player_hand2 + 10;
                                ace_num_p <= 4'd2;
                            end 
                            // else : split case. no need to think
                        end
                    end
                    // move on to dealer phase
                    if (bet_amount > 0 && next_pulse) begin
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                end
                PLAYER_CARD_PHASE: begin
                    // player bust
                    if (player_score > 21 || dealer_score == 21) begin
                        bj_game_state <= RESULT_PHASE;
                    end 
                    else begin
                        if (!stand_pulse) begin
                            if (split_able && split_pulse && split_active) begin
                                // initialize split1_hand 
                                split1_hand1 <= player_hand1;
                                split1_hand2 <= 0;
                                // initialize split2_hand
                                split2_hand1 <= player_hand2;
                                split2_hand2 <= 0;
                                // calcualte split score
                                split1_score <= player_hand1;
                                split2_score <= player_hand2;
                                // you cannot split more, split is completed
                                split_active <= 0;
                                split_complete <= 1;
                                // move on to split1 phase
                                split1_active <= 1;
                                bj_game_state <= SPLIT1_PHASE;
                            end 
                            else if (hit_pulse && !split_complete) begin
                                bj_game_state <= HIT_PHASE;
                            end 
                            else if (double_pulse && !split_complete) begin
                                bj_game_state <= DOUBLE_PHASE;
                            end
                            else if (stand_pulse && !split_complete) begin
                                if (dealer_score >= 17) begin
                                    bj_game_state <= RESULT_PHASE;
                                end else begin
                                    bj_game_state <= DEALER_CARD_PHASE;
                                end
                            end
                            else if (player_score == 21) begin
                                if (next_pulse) begin
                                    bj_game_state <= DEALER_CARD_PHASE;
                                end
                            end
                        end 
                        else if (stand_pulse && dealer_score >= 17) begin
                            bj_game_state <= RESULT_PHASE;
                        end 
                        else begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                    end
                end
                HIT_PHASE: begin
                    sum <= 2'b01;
                    player_new_card_reg <= card1;
                    // player hit
                    if (!next_pulse && !score_calculated) begin
                        // Calculate score
                        // if there was ace in intial two hands
                        if (ace_num_p > 0) begin
                            if (player_score + card1 > 21) begin
                                if (card1 == 4'd1) begin
                                    player_score <= player_score + card1;
                                    ace_num_p <= ace_num_p + 1;
                                end else begin
                                    player_score <= player_score - 10 + card1;
                                end
                            end else begin
                                player_score <= player_score + card1;
                            end
                        end else begin
                            // if there was no ace in the initial two hands
                            if (card1 == 4'd1) begin
                                ace_num_p <= ace_num_p + 1;
                                if (player_score + 11 > 21 && player_score + card1 < 21) begin
                                    player_score <= player_score + card1;
                                end else if (player_score + 11 > 21 && player_score + card1 > 21) begin
                                    player_score <= player_score + card1;
                                end else if (player_score + 11 < 21) begin
                                    player_score <= player_score + 10 + card1;
                                end
                            end else begin
                                player_score <= player_score + card1;
                            end
                        end
                        score_calculated <= 1'b1;
//                        newcard_pulse <= 0;
                    end else if (next_pulse) begin
                        score_calculated <= 1'b0;
                        // player bust
                        if (player_score > 21) begin
                            bj_game_state <= RESULT_PHASE;
                        end else begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                    end else if (hit_pulse) begin
                        score_calculated <= 1'b0;
                        bj_game_state <= PLAYER_CARD_PHASE;
                    end else if (stand_pulse) begin
                        score_calculated <= 1'b0;
                        bj_game_state <= PLAYER_CARD_PHASE;
                    end
                end
                DOUBLE_PHASE: begin
                    sum <= 2'b01;
                    player_new_card_reg <= card1;
                    // calc score
                    if (!next_pulse && !score_calculated) begin
                        // Calculate score
                        // if there was ace in intial two hands
                        if (ace_num_p > 0) begin
                            if (player_score + card1 > 21) begin
                                if (card1 == 4'd1) begin
                                    player_score <= player_score + card1;
                                    ace_num_p <= ace_num_p + 1;
                                end else begin
                                    player_score <= player_score - 10 + card1;
                                end
                            end else begin
                                player_score <= player_score + card1;
                            end
                        end else begin
                            // if there was no ace in the initial two hands
                            if (card1 == 4'd1) begin
                                ace_num_p <= ace_num_p + 1;
                                if (player_score + 11 > 21 && player_score + card1 < 21) begin
                                    player_score <= player_score + card1;
                                end else if (player_score + 11 > 21 && player_score + card1 > 21) begin
                                    player_score <= player_score + card1;
                                end else if (player_score + 11 < 21) begin
                                    player_score <= player_score + 10 + card1;
                                end
                            end else begin
                                player_score <= player_score + card1;
                            end
                        end
                        score_calculated <= 1'b1;
                        bj_game_state <= DOUBLE_PHASE;
//                        newcard_pulse <= 0;
                    end else if (next_pulse) begin
                    // stand. go to the dealer phase
                        score_calculated <= 1'b0;
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                end
                DEALER_CARD_PHASE: begin
                    if (first_turn) begin
                        // if (trigger_newcard) begin
                            // newcard_pulse <= 1;
                        sum <= 2'b10;
                        dealer_hand1 <= card1;
                        dealer_hand2 <= card2;
                        dealer_new_card_reg <= card1;
                        // dealer original score
                        if (card1 + card2 + 10 > 21) begin
                            dealer_score <= card1 + card2;
                        end else begin
                            if (card1 == 4'd1 || card2 == 4'd1) begin
                                dealer_score <= card1 + card2 + 10;
                            end else begin
                                dealer_score <= card1 + card2;
                            end
                        end
                        if (next_pulse) begin
//                            newcard_pulse <= 0;
                            if (dealer_score >= 21 || player_score >= 21) begin
                                bj_game_state <= RESULT_PHASE;
                            end else begin
                                bj_game_state <= PLAYER_CARD_PHASE;
                            end
                        end
                        // turn off trigger
                        // trigger_newcard <= 0;
                    // end else begin
                        first_turn <= 1'b0;
                    // end
                    end
                    else begin
                        // after player stands
                        if (dealer_score < 17) begin
                            score_calculated <= 1'b0;
                            bj_game_state <= DEALER_SCORE_PHASE;
                        end else begin
                            if (next_pulse) begin
                                bj_game_state <= RESULT_PHASE;
                            end
                        end
                    end
                end
                DEALER_SCORE_PHASE: begin
                    if (dealer_score < 17) begin
                        sum <= 2'd01;
//                        dealer_new_card_reg <= card1;
                        // Calculate score
                        // if there was ace in intial two hands
                        if (!score_calculated) begin
                            if (ace_num_d > 0) begin
                                if (dealer_score + card1 > 21) begin
                                    if (card1 == 4'd1) begin
                                        dealer_score <= dealer_score + card1;
                                        ace_num_d <= ace_num_d + 1;
                                    end else begin
                                        dealer_score <= dealer_score - 10 + card1;
                                    end
                                end else begin
                                    dealer_score <= dealer_score + card1;
                                end
                            end else begin
                                // if there was no ace in the initial two hands
                                if (card1 == 4'd1) begin
                                    ace_num_d <= ace_num_d + 1;
                                    if (dealer_score + 11 > 21 && dealer_score + card1 < 21) begin
                                        dealer_score <= dealer_score + card1;
                                    end else if (dealer_score + 11 > 21 && dealer_score + card1 > 21) begin
                                        dealer_score <= dealer_score + card1;
                                    end else if (dealer_score + 11 < 21) begin
                                        dealer_score <= dealer_score + 10 + card1;
                                    end
                                end else begin
                                    dealer_score <= dealer_score + card1;
                                end
                            end
                            score_calculated <= 1'b1;
                            bj_game_state <= DEALER_CARD_PHASE;
                            // newcard_pulse <= 0;
                        end
                    end
                end
                SPLIT1_PHASE: begin
                    if (split1_score > 21) begin
                        if (next_pulse) begin
                            ace_num_p <= 0;
                            bj_game_state <= SPLIT2_PHASE;
                        end
                    end
                    else begin
                        // initialize split1_hand with two cards
                        if (split1_hand2 == 0) begin
                                sum <= 2'd01;
                                split1_hand2 <= card1;
                                //split1 initial score
                                if (split1_hand1 + card1 + 10 > 21) begin
                                    split1_score <= split1_hand1 + card1;
                                end else begin
                                    if (split1_hand1 != card1) begin
                                        if (split1_hand1 == 4'd1 || card1 == 4'd1) begin
                                            split1_score <= split1_hand1 + card1 + 10;
                                            ace_num_p <= 4'd1;
                                        end else begin
                                            split1_score <= split1_hand1 + card1;
                                        end
                                    end else begin
                                        if (split1_hand1 == 4'd1) begin
                                            split1_score <= split1_hand1 + split1_hand2 + 10;
                                            ace_num_p <= 4'd2;
                                        end 
                                    end
                                end
                            // end
                            bj_game_state <= SPLIT1_PHASE;
                        end
                        // hit
                        else if (hit_pulse && split_complete) begin
                                bj_game_state <= SPLIT1_HIT_PHASE;
                        end
                        else if (double_pulse && split_complete) begin
                                bj_game_state <= SPLIT1_DOUBLE_PHASE;
                        end
                        else if (stand_pulse && split_complete) begin
                            if (next_pulse) begin
                                ace_num_p <= 0;
                                bj_game_state <= SPLIT2_PHASE;
                            end
                        end
                        else if (next_pulse) begin
                            ace_num_p <= 0;
                            bj_game_state <= SPLIT2_PHASE;
                        end
                    end 
                end 
                SPLIT2_PHASE: begin
                    if (split2_score >= 21) begin
                        if (next_pulse) begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                    end   
                    else begin
                        // initialize split2_hand with two cards
                        if (split2_hand2 == 0) begin
                                sum <= 2'd01;
                                split2_hand2 <= card1;
                                //split1 initial score
                                if (split2_hand1 + card1 + 10 > 21) begin
                                    split2_score <= split2_hand1 + card1;
                                end else begin
                                    if (split2_hand1 != card1) begin
                                        if (split2_hand1 == 4'd1 || card1 == 4'd1) begin
                                            split2_score <= split2_hand1 + card1 + 10;
                                            ace_num_p <= 4'd1;
                                        end else begin
                                            split2_score <= split2_hand1 + card1;
                                        end
                                    end else begin
                                        if (split2_hand1 == 4'd1) begin
                                            split2_score <= split2_hand1 + split2_hand2 + 10;
                                            ace_num_p <= 4'd2;
                                        end 
                                    end
                                end
                            // end
                            bj_game_state <= SPLIT2_PHASE;
                        end
                        else if (hit_pulse && split_complete) begin
                            // if (!newcard_pulse) begin
                                // trigger_newcard <= 1;
                            // end else begin
                                // trigger_newcard <= 0; 
                                bj_game_state <= SPLIT2_HIT_PHASE;
                            // end
                        end
                        else if (double_pulse && split_complete) begin
                            // if (!newcard_pulse) begin
                                // trigger_newcard <= 1;
                            // end else begin
                                // trigger_newcard <= 0;  // Deassert after one pulse
                                bj_game_state <= SPLIT2_DOUBLE_PHASE;
                            // end
                            // if (next_pulse) begin
                            //     bj_game_state <= DEALER_CARD_PHASE;
                            // end
                        end
                        else if (stand_pulse && dealer_score >= 17) begin
                            bj_game_state <= RESULT_PHASE;
                        end
                        else begin
                            bj_game_state <= SPLIT2_PHASE;
                        end
                    end  
                end 
                SPLIT1_HIT_PHASE: begin
                    if (!next_pulse && !score_calculated) begin
                        sum <= 2'd01;
                        player_new_card_split_reg <= card1;
                        // Calculate score
                        // if there was ace in intial two hands
                        if (ace_num_p > 0) begin
                            if (split1_score + card1 > 21) begin
                                if (card1 == 4'd1) begin
                                    split1_score <= split1_score + card1;
                                    ace_num_p <= ace_num_p + 1;
                                end else begin
                                    split1_score <= split1_score - 10 + card1;
                                end
                            end else begin
                                split1_score <= split1_score + card1;
                            end
                        end else begin
                            // if there was no ace in the initial two hands
                            if (card1 == 4'd1) begin
                                ace_num_p <= ace_num_p + 1;
                                if (split1_score + 11 > 21 && split1_score + card1 < 21) begin
                                    split1_score <= split1_score + card1;
                                end else if (split1_score + 11 > 21 && split1_score + card1 > 21) begin
                                    split1_score <= split1_score + card1;
                                end else if (player_score + 11 < 21) begin
                                    split1_score <= split1_score + 10 + card1;
                                end
                            end else begin
                                split1_score <= split1_score + card1;
                            end
                        end
                        score_calculated <= 1'b1;
                    end else if (next_pulse) begin
                        score_calculated <= 1'b0;
                        // player bust
                        // if (split1_score > 21) begin
                        ace_num_p <= 0;
                        // trigger_newcard <= 1;
                        bj_game_state <= SPLIT2_PHASE;
                        split1_active <= 0;
                        // end else begin
                            // bj_game_state <= SPLIT1_PHASE;
                        // end
                    end else if (hit_pulse) begin
                        score_calculated <= 1'b0;
                        // if (!newcard_pulse) begin
                            // trigger_newcard <= 1;
                        // end else begin
                            // trigger_newcard <= 0;
                            // bj_game_state <= SPLIT1_PHASE;
                        // end
                        bj_game_state <= SPLIT1_PHASE;
                    end else if (stand_pulse) begin
                        score_calculated <= 1'b0;
                        ace_num_p <= 0;
                        bj_game_state <= SPLIT2_PHASE;
                        split1_active <= 0;
                    end
                end
                SPLIT1_DOUBLE_PHASE: begin
                    sum <= 2'd01;
                    player_new_card_split_reg <= card1;
                    // calc score
                    if (!next_pulse && !score_calculated) begin
                        // Calculate score
                        // if there was ace in intial two hands
                        if (ace_num_p > 0) begin
                            if (split1_score + card1 > 21) begin
                                if (card1 == 4'd1) begin
                                    split1_score <= split1_score + card1;
                                    ace_num_p <= ace_num_p + 1;
                                end else begin
                                    split1_score <= split1_score - 10 + card1;
                                end
                            end else begin
                                split1_score <= split1_score + card1;
                            end
                        end else begin
                            // if there was no ace in the initial two hands
                            if (card1 == 4'd1) begin
                                ace_num_p <= ace_num_p + 1;
                                if (split1_score + 11 > 21 && split1_score + card1 < 21) begin
                                    split1_score <= split1_score + card1;
                                end else if (split1_score + 11 > 21 && split1_score + card1 > 21) begin
                                    split1_score <= split1_score + card1;
                                end else if (split1_score + 11 < 21) begin
                                    split1_score <= split1_score + 10 + card1;
                                end
                            end else begin
                                split1_score <= split1_score + card1;
                            end
                        end
                        score_calculated <= 1'b1;
                        bj_game_state <= SPLIT1_DOUBLE_PHASE;
                    end else if (next_pulse) begin
                    // stand. go to the SPLIT2 phase
                        ace_num_p <= 0;
                        score_calculated <= 1'b0;
                        bj_game_state <= SPLIT2_PHASE;
                        split1_active <= 0;
                    end
                end
                SPLIT2_HIT_PHASE: begin
                    sum <= 2'd01;
                    player_new_card_split_reg <= card1;
                    if (!next_pulse && !score_calculated) begin
                        // Calculate score
                        // if there was ace in intial two hands
                        if (ace_num_p > 0) begin
                            if (split2_score + card1 > 21) begin
                                if (card1 == 4'd1) begin
                                    split2_score <= split2_score + card1;
                                    ace_num_p <= ace_num_p + 1;
                                end else begin
                                    split2_score <= split2_score - 10 + card1;
                                end
                            end else begin
                                split2_score <= split2_score + card1;
                            end
                        end else begin
                            // if there was no ace in the initial two hands
                            if (card1 == 4'd1) begin
                                ace_num_p <= ace_num_p + 1;
                                if (split2_score + 11 > 21 && split2_score + card1 < 21) begin
                                    split2_score <= split2_score + card1;
                                end else if (split2_score + 11 > 21 && split2_score + card1 > 21) begin
                                    split2_score <= split2_score + card1;
                                end else if (split2_score + 11 < 21) begin
                                    split2_score <= split2_score + 10 + card1;
                                end
                            end else begin
                                split2_score <= split2_score + card1;
                            end
                        end
                        score_calculated <= 1'b1;
                    end else if (next_pulse) begin
                        score_calculated <= 1'b0;
                        // player bust
                        ace_num_p <= 0;
                        bj_game_state <= DEALER_CARD_PHASE;
                    end else if (hit_pulse) begin
                        score_calculated <= 1'b0;
                        // if (!newcard_pulse) begin
                            // trigger_newcard <= 1;
                        // end else begin
                            // trigger_newcard <= 0;
                            // bj_game_state <= SPLIT2_PHASE;
                        // end
                        bj_game_state <= SPLIT2_PHASE;
                    end else if (stand_pulse) begin
                        score_calculated <= 1'b0;
                        bj_game_state <= DEALER_CARD_PHASE;
                        // split1_active <= 0;
                        ace_num_p <= 0;
                    end
                end
                SPLIT2_DOUBLE_PHASE: begin
                    sum <= 2'd01;
                    player_new_card_split_reg <= card1;
                    // calc score
                    if (!next_pulse && !score_calculated) begin
                        // Calculate score
                        // if there was ace in intial two hands
                        if (ace_num_p > 0) begin
                            if (split2_score + card1 > 21) begin
                                if (card1 == 4'd1) begin
                                    split2_score <= split2_score + card1;
                                    ace_num_p <= ace_num_p + 1;
                                end else begin
                                    split2_score <= split2_score - 10 + card1;
                                end
                            end else begin
                                split2_score <= split2_score + card1;
                            end
                        end else begin
                            // if there was no ace in the initial two hands
                            if (card1 == 4'd1) begin
                                ace_num_p <= ace_num_p + 1;
                                if (split2_score + 11 > 21 && split2_score + card1 < 21) begin
                                    split2_score <= split2_score + card1;
                                end else if (split2_score + 11 > 21 && split2_score + card1 > 21) begin
                                    split2_score <= split2_score + card1;
                                end else if (split2_score + 11 < 21) begin
                                    split2_score <= split2_score + 10 + card1;
                                end
                            end else begin
                                split2_score <= split2_score + card1;
                            end
                        end
                        score_calculated <= 1'b1;
                        bj_game_state <= SPLIT2_DOUBLE_PHASE;
                    end else if (next_pulse) begin
                    // stand. go to the dealer phase
                        score_calculated <= 1'b0;
                        ace_num_p <= 0;
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                end
                RESULT_PHASE: begin
                    if (split2_active) begin
                        // condition check
                        if (((split1_score < dealer_score && dealer_score <= 21) || split1_score > 21) || 
                        (split2_score > 21 || (split2_score < dealer_score && dealer_score <= 21))) begin
                            split_lose <= 1'b1;
                            split_win <= 1'b0;
                            split_draw <= 1'b0;
                        end
                        else if (((split1_score > dealer_score && split1_score <= 21) || dealer_score > 21) || 
                        (dealer_score < 21 || (split2_score > dealer_score && split2_score <= 21))) begin
                            split_win <= 1'b1;
                            split_lose <= 1'b0;
                            split_draw <= 1'b0;
                        end
                        else begin
                            split_win <= 1'b0;
                            split_lose <= 1'b0;
                            split_draw <= 1'b1;
                        end
                        // assert leg
                        if (split_lose) begin
                            lose_reg <= 1'b1;
                            $display("split lose");
                        end else if (split_win) begin
                            win_reg <= 1'b1;
                            $display("split win");
                        end else begin
                            draw_reg <= 1'b1;
                            $display("split draw");
                        end

                        if (next_pulse) begin
                            bj_game_state <= BETTING_PHASE;
                            split2_active <= 0;
                            first_turn <= 1;
                            split_complete <= 0;
                            player_hand1 <= 0;
                            player_hand2 <= 0;
                            dealer_hand1 <= 0;
                            dealer_hand2 <= 0;
                            player_score <= 0;
                            dealer_score <= 0;
                            ace_num_d <= 0;
                            ace_num_p <= 0;
                            new_game <= 1;
                        end
                    end else begin
                        // normal situations
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
                        split_active <= 0;
                        if (next_pulse) begin
                            bj_game_state <= BETTING_PHASE;
                            first_turn <= 1;
                            player_hand1 <= 0;
                            player_hand2 <= 0;
                            dealer_hand1 <= 0;
                            dealer_hand2 <= 0;
                            player_score <= 0;
                            dealer_score <= 0;
                            ace_num_d <= 0;
                            ace_num_p <= 0;
                            new_game <= 1;
                        end
                    end
                end
            endcase
        end
    end

    assign player_current_score = player_score;
    assign dealer_current_score = dealer_score;
    assign dealer_new_card = dealer_new_card_reg;
    assign player_hand1_out = player_hand1;
    assign player_hand2_out = player_hand2;
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
    always @(posedge clk) begin
        if (rst_pulse) begin
            if (!new_game)
                current_coin_reg <= initial_coin;
            else 
                current_coin_reg <= current_coin_reg;
        end else begin
            current_coin_reg <= initial_coin;
            if (bj_game_state == BETTING_PHASE) begin
                bet_amount <= (bet_8 << 3) | (bet_4 << 2) | (bet_2 << 1) | bet_1;
                current_coin_reg <= current_coin_reg - bet_amount;
            end

            if (double_pulse) begin
                current_coin_reg <= current_coin_reg - bet_amount;
                bet_amount <= bet_amount * 2;
            end

            if (bj_game_state == RESULT_PHASE) begin
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
    end
endmodule