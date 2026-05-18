module W_machine #(
    parameter WORDSIZE = 32
) (
    input                       clk_i,
    input  [WORDSIZE*16-1:0]    M_i,
    input                       M_valid_i,
    input  [WORDSIZE-1:0]       sigma0_Wtm15_i, sigma1_Wtm2_i,

    output [WORDSIZE-1:0]       W_tm2_o, W_tm15_o,
    output [WORDSIZE-1:0]       W_o
);
    wire [WORDSIZE-1:0]     W_tm7_w;
    wire [WORDSIZE-1:0]     W_tm16_w;
    wire [WORDSIZE-1:0]     Wt_next;
    reg  [WORDSIZE*16-1:0]  W_stack_q;
    wire [WORDSIZE*16-1:0]  W_stack_d;
    // W(t-n) values, from the perspective of Wt_next
    assign W_tm2_o  = W_stack_q[WORDSIZE*2-1:WORDSIZE*1];
    assign W_tm15_o = W_stack_q[WORDSIZE*15-1:WORDSIZE*14];
    assign W_tm7_w  = W_stack_q[WORDSIZE*7-1:WORDSIZE*6];
    assign W_tm16_w = W_stack_q[WORDSIZE*16-1:WORDSIZE*15];
    // Wt_next is the next Wt to be pushed to the queue, will be consumed in 16 rounds
    assign Wt_next = sigma1_Wtm2_i + W_tm7_w + sigma0_Wtm15_i + W_tm16_w;
    assign W_stack_d = {W_stack_q[WORDSIZE*15-1:0], Wt_next};
    assign W_o = W_stack_q[WORDSIZE*16-1:WORDSIZE*15];

    always @(posedge clk_i) begin
        if (M_valid_i) begin
            W_stack_q <= M_i;
        end else begin
            W_stack_q <= W_stack_d;
        end
    end


endmodule