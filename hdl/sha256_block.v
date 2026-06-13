module sha256_block (
    input           clk_i,
    input           rstn_i,
    //
    input  [511:0]  M_i,
    input           M_valid_i,
    //
    output [255:0]  Hash_o,
    output          Hash_valid_o 
);

    //==============================================================//
    // Parameters                                                   //
    //==============================================================//
    localparam H0_INIT = 32'h6a09e667;
    localparam H1_INIT = 32'hbb67ae85;
    localparam H2_INIT = 32'h3c6ef372;
    localparam H3_INIT = 32'ha54ff53a;
    localparam H4_INIT = 32'h510e527f;
    localparam H5_INIT = 32'h9b05688c;
    localparam H6_INIT = 32'h1f83d9ab;
    localparam H7_INIT = 32'h5be0cd19;

    //==============================================================//
    // Wire Declaration                                             //
    //==============================================================//
    wire [31:0]     Wtm2_w, sig0_Wtm15_w, sig1_Wtm2_w, Wtm15_w;
    wire [31:0]     Wj_w, Kj_w;
    wire [31:0]     a_d_w, b_d_w, c_d_w, d_d_w, e_d_w, f_d_w, g_d_w, h_d_w;

    //==============================================================//
    // Register Declaration                                         //
    //==============================================================//
    reg  [6:0]      round_r;
    reg  [31:0]     a_q_r, b_q_r, c_q_r, d_q_r, e_q_r, f_q_r, g_q_r, h_q_r;

    //==============================================================//
    // Instantiate Message Expandsion                               //
    //==============================================================//
    message_expansion #(.WORD_WIDTH(32)) ME_unit (
        .clk_i(clk_i),
        .M_i(M_i),
        .M_valid_i(M_valid_i),
        .sig1_Wtm2_i(sig1_Wtm2_w),
        .sig0_Wtm15_i(sig0_Wtm15_w),
        .Wtm2_o(Wtm2_w),
        .Wtm15_o(Wtm15_w),
        .W_o(Wj_w)
    );

    ME_sigma0 ME_sigma0_u (.x_i(Wtm15_w), .sigma0_o(sig0_Wtm15_w));
    ME_sigma1 ME_sigma1_u (.x_i(Wtm2_w),  .sigma1_o(sig1_Wtm2_w));

    //==============================================================//
    // Instantiate K Constant                                       //
    //==============================================================//
    K_const K_const (
        .clk_i(clk_i),
        .rst_i(M_valid_i),
        .K_o(Kj_w)
    );

    compression_round compression_round (
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

    always @(posedge clk_i) begin
        if (M_valid_i) begin
            a_q_r   <= H0_INIT;
            b_q_r   <= H1_INIT;
            c_q_r   <= H2_INIT;
            d_q_r   <= H3_INIT;
            e_q_r   <= H4_INIT;
            f_q_r   <= H5_INIT;
            g_q_r   <= H6_INIT;
            h_q_r   <= H7_INIT;
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

    //==============================================================//
    // Output                                                       //
    //==============================================================//
    assign Hash_valid_o = round_r == 64;
    assign Hash_o = {
        H0_INIT + a_q_r,
        H1_INIT + b_q_r,
        H2_INIT + c_q_r,
        H3_INIT + d_q_r,
        H4_INIT + e_q_r,
        H5_INIT + f_q_r,
        H6_INIT + g_q_r,
        H7_INIT + h_q_r
    };

endmodule