module debounce_better_version(
    input input_sig,clk,
    output output_sig
    );
    wire slow_clk_en;
    wire Q1,Q2,Q2_bar,Q0;
    clock_enable u1(clk,slow_clk_en);
    my_dff_en d0(clk,slow_clk_en,input_sig,Q0);

    my_dff_en d1(clk,slow_clk_en,Q0,Q1);
    my_dff_en d2(clk,slow_clk_en,Q1,Q2);
    assign Q2_bar = ~Q2;
    assign output_sig = Q1 & Q2_bar;
endmodule
// Slow clock enable for debouncing button 
module clock_enable(input Clk_100M,output slow_clk_en);
    reg [26:0]counter=0;
    always @(posedge Clk_100M)
    begin
       counter <= (counter>=100)?0:counter+1;
    end
    assign slow_clk_en = (counter == 50)?1'b1:1'b0;
endmodule
// D-flip-flop with clock enable signal for debouncing module 
module my_dff_en(input DFF_CLOCK, clock_enable,D, output reg Q=0);
    always @ (posedge DFF_CLOCK) begin
  if(clock_enable==1) 
           Q <= D;
    end
endmodule 