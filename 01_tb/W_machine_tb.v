module W_machine_tb ();
    parameter WORDSIZE = 32;
    reg clk_i;
    reg M_valid_i; 
    reg  [WORDSIZE*16-1:0]  M_i;
    wire [WORDSIZE-1:0]     W_tm2_o;
    wire [WORDSIZE-1:0]     W_tm15_o;
    wire [WORDSIZE-1:0]     W_o;
    reg  [WORDSIZE-1:0]     sigma0_Wtm15_i;
    reg  [WORDSIZE-1:0]     sigma1_Wtm2_i;

    W_machine #(.WORDSIZE(32)) W_machine_dut (
        .clk_i(clk_i),
        .M_i(M_i),
        .M_valid_i(M_valid_i),
        .W_tm2_o(W_tm2_o),
        .W_tm15_o(W_tm15_o),
        .sigma1_Wtm2_i(sigma1_Wtm2_i), 
        .sigma0_Wtm15_i(sigma0_Wtm15_i),
        .W_o(W_o)
    );

    always @(*) begin
        // Sigma0 cho W[t-15]. Trong thực tế bạn nên dùng module sha256_sigma0
        // Ở đây tôi gán hằng số để bạn kiểm tra kết quả W16
        if (i >= 15) 
            sigma0_Wtm15_i = 32'h1D7F313C; // Giá trị sigma0(W1)
        else
            sigma0_Wtm15_i = 0;
            
        sigma1_Wtm2_i = 0; // Tạm thời để 0 vì W14 = 0
    end

    // Clock 100MHz
    always #5 clk_i = ~clk_i;

    integer i = 0;
    initial begin
        clk_i = 0;
        M_valid_i = 0;
        sigma0_Wtm15_i = 0;
        sigma1_Wtm2_i = 0;

        // ============================
        // TEST 1: Load initial block
        // ============================
        // M = W0..W15 = 0..15
        M_i = {
            32'h70726f6a,   // Word index [00]   
            32'h65637466,   // Word index [01]
            32'h7067612e,   // Word index [02]
            32'h636f6d80,   // Word index [03]
            32'h00000000,   // Word index [04]
            32'h00000000,   // Word index [05]
            32'h00000000,   // Word index [06]
            32'h00000000,   // Word index [07]
            32'h00000000,   // Word index [08]
            32'h00000000,   // Word index [09]
            32'h00000000,   // Word index [10]
            32'h00000000,   // Word index [11]
            32'h00000000,   // Word index [12]
            32'h00000000,   // Word index [13]
            32'h00000000,   // Word index [14]
            32'h00000078    // Word index [15]
        };

        @(posedge clk_i);
        M_valid_i = 1;   // load 1 cycle

        @(posedge clk_i);
        M_valid_i = 0;

        $display("==== RUNNING SHA-256 W-MACHINE ====");
        for (i = 0; i < 64; i = i + 1) begin
            @(negedge clk_i); // Quan sát ở cạnh xuống để dữ liệu đã ổn định
            $display("Cycle %0d: W_o = %h", i, W_o);
        end

        $finish;
    end
endmodule
