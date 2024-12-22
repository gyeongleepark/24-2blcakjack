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
    output [5:0] player_hand1,
    output [5:0] player_hand2,
    // output [5:0] dealer_hand1,
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

    // card generation instance
    wire [3:0] card1, card2;
    // hands
    reg [5:0] player_hand1 = 0;
    reg [5:0] player_hand2 = 0;
    reg [5:0] dealer_hand1 = 0;
    reg [5:0] dealer_hand2 = 0;
    reg [5:0] player_hand;
    reg [5:0] dealer_hand [1:4];
    reg [5:0] split1_hand [1:4];
    reg [5:0] split2_hand [1:4];

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


    reg hit_before;         // debouncing pulses
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


    reg blackjack_win;
    reg [1:0] new_game = 1'd0;
    reg [2:0] test_signal = 3'd0;

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
        .test(test_signal),
        .card1_out(card1),
        .card2_out(card2)
    );

    debouncer db_rst(reset, clk, rst_reg);
    debouncer db_next(next, clk, nxt_reg);
    debouncer db_hit(hit, clk, hit_reg);
    debouncer db_stand(stand, clk, stand_reg);
    debouncer db_double(double, clk, double_reg);


    //-----------------------------------------
    //       Test signal
    //-----------------------------------------    
    always @(posedge reset) begin
        if (test_signal >= 3'b101) begin
            test_signal <= 3'b000; // Wrap around after 5
        end else begin
            test_signal <= test_signal + 1; // Increment
        end
    end


    //-----------------------------------------
    //       Card generation pulse
    //-----------------------------------------
    assign newcard_pulse = !newcard_ff2 && trigger_newcard;

    always @(posedge clk) begin
        if (rst_pulse) begin
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
                    DEALER_SCORE_PHASE = 4'b1000;
    reg [3:0] bj_game_state;
    reg [2:0] card_get_counter;
    reg [1:0] double_complete;
    reg [1:0] score_calculated;

    always @(posedge clk, negedge next) begin
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
            trigger_newcard <= 0;
            ace_num_p <= 0;
            ace_num_d <= 0;
            split1_count <= 2;
            split2_count <= 2;
            card_get_counter <= 0;
            double_complete <= 0;
            score_calculated <= 0;
        end else begin
            case (bj_game_state)
                BETTING_PHASE: begin
                    // hand over two cards to the player
                    if (!newcard_pulse) begin
                        trigger_newcard <= 1;
                        player_hand1 <= card1;
                        player_hand2 <= card2;
                    end else begin
                        trigger_newcard <= 0;  // Deassert after one pulse
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
                    end
                    // move on to dealer phase
                    if (bet_amount > 0 && next_pulse) begin
                        player_card_count <= 3; // initialize to 3 so that we won't caculate in the index
                        split_card_count <= 2;
                        trigger_newcard <= 1;
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
                            else if (hit_pulse && !split_complete) begin
                                if (!newcard_pulse) begin
                                    trigger_newcard <= 1;
                                end else begin
                                    trigger_newcard <= 0;  // Deassert after one pulse
                                    bj_game_state <= HIT_PHASE;
                                end
                            end 
                            else if (double_pulse && !split_complete) begin
                                if (!newcard_pulse) begin
                                    trigger_newcard <= 1;
                                end else begin
                                    trigger_newcard <= 0;  // Deassert after one pulse
                                    // $display("player_score before: %d", player_score);
                                    bj_game_state <= DOUBLE_PHASE;
                                end
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
                    player_new_card_reg <= card1;
                    if (!next_pulse && !score_calculated) begin
//                        player_new_card_reg <= card1;
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
                        if (!newcard_pulse) begin
                            trigger_newcard <= 1;
                        end else begin
                            trigger_newcard <= 0;
                        end
                        bj_game_state <= PLAYER_CARD_PHASE;
                    end else if (stand_pulse) begin
                        score_calculated <= 1'b0;
                        bj_game_state <= PLAYER_CARD_PHASE;
                    end
                end
                DOUBLE_PHASE: begin
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
                    end else if (next_pulse) begin
                    // stand. go to the dealer phase
                        score_calculated <= 1'b0;
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                end
                DEALER_CARD_PHASE: begin
                    if (first_turn) begin
                        if (trigger_newcard) begin
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
                                if (dealer_score >= 21) begin
                                    bj_game_state <= RESULT_PHASE;
                                end else begin
                                    bj_game_state <= PLAYER_CARD_PHASE;
                                end
                            end
                            // turn off trigger
                            trigger_newcard <= 0;
                        end else begin
                            first_turn <= 1'b0;
                        end
                    end
                    else begin
                        // after player stands
                        if (dealer_score < 17) begin
                            score_calculated <= 1'b0;
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                            end else begin
                                trigger_newcard <= 0;
                                bj_game_state <= DEALER_SCORE_PHASE;
                            end
                        end else begin
                            if (next_pulse) begin
                                bj_game_state <= RESULT_PHASE;
                            end
                        end
                    end
                end
                DEALER_SCORE_PHASE: begin
                    dealer_new_card_reg <= card1;
                    if (dealer_score < 17) begin
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
                        end
                    end
                end
                SPLIT1_PHASE: begin
                    if (split1_score > 21) begin
                        if (next_pulse) begin
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
                        else if (hit_pulse && split_complete) begin
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
                        else if (double_pulse && split_complete) begin
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
                            if (next_pulse) begin
                                bj_game_state <= SPLIT2_PHASE;
                            end
                        end
                        else if (stand_pulse && split_complete) begin
                            if (next_pulse) begin
                                bj_game_state <= SPLIT2_PHASE;
                            end
                        end
                        else if (next_pulse) begin
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
                        else if (hit_pulse && split_complete) begin
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
                        else if (double_pulse && split_complete) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split2_hand[split2_count] <= card1;
                                player_new_card_split_reg <= card1;
                                split2_count <= split2_count + 1;
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                split2_score <= calculate_score_with_ace(split2_hand[1], split2_hand[2], split2_hand[3], split2_hand[4], split2_count);
                            end
                            if (next_pulse) begin
                                bj_game_state <= DEALER_CARD_PHASE;
                            end
                        end
                        else if (stand_pulse && split_complete) begin
                            bj_game_state <= DEALER_CARD_PHASE;
                        end
                        // else if (next_pulse) begin
                            // bj_game_state <= DEALER_CARD_PHASE;
                        // end
                    end  
                end 
                RESULT_PHASE: begin
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
                        new_game <= 1;
                    end
                end
            endcase
        end
    end

    assign player_current_score = player_score;
    assign dealer_current_score = dealer_score;
    assign dealer_new_card = dealer_new_card_reg;
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