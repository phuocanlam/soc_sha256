module message_expansion #(
    parameter WORD_WIDTH = 32
) (
    input                       clk_i,
    input  [WORD_WIDTH*16-1:0]  M_i,
    input                       M_valid_i,
    input  [WORD_WIDTH-1:0]     sig0_Wtm15_i,    // W(t) - 15
    input  [WORD_WIDTH-1:0]     sig1_Wtm2_i,     // W(t) - 2

    output [WORD_WIDTH-1:0]     Wtm2_o,
    output [WORD_WIDTH-1:0]     Wtm15_o,
    output [WORD_WIDTH-1:0]     W_o
);
    //==============================================================//
    // Register Declaration                                         //
    //==============================================================//
    reg  [WORD_WIDTH*16-1:0]      W_stack_q;

    //==============================================================//
    // Wire Declaration                                             //
    //==============================================================//
    wire [WORD_WIDTH*16-1:0]      W_stack_d;
    wire [WORD_WIDTH-1:0]         Wtm7_w;
    wire [WORD_WIDTH-1:0]         Wtm16_w;
    wire [WORD_WIDTH-1:0]         Wt_next;

    //==============================================================//
    //                                                              //
    //==============================================================//
    always @(posedge clk_i) begin
        if (M_valid_i) begin
            W_stack_q <= M_i;
        end else begin
            W_stack_q <= W_stack_d;
        end
    end

    //==============================================================//
    // W(t-n) values, from the perspective of Wt_next               //
    //==============================================================//
    assign Wtm2_o  = W_stack_q[WORD_WIDTH*2-1:WORD_WIDTH*1];
    assign Wtm15_o = W_stack_q[WORD_WIDTH*15-1:WORD_WIDTH*14];
    assign Wtm7_w  = W_stack_q[WORD_WIDTH*7-1:WORD_WIDTH*6];
    assign Wtm16_w = W_stack_q[WORD_WIDTH*16-1:WORD_WIDTH*15];

    //==============================================================//
    // Wt_next is the next Wt to be pushed to the queue,            //
    // will be consumed in 16 rounds                                //
    //==============================================================//
    assign Wt_next   = sig1_Wtm2_i + Wtm7_w + sig0_Wtm15_i + Wtm16_w;
    assign W_stack_d = {W_stack_q[WORD_WIDTH*15-1:0], Wt_next};
    assign W_o       = W_stack_q[WORD_WIDTH*16-1:WORD_WIDTH*15];

endmodule