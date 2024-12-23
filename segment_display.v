`timescale 1ns / 1ps

// fpga4student.com: FPGA projects, Verilog projects, VHDL projects
// FPGA tutorial: seven-segment LED display controller on Basys  3 FPGA
module segment_display(
    input clk, // 100 Mhz clock source on Basys 3 FPGA
    // Buttons
    input reset,
    input next,
    input hit,
    input stand,
    input double,
    // Switches
    input split,   
    input bet_8,
    input bet_4,   
    input bet_2,
    input bet_1,
    // Outputs
    output [3:0] Anode_Activate, // anode signals of the 7-segment LED display
    output [6:0] LED_out,// cathode patterns of the 7-segment LED display
    output LED_split,
    output LED_Win,
    output LED_Lose,
    output LED_Draw
    );
    
    integer onesDigit = 0;
    integer twosDigit = 0;
    integer threesDigit = 0;
    integer foursDigit = 0;
    integer refresh_counter = 0;
    integer LED_activating_counter = 0;
    
    reg [3:0] Anode_Activate_Var;
    reg [6:0] LED_out_Var;
    reg [3:0] LED_BCD;
    reg LED_split_Var;
    reg LED_Win_Var;
    reg LED_Lose_Var;
    reg LED_Draw_Var;
    
    integer total_bet;
    
    localparam D0 = 4'b0000, // "0"     
               D1 = 4'b0001, // "1" 
               D2 = 4'b0010, // "2" 
               D3 = 4'b0011, // "3" 
               D4 = 4'b0100, // "4" 
               D5 = 4'b0101, // "5" 
               D6 = 4'b0110, // "6" 
               D7 = 4'b0111, // "7" 
               D8 = 4'b1000, // "8"     
               D9 = 4'b1001, // "9" 
               Db = 4'b1010, // "b"
               Dd = 4'b1011, // "d"
               DA = 4'b1100, // "A"
               DN = 4'b1101; // None 

    wire [5:0] player_current_score, player_new_card, player_current_score_split, player_new_card_split; 
    wire [5:0] dealer_new_card, dealer_current_score;
    wire [4:0] current_coin;
    reg [5:0] player_hand1, player_hand2;
    wire can_split, Win, Lose, Draw;


    reg bet_in;
    reg dealer_reveal_in, player_state_in, dealer_state_in;

    //-----------------------------------------
    //       Button input pulse
    //-----------------------------------------
     // Wires for debounced button signals
    wire db_next, db_hit, db_stand, db_double, db_reset;

    // Instantiate debouncers for each button
    debouncer db_next_inst (
        .input_sig(next),
        .clk(clk),
        .output_sig(db_next)
    );

    debouncer db_hit_inst (
        .input_sig(hit),
        .clk(clk),
        .output_sig(db_hit)
    );

    debouncer db_stand_inst (
        .input_sig(stand),
        .clk(clk),
        .output_sig(db_stand)
    );

    debouncer db_double_inst (
        .input_sig(double),
        .clk(clk),
        .output_sig(db_double)
    );

    debouncer db_reset_inst (
        .input_sig(reset),
        .clk(clk),
        .output_sig(db_reset)
    );

    // Pulse generation registers
    reg db_next_d, db_hit_d, db_stand_d, db_double_d, db_reset_d;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all registers and pulses
            db_next_d   <= 0; db_hit_d   <= 0;
            db_stand_d  <= 0; db_double_d <= 0;
            db_reset_d  <= 0;
            nxt_pulse   <= 0; hit_pulse   <= 0;
            stand_pulse <= 0; double_pulse <= 0;
            rst_pulse <= 0;
        end else begin
            // Capture the previous state of debounced signals
            db_next_d   <= db_next;
            db_hit_d    <= db_hit;
            db_stand_d  <= db_stand;
            db_double_d <= db_double;
            db_reset_d  <= db_reset;

            // Generate pulses on rising edge of debounced signals
            nxt_pulse   <= db_next && ~db_next_d;
            hit_pulse   <= db_hit && ~db_hit_d;
            stand_pulse <= db_stand && ~db_stand_d;
            double_pulse <= db_double && ~db_double_d;
            rst_pulse <= db_reset && ~db_reset_d;
        end
    end
  
               
    ///////////////////////////////////////////////////////////////////////////////////////////
    // TODO: Instantiate your top module top.v here so that it works correctly
    top uut (
        .clk(clk),
        .reset(rst_pulse),
        .next(next_pulse),
        .hit(hit_pulse),
        .stand(stand_pulse),
        .double(double_pulse),
        .split(split),
        .bet_8(bet_8),
        .bet_4(bet_4),
        .bet_2(bet_2),
        .bet_1(bet_1),
        .player_current_score(player_current_score),
        .player_new_card(player_new_card),
        .dealer_new_card(dealer_new_card),
        .player_current_score_split(player_current_score_split),
        .player_new_card_split(player_new_card_split),
        .dealer_current_score(dealer_current_score),
        .current_coin(current_coin),
        .player_hand1_out(player_hand1),
        .player_hand2_out(player_hand2),
        .can_split(can_split),
        .Win(Win),
        .Lose(Lose),
        .Draw(Draw)
    );

    // Activate LEDs (TODO)
    always @(posedge(clk)) begin
        if (split) LED_split_Var = 1;
        else LED_split_Var = 0;

        if (Win) LED_Win_Var = 1;
        else LED_Win_Var = 0;

        if (Lose) LED_Lose_Var = 1;
        else LED_Lose_Var = 0;

        if (Draw) LED_Draw_Var = 1;
        else LED_Draw_Var = 0;
    end

    reg bet_fin;
    // Declare the digits for display (TODO)
    always @(posedge(clk)) begin
        if (rst_pulse) begin
            onesDigit = D0;
            twosDigit = D3;
            threesDigit = DN;
            foursDigit = Db;
            bet_fin <= 0;

            //my signals
            bet_in <= 0;
            dealer_reveal_in <= 0;
            player_state_in <= 0;
            dealer_state_in <= 0;
        end
        // betting phase
        else begin
            // betting phase
            if (!bet_fin) begin
                total_bet <= (bet_8<<3) | (bet_4<<2) | (bet_2<<2) | (bet_1<<1);
                if (total_bet > 0) begin
                    bet_fin <= 1;
                end
            end
            else if (total_bet > 0 && next_pulse) begin
                bet_in <= 1;
            end
            // start the game if bet is set
            if (bet_in) begin
                dealer_reveal_in <= 1;
                if (bet_in && dealer_reveal_in) begin
                    bet_in <= 0;
                    onesDigit = dealer_new_card % 10;
                    twosDigit = dealer_new_card / 10;
                    threesDigit = DN;
                    foursDigit = Dd;
                end
            end else begin
                if (dealer_reveal_in && foursDigit == Dd) begin
                    if (next_pulse) begin
                        dealer_reveal_in <= 0;
                        // if not result phase, go to the player phase
                        if (!Win && !Lose && !Draw) begin
                            player_state_in <= 1;
                            onesDigit = player_hand2 % 10;
                            twosDigit = player_hand2 / 10;
                            threesDigit = player_hand1 % 10;
                            foursDigit = player_hand1 / 10;
                    end
                end
                else if (player_state_in) begin
                    if (hit_pulse) begin
                        // hand msb detect logic needed!
                        onesDigit = player_new_card % 10;
                        twosDigit = player_new_card / 10;
                        threesDigit = player_current_score % 10;
                        foursDigit = player_current_score / 10;
                        // if not bust, go to dealer_state
                        if (next_pulse) begin
                            player_state_in <= 0;
                            dealer_state_in <= 1;
                        end
                    end
                    else if (double_pulse) begin
                        onesDigit = player_new_card % 10;
                        twosDigit = player_new_card / 10;
                        threesDigit = player_current_score % 10;
                        foursDigit = player_current_score / 10;
                        // if not bust, go to dealer_state
                        if (next_pulse) begin
                            player_state_in <= 0;
                            dealer_state_in <= 1;
                            onesDigit = dealer_current_score % 10;
                            twosDigit = dealer_current_score / 10;
                            threesDigit = DN;
                            foursDigit = Dd;
                        end
                    end
                end
                else if (dealer_state_in) begin
                    onesDigit = dealer_current_score % 10;
                    twosDigit = dealer_current_score / 10;
                    threesDigit = DN;
                    foursDigit = Dd;
                end
            end
        end
    end    
    end
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////
    // You don't have to change it down here
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    // Activate one of four 7-seg displays 
    always @(posedge(clk))
    begin 
        refresh_counter = refresh_counter + 1;      //increment counter
        if(refresh_counter == 5000)                 //at 500
            LED_activating_counter = 0;             //light onesDigit
        if(refresh_counter == 10000)                //at 1,000
            LED_activating_counter = 1;             //light twosDigit
        if(refresh_counter == 15000)                //at 1,500
            LED_activating_counter = 2;             //light threesDigit
        if(refresh_counter == 20000)                //at 20,000
            LED_activating_counter = 3;             //light foursDigit
        if(refresh_counter == 25000)                //at 25,000
            refresh_counter = 0;                    //start over at 0
    end


    always @(LED_activating_counter, foursDigit, threesDigit, twosDigit, onesDigit)                    //when 7-seg digit changes
    begin
        //LED_activating_counter = refresh_counter;
        case(LED_activating_counter)                    //activate the digit
            0: begin
                Anode_Activate_Var = 4'b0111;           //activate LED1 and Deactivate LED2, LED3, LED4
                LED_BCD = foursDigit;                   //the first digit of the 16-bit number
            end
            1: begin
                Anode_Activate_Var = 4'b1011;           //activate LED2 and Deactivate LED1, LED3, LED4
                LED_BCD = threesDigit;                  //the second digit of the 16-bit number
            end
            2: begin
                Anode_Activate_Var = 4'b1101;           // activate LED3 and Deactivate LED2, LED1, LED4
                LED_BCD = twosDigit;                    // the third digit of the 16-bit number
            end
            3: begin
                Anode_Activate_Var = 4'b1110;           // activate LED4 and Deactivate LED2, LED3, LED1
                LED_BCD = onesDigit;                    // the fourth digit of the 16-bit number 
            end
        endcase
    end


    always @(LED_BCD)
    begin
        case(LED_BCD)
            4'b0000: LED_out_Var = 7'b0000001; // "0"     
            4'b0001: LED_out_Var = 7'b1001111; // "1" 
            4'b0010: LED_out_Var = 7'b0010010; // "2" 
            4'b0011: LED_out_Var = 7'b0000110; // "3" 
            4'b0100: LED_out_Var = 7'b1001100; // "4" 
            4'b0101: LED_out_Var = 7'b0100100; // "5" 
            4'b0110: LED_out_Var = 7'b0100000; // "6" 
            4'b0111: LED_out_Var = 7'b0001111; // "7" 
            4'b1000: LED_out_Var = 7'b0000000; // "8"     
            4'b1001: LED_out_Var = 7'b0000100; // "9" 
            4'b1010: LED_out_Var = 7'b1100000; // "b"
            4'b1011: LED_out_Var = 7'b1000010; // "d"
            4'b1100: LED_out_Var = 7'b0001000; // "A"
            4'b1101: LED_out_Var = 7'b1111111; // None
            default: LED_out_Var = 7'b0000001; // "0"
        endcase
    end

    assign Anode_Activate = Anode_Activate_Var;
    assign LED_out = LED_out_Var;
    assign LED_split = LED_split_Var;
    assign LED_Win = LED_Win_Var;
    assign LED_Lose = LED_Lose_Var;
    assign LED_Draw = LED_Draw_Var;
    
 endmodule