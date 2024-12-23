module deck(
    input clk,
    input reset,
    input [1:0] num, // Changed to 2 bits for clarity
    output reg [3:0] card1,
    output reg [3:0] card2
);

    wire [3:0] gen_card1;
    wire [3:0] gen_card2;
    reg newcard_pulse;

    // Card generation instance
    card_generation u_card (
        .clk(clk),
        .reset(reset),
        .on(newcard_pulse),
        .test(3'b000),
        .card1_out(gen_card1),
        .card2_out(gen_card2)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            card1 <= 4'd0;
            card2 <= 4'd0;
            newcard_pulse <= 1'b0;
        end else begin
            // Generate a new card on every clock cycle (pulse-based)
            if (newcard_pulse) begin
                newcard_pulse <= 1'b0; // Reset pulse after one cycle
            end else begin
                newcard_pulse <= 1'b1; // Set pulse for card generation
            end

            // Update card outputs based on `num`
            if (num == 2'b01) begin
                card1 <= gen_card1;
                card2 <= 4'd0; // Clear card2 when only one card is generated
            end else if (num == 2'b10) begin
                card1 <= gen_card1;
                card2 <= gen_card2; // Assign both cards when two are generated
            end else begin
                card1 <= 4'd0;
                card1 <= 4'd0;
            end
        end
    end
endmodule
