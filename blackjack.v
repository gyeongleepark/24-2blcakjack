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
    wire [3:0] card1, card2, card3, card4, card_value;

    reg [5:0] player_hand [1:4];
    reg [5:0] dealer_hand [1:4];
    reg [5:0] split_hand [1:4];   // 이 아래 세 줄 추가함
    reg [1:0] hand_count;
    reg [3:0] player_card_count, dealer_card_count, split_card_count;

    reg [3:0] split_card1, split_card2;
    reg [5:0] bet_amount;
    reg [4:0] initial_coin = 5'd30;
 
    reg [5:0] player_new_card_reg;
    //reg [5:0] player_current_score_split_reg; 
    reg [5:0] player_new_card_split_reg;
    reg [4:0] current_coin_reg;

    reg win_reg;
    reg lose_reg;
    reg draw_reg;

    reg split_can;       // 처음 card1 = card2
    reg split_active;    // split 한 적 없으면 1 있으면 0
    reg split_complete;  // split 함
    reg first_turn;

    reg blackjack_win;

    reg [5:0] player_score;
    reg [5:0] dealer_score;
    reg [5:0] split_score;  // 추가
    // player_score가 int라서 이전 state를 불러올 수 없는듯

    function [7:0] calculate_score_with_ace;
        input [5:0] card1, card2, card3, card4;  // 최대 4개의 카드 입력
        input [3:0] card_count;   // 카드 개수
        integer i;                // Loop index
        reg [7:0] score;          // 점수 계산용
        reg [3:0] ace_count;      // Ace 개수 추적
        reg [5:0] cards [1:4];                  // 지역 배열

        begin
            score = 0;
            ace_count = 0;

            // 배열 초기화
            cards[1] = card1;
            cards[2] = card2;
            cards[3] = card3;
            cards[4] = card4;

            // 모든 카드 순회
            for (i = 1; i <= card_count; i = i + 1) begin
                if (cards[i] == 6'd1) begin
                    ace_count = ace_count + 1;   // Ace 발견 시 개수 증가
                end
                score = score + cards[i];         // 기본 점수 계산
            end

            // Ace를 11로 계산할 수 있는 경우 처리
            if (ace_count > 0) begin
                // 한 개의 Ace를 11로 계산하고 나머지는 1로 계산
                if ((score + 10) <= 21) begin
                    score = score + 10;  // 첫 번째 Ace는 11로 계산
                    ace_count = ace_count - 1;
                end

                // 추가 Ace는 모두 1로 계산
                score = score + ace_count;  // 남은 Ace는 1씩 추가
            end

            calculate_score_with_ace = score;
        end
    endfunction    


    // Card generation instance
    card_generation u_card (
        .clk(clk),
        .reset(reset),
        .on(1'b1),
        .test(3'b001),
        .card1_out(card1),
        .card2_out(card2),
        .card3_out(card3),
        .card4_out(card4)
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
            player_score <= 0;
            dealer_score <= 0;
            split_score <= 0;
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
            split_active <= 1;  // 여길 바꿈  
            split_complete <= 0;
            split_can <= 0;
            first_turn <= 1;
            blackjack_win <= 0;

            player_hand[1] <= 6'd0;
            player_hand[2] <= 6'd0;
            player_hand[3] <= 6'd0;
            player_hand[4] <= 6'd0;

            dealer_hand[1] <= 6'd0;
            dealer_hand[2] <= 6'd0;
            dealer_hand[3] <= 6'd0;
            dealer_hand[4] <= 6'd0;

            split_hand[1] <= 6'd0;
            split_hand[2] <= 6'd0;
            split_hand[3] <= 6'd0;
            split_hand[4] <= 6'd0;

        end else begin
            case (bj_game_state)
                BETTING_PHASE: begin
                    current_coin_reg <= initial_coin;
                    player_hand[1] <= card1;
                    player_hand[2] <= card2;
                    player_card_count <= 4'd2;    // 이거 추가함
                    player_score <= calculate_score_with_ace(player_hand[1], player_hand[2], player_hand[3], player_hand[4], player_card_count);   // 이거 함수로 바꿈
                    dealer_hand[1] <= card3;
                    dealer_hand[2] <= card4;
                    dealer_card_count <= 4'd2;    // 이것도
                    dealer_score <= dealer_hand[1] + dealer_hand[2];
                    
                    /*if (player_hand[1] == 6'd1) begin
                        player_score <= player_hand[1] + player_hand[2] + 10;
                    end else if (player_hand[2] == 6'd1) begin
                        player_score <= player_hand[1] + player_hand[2] + 10;
                    end    // Ace

                    if (bet_amount > 0 & next) begin
                        bj_game_state <= DEALER_CARD_PHASE;
                    end*/
                end

                PLAYER_CARD_PHASE: begin
                    if (player_score >= 21) begin
                        bj_game_state <= RESULT_PHASE;
                    end 
                    else begin
                        if (!stand && dealer_score < 17) begin
                            if (player_hand[1] == player_hand[2] && split_active) begin  // 얘 추가함
                                split_can <= 1;
                            end
                            if (split_can && split) begin    // 얘는 active 여야할듯
                                hand_count <= 2;
                                split_hand[1] <= player_hand[2];
                                player_card_count <= 1;
                                split_card_count <= 1;
                                player_score <= calculate_score_with_ace(player_hand[1], player_hand[2], player_hand[3], player_hand[4], player_card_count);
                                split_score <= calculate_score_with_ace(split_hand[1], split_hand[2], split_hand[3], split_hand[4], split_card_count);
                                split_active <= 0;
                                split_complete <= 1;
                            end 
                            else if (hit) begin
                                if (!split_complete) begin
                                    player_new_card_reg <= card1;
                                    if (player_card_count == 4'd2) begin
                                        player_card_count <= 4'd3;    // ace 계산 추가해야함
                                    end
                                    else if (player_card_count == 4'd3) begin
                                        player_card_count <= 4'd4;
                                    end
                                    player_hand[player_card_count] <= card1;
                                    player_score <= calculate_score_with_ace(player_hand[1], player_hand[2], player_hand[3], player_hand[4], player_card_count);
                                    bj_game_state <= PLAYER_CARD_PHASE;
                                end else begin
                                    player_new_card_split_reg <= card2;
                                    split_score <= split_score + card2;
                                end
                            end 
                            else if (double) begin
                                if (!split_complete) begin
                                    current_coin_reg <= current_coin - bet_amount;  // 돈 부족한 경우는 아직 처리 안 함
                                    bet_amount <= 2 * bet_amount;
                                    player_new_card_reg <= card1;
                                    player_card_count <= player_card_count + 1;    // ace 계산 추가해야함
                                    player_hand[player_card_count] <= player_new_card_reg;
                                    player_score <= calculate_score_with_ace(player_hand[1], player_hand[2], player_hand[3], player_hand[4], player_card_count);
                                    bj_game_state <= DEALER_CARD_PHASE;
                                end else begin
                                    
                                end
                            end
                            else if (stand) begin
                                if (!split_complete) begin
                                    if (dealer_score >= 17) begin
                                        bj_game_state <= RESULT_PHASE;
                                    end else begin
                                        bj_game_state <= DEALER_CARD_PHASE;
                                    end
                                end else begin
                                    
                                end
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
                            if (dealer_score >= 21) begin    // 이거 수정함
                                bj_game_state <= RESULT_PHASE;
                            end else begin
                                bj_game_state <= PLAYER_CARD_PHASE;
                            end
                            first_turn = 1'b0;
                        end
                    end 
                    else if (!first_turn && dealer_score < 17) begin
                        dealer_score <= dealer_score + card1;
                        bj_game_state <= DEALER_CARD_PHASE;   //  이거 수정함
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
    assign player_current_score_split = split_score;
    assign player_new_card = player_new_card_reg;
    assign player_new_card_split = player_new_card_split_reg;
    assign current_coin = current_coin_reg;
    assign can_split = split_can;

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