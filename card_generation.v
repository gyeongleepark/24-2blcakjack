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
    // output [5:0] player_hand[1:4],
    // output [5:0] dealer_hand[1:4],
    output split_can,
    output Win,
    output Lose,
    output Draw
);

    // Internal signals
    wire lose1, lose2, win1, win2, draw1, draw2;
    wire [3:0] card1, card2, card_value;

    reg [5:0] player_hand [1:4];
    reg [5:0] dealer_hand [1:4];
    reg [5:0] split_hand [1:4];

    reg [3:0] split_card1, split_card2;
    reg [5:0] bet_amount;
    reg [4:0] initial_coin = 5'd30;
 
    reg [5:0] player_new_card_reg;
    reg [5:0] dealer_new_card_reg;
    reg [5:0] player_current_score_split_reg; 
    reg [5:0] player_new_card_split_reg;
    reg [4:0] current_coin_reg;

    reg win_reg;
    reg lose_reg;
    reg draw_reg;
    reg lose_p, lose_s, win_p, win_s, draw_p,draw_s;

    //reg split_can;       // 처음 card1 = card2
    reg split_active;    // split 한 적 없으면 1 있으면 0
    reg split_complete;  // split 함
    reg first_turn;

    reg blackjack_win;

    reg [5:0] player_score;
    reg [5:0] dealer_score;
    reg [5:0] split_score;

    wire newcard_pulse;
    reg newcard_ff, newcard_ff2;
    reg trigger_newcard;

    // Card generation instance
    card_generation u_card (
        .clk(clk),
        .reset(reset),
        .on(newcard_pulse),
        .test(3'b011),
        .card1_out(card1),
        .card2_out(card2)
    );

    //-----------------------------------------
    //       Card generation pulse
    //-----------------------------------------
    assign newcard_pulse = !newcard_ff2 && trigger_newcard;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            newcard_ff <= 1'b0;
            newcard_ff2 <= 1'b0;
        end else begin
            // Update flip-flops for pulse generation
            newcard_ff <= trigger_newcard;
            newcard_ff2 <= newcard_ff;
            if (newcard_pulse) begin
                trigger_newcard <= 0;  // Turn off trigger
            end
        end
    end

    //-----------------------------------------
    //               FSM
    //-----------------------------------------

    parameter [2:0] BETTING_PHASE = 3'b000, 
                    DEALER_CARD_PHASE = 3'b001,
                    PLAYER_CARD_PHASE = 3'b010, 
                    RESULT_PHASE = 3'b011,
                    SPLIT1_PHASE = 3'b100,
                    SPLIT2_PHASE = 3'b101;
    reg [2:0] bj_game_state;

    integer i, j;
    


    always @(posedge clk) begin
        if (reset) begin
            bj_game_state <= BETTING_PHASE;
            player_score <= 0;
            dealer_score <= 0;
            split_score <= 0;
            current_coin_reg <= 0;
            player_new_card_reg <= 0;
            dealer_new_card_reg <= 0;
            player_new_card_split_reg <= 0;
            win_reg <= 0;
            lose_reg <= 0;
            draw_reg <= 0;
            split_active <= 1;
            split_complete <= 0;
            first_turn <= 1;
            blackjack_win <= 0;
            trigger_newcard <= 0;
            lose_p <= 0;
            lose_s <=0;
            win_p <= 0;
            win_s <= 0;
            draw_p <= 0;
            draw_s <= 0;
            i = 3;
            j = 3;
        end else begin
            case (bj_game_state)
                BETTING_PHASE: begin
                    current_coin_reg <= initial_coin;
                    // hand over two cards to the player
                    if (!newcard_pulse) begin
                        trigger_newcard <= 1;
                        player_hand[1] <= card1;
                        player_hand[2] <= card2;
                        player_score <= player_hand[1] + player_hand[2];
                        // Handle player ace of the first two cards
                        if (player_hand[1] == 6'd1) begin
                            player_score <= player_hand[1] + player_hand[2] + 10;
                        end else if (player_hand[2] == 6'd1) begin
                            player_score <= player_hand[1] + player_hand[2] + 10;
                        end
                        if(player_hand[1]==player_hand[2]) begin
                            split_complete <= 1;
                        end 
                        if (split && split_complete && split_active) begin
                            trigger_newcard <= 1;
                            split_card1 <= card1;
                            split_card2 <= card2;
                            player_score <= card1;
                            split_score <= card2;
                            split_complete <= 1'b1;
                            split_active <= 1'b0;
                            bj_game_state <= SPLIT1_PHASE;
                        end 
                    end else begin
                        trigger_newcard <= 0;  // Deassert after one pulse
                    end
                    // move on to dealer phase
                    if (bet_amount > 0 && next) begin
                        bj_game_state <= DEALER_CARD_PHASE;
                    end
                end
                SPLIT1_PHASE: 
                    if (player_score >= 21) begin
                        bj_game_state <= SPLIT2_PHASE;
                    end 
                    
                    else if (!stand && !next) begin
                            // hit
                        if (hit) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split_hand[i] <= card1;
                                player_new_card_split_reg <= card1;
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                // $display("player_score before: %d", player_score);
                                split_score <= split_score + player_new_card_split_reg;
                                // $display("player_score after: %d", player_score);
                            end
                                bj_game_state <= SPLIT1_PHASE;
                            end 
                        else if (double) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split_hand[i] <= card1;
                                player_new_card_split_reg <= card1;
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                // $display("player_score before: %d", player_score);
                                split_score <= split_score + player_new_card_split_reg;
                                // $display("player_score after: %d", player_score);
                            end
                                bj_game_state <= SPLIT2_PHASE;
                            end
                    end 
                    else begin
                            // if not bust, go to the dealer phase 
                            bj_game_state <= SPLIT2_PHASE;
                    end
                SPLIT2_PHASE: 
                    if (split_score >= 21) begin
                        bj_game_state <= DEALER_CARD_PHASE;
                    end 
                    
                    else if (!stand && !next) begin
                            // hit
                        if (hit) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split_hand[i] <= card1;
                                player_new_card_split_reg <= card1;
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                // $display("player_score before: %d", player_score);
                                split_score <= split_score + player_new_card_split_reg;
                                // $display("player_score after: %d", player_score);
                            end
                            bj_game_state <= SPLIT2_PHASE;
                        end
                        else if (double) begin
                            if (!newcard_pulse) begin
                                trigger_newcard <= 1;
                                split_hand[i] <= card1;
                                player_new_card_split_reg <= card1;
                            end else begin
                                trigger_newcard <= 0;  // Deassert after one pulse
                                // $display("player_score before: %d", player_score);
                                split_score <= split_score + player_new_card_split_reg;
                                // $display("player_score after: %d", player_score);
                            end
                                bj_game_state <= DEALER_CARD_PHASE;
                            end
                    end 
                    else begin
                            // if not bust, go to the dealer phase 
                            bj_game_state <= DEALER_CARD_PHASE;
                    end

                PLAYER_CARD_PHASE: begin
                    // player bust
                    if (player_score >= 21 || dealer_score == 21) begin
                        bj_game_state <= RESULT_PHASE;
                    end 
                    else begin
                        if (!stand) begin
                            // hit
                            if (hit) begin
                                if (!split_complete) begin
                                    if (!newcard_pulse) begin
                                        trigger_newcard <= 1;
                                        player_hand[i] <= card1;
                                        player_new_card_reg <= card1;
                                    end else begin
                                        trigger_newcard <= 0;  // Deassert after one pulse
                                        // $display("player_score before: %d", player_score);
                                        player_score <= player_score + player_new_card_reg;
                                        // $display("player_score after: %d", player_score);
                                    end
                                    bj_game_state <= PLAYER_CARD_PHASE;
                                end 
                            end 
                            // double
                            else if (double) begin
                                if (!newcard_pulse) begin
                                    trigger_newcard <= 1;
                                    player_hand[i] <= card1;
                                    player_new_card_reg <= card1;
                                end else begin
                                    trigger_newcard <= 0;  // Deassert after one pulse
                                    // $display("player_score before: %d", player_score);
                                    player_score <= player_score + player_new_card_reg;
                                    // $display("player_score after: %d", player_score);
                                end
                                bj_game_state <= DEALER_CARD_PHASE;
                            end
                        end else begin
                            // if not bust, go to the dealer phase 
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
                        end else begin
                            trigger_newcard <= 0;  // Deassert after one pulse
                            // $display("dealer_score before: %d", dealer_score);
                            dealer_score <= dealer_hand[1] + dealer_hand[2];
                            // $display("dealer_score after: %d", dealer_score);
                        end
                        // reveal one of the cards
                        if (next) begin
                            bj_game_state <= PLAYER_CARD_PHASE;
                            first_turn = 1'b0;
                        end
                    end 
                    // after player stands
                    else if (!first_turn && dealer_score < 17) begin
                        if (!newcard_pulse) begin
                            trigger_newcard <= 1;
                            dealer_new_card_reg <= card1;   
                            dealer_hand[j] <= dealer_new_card_reg;  
                        end else begin
                            trigger_newcard <= 0;
                            dealer_score <= dealer_score + dealer_new_card_reg; 
                        end
                        bj_game_state <= DEALER_CARD_PHASE;
                        j <= j + 1;
                    end
                    else begin
                        bj_game_state <= RESULT_PHASE;
                    end
                end

                RESULT_PHASE: begin
                    if(split_score==0) begin
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
                    end
                    else begin
                    
                    lose_p <= ((player_score < dealer_score && dealer_score <= 21) || player_score > 21);
                    lose_s <= ((split_score < dealer_score && dealer_score <= 21) || split_score > 21);
                    win_p <= ((player_score > dealer_score && player_score <= 21) || dealer_score > 21);
                    win_s <= ((split_score > dealer_score && split_score <= 21) || dealer_score > 21);
                    draw_s <= !(lose_s || win_s); // 논리 NOT 사용
                    draw_p <= !(lose_s || win_p); // 논리 NOT 사용

                    if (lose_s&&lose_p) begin
                        win_reg  <= 1'b0;
                        lose_reg <= 1'b1;
                        draw_reg <= 1'b0;
                        $display("you lose");
                    end 
                    else if (win_s&&win_p) begin
                        win_reg  <= 1'b1;
                        lose_reg <= 1'b0;
                        draw_reg <= 1'b0;
                        $display("you win!");
                    end 
                    else if(draw_s&&draw_p) begin
                        win_reg  <= 1'b0;
                        lose_reg <= 1'b0;
                        draw_reg <= 1'b1;
                        $display("draw");
                    
                    end
                     else if(lose_p&&draw_s||lose_s&&draw_p) begin
                        win_reg  <= 1'b0;
                        lose_reg <= 1'b1;
                        draw_reg <= 1'b1;
                        $display("draw");
                    end    
                    else if(lose_s&&win_p||win_s&&lose_p)begin
                        win_reg  <= 1'b1;
                        lose_reg <= 1'b1;
                        draw_reg <= 1'b0;
                        $display("draw");
                    end
                    else if(draw_p&&win_s||draw_s&&win_p)begin
                        win_reg  <= 1'b1;
                        lose_reg <= 1'b0;
                        draw_reg <= 1'b1;
                        $display("draw");
                    end
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
    assign split_can = split_complete;

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

            if (double) begin
                bet_amount <= bet_amount * 2;
                current_coin_reg <= current_coin_reg - bet_amount;
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