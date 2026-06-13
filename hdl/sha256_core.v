module sha256_core #(
    parameter   DATA_WIDTH        = 32,
    parameter   BUS_WA_WIDTH      = 6,
    parameter   BUS_RA_WIDTH      = 4,
    parameter   MSG_MEM_A_WIDTH   = 4,
    parameter   HASH_MEM_A_WIDTH  = 3,
    parameter   HASH_WIDTH        = 256,
    parameter   MSG_WIDTH         = 512,
    parameter   ADDR_WIDTH        = 4,
    parameter   MSG_MEM_DEPTH     = 16,
    parameter   HASH_MEM_DEPTH    = 8

)(
    input  wire                     clk_i,
    input  wire                     rstn_i,

    // External write channel
    input  wire                     awvalid_i,
    input  wire [BUS_WA_WIDTH-1:0]  waddr_i,
    input  wire [DATA_WIDTH-1:0]    wdata_i,

    // External read channel
    input  wire                     arvalid_i,
    input  wire [BUS_RA_WIDTH-1:0]  raddr_i,
    output wire [DATA_WIDTH-1:0]    rdata_o
);

    //==================================================
    // Internal wires
    //==================================================
    // Arbiter <-> Controller
    wire                                load_flag_w;
    wire                                start_flag_w;
    wire                                done_flag_w;
    wire                                hash_valid_flag_w;
    wire [1:0]                          state_w;

    // SHA256 -> Controller
    wire                                hash256_valid_w;

    // Controller -> SHA256
    wire                                CTRL_msg_valid_w;

    // Controller -> Message Input Mem
	wire 							    CTRL_MM_rd_en_w;

    // Arbiter -> Message Input Mem
    wire                                Arbiter_msg_awvalid_w;
    wire        [MSG_MEM_A_WIDTH-1:0]   Arbiter_msg_waddr_w;
    wire signed [DATA_WIDTH-1:0]        Arbiter_msg_wdata_w;
    
    // Arbiter <-> Hash256 Output Mem
    wire                                Arbiter_hash256_arvalid_w;
    wire        [HASH_MEM_A_WIDTH-1:0]  Arbiter_hash256_raddr_w;
    wire        [DATA_WIDTH-1:0]        Arbiter_hash256_rdata_w;

    // Message Input Mem -> SHA256
    wire signed [MSG_WIDTH-1:0]         msg_512_w;

    // SHA256 -> Hash256 Output Mem
    wire signed [HASH_WIDTH-1:0]        hash256_w;

    //==================================================
    // Arbiter
    //==================================================

    arbiter #(
        .DATA_WIDTH                 (DATA_WIDTH),
        .BUS_WA_WIDTH               (BUS_WA_WIDTH),
        .BUS_RA_WIDTH               (BUS_WA_WIDTH),
        .MSG_MEM_A_WIDTH            (MSG_MEM_A_WIDTH),
        .HASH_MEM_A_WIDTH           (HASH_MEM_A_WIDTH)
    ) u_arbiter (
        .clk_i                      (clk_i),
        .rstn_i                     (rstn_i),

        .awvalid_i                  (awvalid_i),
        .waddr_i                    (waddr_i),
        .wdata_i                    (wdata_i),

        .arvalid_i                  (arvalid_i),
        .raddr_i                    (raddr_i),
        .rdata_o                    (rdata_o),

        .load_flag_o                (load_flag_w),
        .start_flag_o               (start_flag_w),
        .done_flag_o                (done_flag_w),

        .hash_valid_flag_i          (hash_valid_flag_w),
        .state_i                    (state_w),

        .Arbiter_msg_awvalid_o      (Arbiter_msg_awvalid_w),
        .Arbiter_msg_waddr_o        (Arbiter_msg_waddr_w),
        .Arbiter_msg_wdata_o        (Arbiter_msg_wdata_w),

        .Arbiter_hash256_arvalid_o  (Arbiter_hash256_arvalid_w),
        .Arbiter_hash256_raddr_o    (Arbiter_hash256_raddr_w),
        .Arbiter_hash256_rdata_i    (Arbiter_hash256_rdata_w)
    );

    //==================================================
    // Controller
    //==================================================

    controller #(
        .DATA_WIDTH                 (DATA_WIDTH),
        .BUS_WA_WIDTH               (BUS_WA_WIDTH),
        .BUS_RA_WIDTH               (BUS_WA_WIDTH),
        .MSG_MEM_A_WIDTH            (MSG_MEM_A_WIDTH),
        .HASH_MEM_A_WIDTH           (HASH_MEM_A_WIDTH)
    ) u_controller (
        .clk_i                      (clk_i),
        .rstn_i                     (rstn_i),

        .load_flag_i                (load_flag_w),
        .start_flag_i               (start_flag_w),
        .done_flag_i                (done_flag_w),

        .hash256_valid_flag_o       (hash_valid_flag_w),
		.state_o	                (state_w),
		.CTRL_MM_rd_en_o	        (CTRL_MM_rd_en_w),
        .hash256_valid_i            (hash256_valid_w),
        .CTRL_msg_valid_o           (CTRL_msg_valid_w)
    );

    //==================================================
    // Message Input Memory
    //==================================================
    msg_mem #(
        .ADDR_WIDTH                 (ADDR_WIDTH),
        .DATA_WIDTH                 (DATA_WIDTH),
        .MEM_DEPTH                  (MSG_MEM_DEPTH), 
        .MSG_WIDTH                  (MSG_WIDTH)
    ) u_msg_mem (
        .clk_i                      (clk_i),
        .Arbiter_msg_awvalid_i      (Arbiter_msg_awvalid_w),
        .Arbiter_msg_waddr_i        (Arbiter_msg_waddr_w),
        .Arbiter_msg_wdata_i        (Arbiter_msg_wdata_w),
        .CTRL_MM_rd_en_i            (CTRL_MM_rd_en_w),
		.msg_o                      (msg_512_w)
    );

    //==================================================
    // Datapath
    //==================================================

    sha256_block u_sha256_block (
        .clk_i                      (clk_i),
        .rstn_i                     (rstn_i),

        .M_i                        (msg_512_w),
        .M_valid_i                  (CTRL_msg_valid_w),
        .Hash_o                     (hash256_w),
        .Hash_valid_o               (hash256_valid_w)
    );

    //==================================================
    // Hash256 Memory
    //==================================================
    hash_mem #(
        .ADDR_WIDTH                 (ADDR_WIDTH),
        .DATA_WIDTH                 (DATA_WIDTH),
        .MEM_DEPTH                  (HASH_MEM_DEPTH), 
        .HASH_WIDTH                 (HASH_WIDTH)
    ) u_hash_mem (
        .clk_i                      (clk_i),
        .rstn_i                     (rstn_i),
        .Arbiter_hash256_arvalid_i  (Arbiter_hash256_arvalid_w),
        .Arbiter_hash256_raddr_i    (Arbiter_hash256_raddr_w),
        .Arbiter_hash256_rdata_o    (Arbiter_hash256_rdata_w),
        .hash256_data_i             (hash256_w),
        .hash256_valid_i            (hash256_valid_w)
    );

endmodule