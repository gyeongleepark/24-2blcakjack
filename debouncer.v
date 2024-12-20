`timescale 1ns / 1ps
 
module debouncer(
    input input_sig,
    input clk,
    output output_sig
    );

wire slow_clk;
wire Q0, Q1, Q2, Q2_bar;
reg out_reg;

clock_div u1(clk,slow_clk);
dff d0(slow_clk, input_sig, Q0);
dff d1(slow_clk, Q0, Q1);
dff d2(slow_clk, Q1, Q2);

assign Q2_bar = ~Q2;

assign output_sig = out_reg;
always @(clk)
begin
    out_reg = Q1 & Q2;
end

assign output_sig = out_reg;

endmodule

// Slow clock
module clock_div(
    input clk,
    output slow_clk
    );

    reg [26:0] counter = 0;
    reg slow_clk_reg;
    always @(posedge(clk))
    begin
        counter <= (counter >= 350)?0:counter+1;
        slow_clk_reg <= (counter < 175)?1'b0:1'b1;
    end
    
    assign slow_clk = slow_clk_reg;
endmodule

// D Flip-Flop
module dff(
    input clk,
    input d,
    output q
    );

    reg q_reg;
    always @(clk)
    begin
        q_reg <= d;
    end
    
    assign q = q_reg;
endmodule