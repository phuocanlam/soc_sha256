// round compression function
module compression_round (
    input  [31:0] Kj_i, Wj_i,
    input  [31:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in,
    output [31:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out
);

    wire [31:0] Ch_e_f_g_w, Maj_a_b_c_w, S0_a_w, S1_e_w;

    Ch #(.WORD_WIDTH(32)) Ch (
        .x_i(e_in),
        .y_i(f_in),
        .z_i(g_in),
        .Ch_o(Ch_e_f_g_w)
    );

    Maj #(.WORD_WIDTH(32)) Maj (
        .x_i(a_in),
        .y_i(b_in),
        .z_i(c_in),
        .Maj_o(Maj_a_b_c_w)
    );

    compress_sigma0 S0 (
        .x_i(a_in),
        .S0_o(S0_a_w)
    );

    compress_sigma1 S1 (
        .x_i(e_in),
        .S1_o(S1_e_w)
    );

    compression #(.WORD_WIDTH(32)) compression (
        .Kj_i(Kj_i), .Wj_i(Wj_i),
        .a_in(a_in), .b_in(b_in), .c_in(c_in), .d_in(d_in),
        .e_in(e_in), .f_in(f_in), .g_in(g_in), .h_in(h_in),
        .Ch_e_f_g(Ch_e_f_g_w), .Maj_a_b_c(Maj_a_b_c_w), .S0_a(S0_a_w), .S1_e(S1_e_w),
        .a_out(a_out), .b_out(b_out), .c_out(c_out), .d_out(d_out),
        .e_out(e_out), .f_out(f_out), .g_out(g_out), .h_out(h_out)
    );

endmodule