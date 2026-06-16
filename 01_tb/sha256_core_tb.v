// `timescale 1ns/1ps

module sha256_core_tb;

    parameter   DATA_WIDTH              = 32;
    parameter   BUS_WA_WIDTH            = 6;
    parameter   BUS_RA_WIDTH            = 4;
    parameter   MSG_MEM_A_WIDTH         = 4;
    parameter   HASH_MEM_A_WIDTH        = 3;
    parameter   HASH_WIDTH              = 256;
    parameter   MSG_WIDTH               = 512;

    parameter   INPUT_MSG_WORDS         = 16;   // Message input is 512-bit format
    parameter   OUTPUT_HASH_WORDS       = 8;    // Hash output is 216-bit format

    reg                     CLK;
    reg                     RST;

    reg                     awvalid_i;
    reg  [BUS_WA_WIDTH-1:0]      waddr_i;
    reg  [DATA_WIDTH-1:0]   wdata_i;

    wire                    arvalid_i;
    wire [BUS_RA_WIDTH-1:0] raddr_i;
    wire [DATA_WIDTH-1:0]   rdata_o;

    reg [31:0] message_input_mem  [0:INPUT_MSG_WORDS-1];
    reg [31:0] hash256_golden_mem [0:OUTPUT_HASH_WORDS-1];

    integer tc;
    integer i;
    integer base_in;
    integer base_golden;
    integer pass_count;
    integer fail_count;

    reg [31:0] expected;
    reg [31:0] actual;

    // -------------------------------------------------
    // Registered read request signals in TB
    // -------------------------------------------------
    reg                     arvalid_req_r;
    reg [BUS_RA_WIDTH-1:0]  raddr_req_r;

    reg                     arvalid_ff_r;
    reg [BUS_RA_WIDTH-1:0]  raddr_ff_r;

    assign arvalid_i = arvalid_ff_r;
    assign raddr_i   = raddr_ff_r;

    localparam [BUS_WA_WIDTH-1:0] LOAD_FLAG_ADDR_BASE   = 6'd0;
    localparam [BUS_WA_WIDTH-1:0] START_FLAG_ADDR_BASE  = 6'd16;
    localparam [BUS_WA_WIDTH-1:0] DONE_FLAG_ADDR_BASE   = 6'd32;
    localparam [BUS_WA_WIDTH-1:0] MSG_MEM_BASE_ADDR     = 6'd48;

    localparam [BUS_RA_WIDTH-1:0] HASH_VALID_BASE_ADDR  = 4'd0;
    localparam [BUS_RA_WIDTH-1:0] HASH_MEM_BASE_ADDR    = 4'd8;

    sha256_core #(
        .DATA_WIDTH         (DATA_WIDTH),
        .BUS_WA_WIDTH       (BUS_WA_WIDTH),
        .BUS_RA_WIDTH       (BUS_RA_WIDTH),
        .MSG_MEM_A_WIDTH    (MSG_MEM_A_WIDTH),
        .HASH_MEM_A_WIDTH   (HASH_MEM_A_WIDTH),
        .HASH_WIDTH         (HASH_WIDTH),
        .MSG_WIDTH          (MSG_WIDTH)
    ) dut (
        .clk_i              (CLK),
        .rstn_i             (RST),
        .awvalid_i          (awvalid_i),
        .waddr_i            (waddr_i),
        .wdata_i            (wdata_i),
        .arvalid_i          (arvalid_i),
        .raddr_i            (raddr_i),
        .rdata_o            (rdata_o)
    );

    // Clock
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end

    // Read-channel Registering
    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            arvalid_ff_r <= 1'b0;
            raddr_ff_r   <= {BUS_RA_WIDTH{1'b0}};
        end
        else begin
            arvalid_ff_r <= arvalid_req_r;
            raddr_ff_r   <= raddr_req_r;
        end
    end

    initial begin
        $dumpfile("sha256_core_tb.vcd");
        $dumpvars(0, sha256_core_tb );
    end

    task write_reg;
        input [BUS_WA_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0]   data;
        begin
            @(negedge CLK);
            awvalid_i = 1'b1;
            waddr_i  = addr;
            wdata_i  = data;

            @(negedge CLK);
            awvalid_i = 1'b0;
            waddr_i  = {BUS_RA_WIDTH{1'b0}};
            wdata_i  = {DATA_WIDTH{1'b0}};
        end
    endtask

    task read_reg;
        input  [BUS_RA_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0]   data;
        begin
            // drive request side
            @(negedge CLK);
            arvalid_req_r = 1'b1;
            raddr_req_r   = addr;

            // 1st posedge: request is captured into FF by <=
            @(posedge CLK);

            // 2nd posedge: DUT sees stable registered arvalid_i/raddr_i
            @(posedge CLK);
            #1;
            data = rdata_o;

            // deassert request
            @(negedge CLK);
            arvalid_req_r = 1'b0;
            raddr_req_r   = {BUS_RA_WIDTH{1'b0}};

            @(posedge CLK);
        end
    endtask

    task wait_complete;
        reg [DATA_WIDTH-1:0] status;
        integer watchdog;
        begin
            status   = 0;
            watchdog = 0;

            while (status[0] !== 1'b1 && watchdog < 700) begin
                read_reg(HASH_VALID_BASE_ADDR, status);
                watchdog = watchdog + 1;
            end

            if (watchdog >= 700) begin
                $display("[ERROR] Timeout waiting complete flag");
                $finish;
            end
        end
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;

        awvalid_i    = 0;
        waddr_i      = 0;
        wdata_i      = 0;

        arvalid_req_r = 0;
        raddr_req_r   = 0;

        expected = 0;
        actual   = 0;

        // $readmemh("/home/ubuntu/SoC_Can_Ban/Luan/Class_2/Buoi_8/Code_C/input.txt",  input_mem);
        // $readmemh("/home/ubuntu/SoC_Can_Ban/Luan/Class_2/Buoi_8/Code_C/golden.txt", golden_mem);
        $readmemh("../01_tb/message_input.txt",  message_input_mem);
        $readmemh("../01_tb/hash256_golden.txt", hash256_golden_mem);

        RST = 1'b0;
        repeat (3) @(posedge CLK);
        RST = 1'b1;
        repeat (2) @(posedge CLK);

        $display("==============================================");
        $display(" Start SHA256 file-based test ");
        $display("==============================================");

        base_in     = 0;
        base_golden = 0;

        $display("CPU Write LOAD FLAG => Starting to load 521 bit message to MSG MEMORY");
        write_reg(LOAD_FLAG_ADDR_BASE, 32'h0000_0001);

        for (i = 0; i < 16; i = i + 1) begin
            write_reg(MSG_MEM_BASE_ADDR + i[BUS_WA_WIDTH-1:0], message_input_mem[base_in + i]);
        end

        $display("CPU Write START FLAG => Starting to load data to SHA256 and calculate HASH256");
        write_reg(START_FLAG_ADDR_BASE, 32'h0000_0001);
        wait_complete();

        for (i = 0; i < 8; i = i + 1) begin
            read_reg(HASH_MEM_BASE_ADDR + i[BUS_RA_WIDTH-1:0], actual);
            expected = hash256_golden_mem[base_golden + i];

            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] TC=%0d IDX=%0d ACT=%08h EXP=%08h",
                            tc, i, actual, expected);
            end
            else begin
                fail_count = fail_count + 1;
                $display("[FAIL] TC=%0d IDX=%0d ACT=%08h EXP=%08h",
                            tc, i, actual, expected);
            end
        end

        write_reg(DONE_FLAG_ADDR_BASE, 32'h0000_0001);
        repeat (2) @(posedge CLK);


        $display("==============================================");
        $display(" TEST DONE");
        $display(" PASS = %0d", pass_count);
        $display(" FAIL = %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TEST FAILED");

        $finish;
    end

endmodule