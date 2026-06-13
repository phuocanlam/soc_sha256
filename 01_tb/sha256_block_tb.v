//`timescale 1ns/1ps

module sha256_block_tb;

    //----------------------------------------
    // Signals
    //----------------------------------------
    reg         clk;
    reg         rst_n;
    reg  [511:0] M_in;
    reg         valid_i;

    wire [255:0] H_out;
    wire         valid_o;

    //----------------------------------------
    // DUT
    //----------------------------------------
    sha256_block dut (
        .clk_i       (clk),
        .rstn_i      (rst_n),
        .M_i         (M_in),
        .M_valid_i   (valid_i),
        .Hash_o      (H_out),
        .Hash_valid_o(valid_o)
    );

    //----------------------------------------
    // Clock: 100MHz
    //----------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //----------------------------------------
    // Task: reset
    //----------------------------------------
    task reset_dut();
    begin
        rst_n = 0;
        valid_i = 0;
        #20;
        rst_n = 1;
    end
    endtask

    /*
    //----------------------------------------
    // SHA-256 initial hash (H0)
    //----------------------------------------
    function [255:0] get_sha256_init();
        get_sha256_init = {
            32'h6a09e667,
            32'hbb67ae85,
            32'h3c6ef372,
            32'ha54ff53a,
            32'h510e527f,
            32'h9b05688c,
            32'h1f83d9ab,
            32'h5be0cd19
        };
    endfunction

    //----------------------------------------
    // Message block: "abc"
    //----------------------------------------
    function [511:0] get_msg_abc();
        get_msg_abc = {
            32'h61626380, // "abc" + padding bit
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000018  // length = 24 bits
        };
    endfunction
    */
    integer i = 0;
    //----------------------------------------
    // Stimulus
    //----------------------------------------
    initial begin
        $display("==== SHA256 BLOCK TEST START ====");

        reset_dut();

        //------------------------------------
        // Apply input
        //------------------------------------
        // @(posedge clk);
        // H_in    = get_sha256_init();
        // M_in    = get_msg_abc();
        // @(posedge clk);
        // M_in = {
        //     32'h70726f6a,   // Word index [00]   
        //     32'h65637466,   // Word index [01]
        //     32'h7067612e,   // Word index [02]
        //     32'h636f6d80,   // Word index [03]
        //     32'h00000000,   // Word index [04]
        //     32'h00000000,   // Word index [05]
        //     32'h00000000,   // Word index [06]
        //     32'h00000000,   // Word index [07]
        //     32'h00000000,   // Word index [08]
        //     32'h00000000,   // Word index [09]
        //     32'h00000000,   // Word index [10]
        //     32'h00000000,   // Word index [11]
        //     32'h00000000,   // Word index [12]
        //     32'h00000000,   // Word index [13]
        //     32'h00000000,   // Word index [14]
        //     32'h00000078    // Word index [15]
        // };

        M_in = {
            32'h48656C6C,   // Word index [00]   
            32'h6F20576F,   // Word index [01]
            32'h726C6421,   // Word index [02]
            32'h20497420,   // Word index [03]
            32'h69732053,   // Word index [04]
            32'h48413235,   // Word index [05]
            32'h36204861,   // Word index [06]
            32'h73682120,   // Word index [07]
            32'h50696E65,   // Word index [08]
            32'h6170706C,   // Word index [09]
            32'h6520616B,   // Word index [10]
            32'h61205068,   // Word index [11]
            32'h756F6320,   // Word index [12]
            32'h416E8000,   // Word index [13]
            32'h00000000,   // Word index [14]
            32'h000001B0    // Word index [15]
        };

        @(posedge clk);
        valid_i = 1;

        @(posedge clk);
        valid_i = 0;

        //------------------------------------
        // Wait for computation (~64 rounds)
        //------------------------------------
        repeat (64) @(posedge clk);
        $display("==== RUNNING SHA-256 W-MACHINE ====");
        // for (i = 0; i < 64; i = i + 1) begin
        //     @(negedge clk);
        //     $display("Cycle %0d: H_out = %h", i, H_out);
        // end
        //------------------------------------
        // Display result
        //------------------------------------
        $display("H_out    = %h", H_out);

        //------------------------------------
        // Expected SHA256("abc")
        //------------------------------------
        //e254720208ff333431f723cbe00b9c1d45fc65b7ac1650151a3d8eb0cbd885a3
        $display("Expected = ed878761fb060ed7c836149beeda722c3d0e5a7d6dc0cd6a3bd92a2d46a6f72f");

        $finish;
    end

    //----------------------------------------
    // Monitor
    //----------------------------------------
    initial begin
        $monitor("[%0t] valid_o=%b H_out=%h",
                 $time, valid_o, H_out);
    end

endmodule