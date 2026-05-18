// generalised round compression function
module sha2_round #(
    parameter WORDSIZE = 1
) (
    input  [WORDSIZE-1:0] Kj_i, Wj_i,
    input  [WORDSIZE-1:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in,
    input  [WORDSIZE-1:0] Ch_e_f_g, Maj_a_b_c, S0_a, S1_e,
    output [WORDSIZE-1:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out
);
    wire [WORDSIZE-1:0]     temp1_w;
    wire [WORDSIZE-1:0]     temp2_w;
    
    //temp1_w = h + S1 + ch + k[i] + w[i]
    //temp2_w = S0 + maj
    assign temp1_w = h_in + S1_e + Ch_e_f_g + Kj_i + Wj_i;
    assign temp2_w = S0_a + Maj_a_b_c;

    assign a_out = temp1_w + temp2_w;
    assign b_out = a_in;
    assign c_out = b_in;
    assign d_out = c_in;
    assign e_out = d_in + temp1_w;
    assign f_out = e_in;
    assign g_out = f_in;
    assign h_out = g_in;

endmodule