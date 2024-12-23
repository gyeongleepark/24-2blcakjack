`timescale 1ns/1ps

module deck_tb;

    // Testbench signals
    reg clk;
    reg reset;
    reg num;
    wire [3:0] card1;
    wire [3:0] card2;

    // Instantiate the deck module
    deck uut (
        .clk(clk),
        .reset(reset),
        .num(num),
        .card1(card1),
        .card2(card2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        num = 0;

        // Display header
        $display("Time | Num | Card1 | Card2");
        $display("---------------------------");

        // Apply reset
        #10 reset = 0;

        // Generate a single card
        #10 num = 1;
        #20 $display("%4d |  %b  |   %d   |   %d", $time, num, card1, card2);

        // Generate two cards
        #10 num = 2;
        #20 $display("%4d |  %b  |   %d   |   %d", $time, num, card1, card2);

        // Generate single card again
        #10 num = 1;
        #20 $display("%4d |  %b  |   %d   |   %d", $time, num, card1, card2);

        // End simulation
        #50 $finish;
    end

    // Monitor outputs
    always @(posedge clk) begin
        if (!reset) begin
            $display("%4d |  %b  |   %d   |   %d", $time, num, card1, card2);
        end
    end

endmodule