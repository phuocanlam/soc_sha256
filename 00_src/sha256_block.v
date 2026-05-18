module sha256_block (
    input           clk_i,
    input           rst_ni,
    input  [255:0]  H_in,
    input  [511:0]  M_in,
    input           valid_i,
    
    output [255:0]  H_out,
    output          valid_o
);
    reg  [6:0]      round_r;
    reg  [31:0]     a_q_r, b_q_r, c_q_r, d_q_r, e_q_r, f_q_r, g_q_r, h_q_r;
    wire [31:0]     a_d_w, b_d_w, c_d_w, d_d_w, e_d_w, f_d_w, g_d_w, h_d_w;
    wire [31:0]     a_in_w;
    wire [31:0]     b_in_w;
    wire [31:0]     c_in_w;
    wire [31:0]     d_in_w;
    wire [31:0]     e_in_w;
    wire [31:0]     f_in_w;
    wire [31:0]     g_in_w;
    wire [31:0]     h_in_w;
    wire [31:0]     W_tm2_w, W_tm15_w, s1_Wtm2_w, s0_Wtm15_w, Wj_w, Kj_w;

    assign a_in_w = H_in[255:224];
    assign b_in_w = H_in[223:192];
    assign c_in_w = H_in[191:160];
    assign d_in_w = H_in[159:128];
    assign e_in_w = H_in[127:96];
    assign f_in_w = H_in[95:64];
    assign g_in_w = H_in[63:32];
    assign h_in_w = H_in[31:0];

    assign valid_o = round_r == 64;
    assign H_out = {
        a_in_w + a_q_r,
        b_in_w + b_q_r,
        c_in_w + c_q_r,
        d_in_w + d_q_r,
        e_in_w + e_q_r,
        f_in_w + f_q_r,
        g_in_w + g_q_r,
        h_in_w + h_q_r
    };

    always @(posedge clk_i)
        begin
            if (valid_i) begin
                a_q_r   <= a_in_w;
                b_q_r   <= b_in_w;
                c_q_r   <= c_in_w;
                d_q_r   <= d_in_w;
                e_q_r   <= e_in_w;
                f_q_r   <= f_in_w;
                g_q_r   <= g_in_w;
                h_q_r   <= h_in_w;
                round_r <= 0;
            end else begin
                a_q_r   <= a_d_w;
                b_q_r   <= b_d_w;
                c_q_r   <= c_d_w;
                d_q_r   <= d_d_w;
                e_q_r   <= e_d_w;
                f_q_r   <= f_d_w;
                g_q_r   <= g_d_w;
                h_q_r   <= h_d_w;
                round_r <= round_r + 1'b1;
            end
        end

    sha256_round sha256_round (
        .Kj_i(Kj_w),
        .Wj_i(Wj_w),

        .a_in(a_q_r),
        .b_in(b_q_r), 
        .c_in(c_q_r),
        .d_in(d_q_r), 
        .e_in(e_q_r), 
        .f_in(f_q_r), 
        .g_in(g_q_r), 
        .h_in(h_q_r),

        .a_out(a_d_w), 
        .b_out(b_d_w), 
        .c_out(c_d_w), 
        .d_out(d_d_w), 
        .e_out(e_d_w), 
        .f_out(f_d_w), 
        .g_out(g_d_w), 
        .h_out(h_d_w)
    );

    sha256_sigma0 sha256_sigma0 (.x_i(W_tm15_w), .sigma0_o(s0_Wtm15_w));
    sha256_sigma1 sha256_sigma1 (.x_i(W_tm2_w), .sigma1_o(s1_Wtm2_w));

    W_machine #(.WORDSIZE(32)) W_machine (
        .clk_i(clk_i),
        .M_i(M_in),
        .M_valid_i(valid_i),
        .sigma1_Wtm2_i(s1_Wtm2_w),
        .sigma0_Wtm15_i(s0_Wtm15_w),
        .W_tm2_o(W_tm2_w),
        .W_tm15_o(W_tm15_w),
        .W_o(Wj_w)
    );

    sha256_K_machine sha256_K_machine (
        .clk_i(clk_i),
        .rst_i(valid_i),
        .K_o(Kj_w)
    );

endmodule   