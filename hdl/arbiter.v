module arbiter #(
    parameter   DATA_WIDTH        = 32,
    parameter   BUS_WA_WIDTH      = 6,
    parameter   BUS_RA_WIDTH      = 4,
    parameter   MSG_MEM_A_WIDTH   = 4,
    parameter   HASH_MEM_A_WIDTH  = 3
) (
    input  wire                         clk_i,
    input  wire                         rstn_i,
	
	// Write channel
	input  wire                         awvalid_i,
	input  wire [BUS_WA_WIDTH-1:0]      waddr_i,
	input  wire [DATA_WIDTH-1:0]        wdata_i,
	
	// Read channel
	input  wire                         arvalid_i,
	input  wire [BUS_RA_WIDTH-1:0]      raddr_i,
	output wire [DATA_WIDTH-1:0]        rdata_o,

	// To Controller
	output wire 				        load_flag_o,
	output wire 				        start_flag_o,
	output wire 				        done_flag_o,

	// From Controller
	input  wire 				        hash_valid_flag_i,
	input  wire [1:0]			        state_i,
	
	// To Message Input Memory
	output wire [MSG_MEM_A_WIDTH-1:0]   Arbiter_msg_waddr_o,
	output wire 				        Arbiter_msg_awvalid_o,
	output wire [DATA_WIDTH-1:0]	    Arbiter_msg_wdata_o,
	
	// To Hash Output Memory
	output wire [HASH_MEM_A_WIDTH-1:0]  Arbiter_hash256_raddr_o,
	output wire 				        Arbiter_hash256_arvalid_o,
	input  wire [DATA_WIDTH-1:0]        Arbiter_hash256_rdata_i

);
    //----------------------------------------------//
    //              Local Parameter                 //
    //----------------------------------------------//
    // State
    localparam s_IDLE               = 0;
    localparam s_LOAD               = 1;
    localparam s_EXEC               = 2;
    localparam s_READ               = 3;

    // Write Channel
    localparam LOAD_BASE_ADDR       = 0;
    localparam START_BASE_ADDR      = 1;
    localparam DONE_BASE_ADDR       = 2;
    localparam MSG_MEM_BASE_ADDR    = 3;

    // Read Channel
    localparam HASH_VALID_BASE_ADDR = 0;
    localparam HASH_MEM_BASE_ADDR   = 1;

    //----------------------------------------------//
    //               Wire Declaration               //
    //----------------------------------------------//

    //----------------------------------------------//
    //               Reg Declaration                //
    //----------------------------------------------//
    reg						        arvalid_r;
	reg [BUS_RA_WIDTH-1:0]          raddr_r;

    //----------------------------------------------//
    //            Combinational Circuit             //
    //----------------------------------------------//
    // To Controller
    assign load_flag_o  = (awvalid_i && (state_i == s_IDLE) && (waddr_i[BUS_WA_WIDTH-1:4] == LOAD_BASE_ADDR))  ? wdata_i[0] : 1'b0;
    assign start_flag_o = (awvalid_i && (state_i == s_LOAD) && (waddr_i[BUS_WA_WIDTH-1:4] == START_BASE_ADDR)) ? wdata_i[0] : 1'b0;
    assign done_flag_o  = (awvalid_i && (state_i == s_READ) && (waddr_i[BUS_WA_WIDTH-1:4] == DONE_BASE_ADDR))  ? wdata_i[0] : 1'b0;

    // To MSG Input Bank Memory
    assign Arbiter_msg_awvalid_o = (awvalid_i && (state_i == s_LOAD) && (waddr_i[BUS_WA_WIDTH-1:4] == MSG_MEM_BASE_ADDR))  ? 1'b1 : 1'b0;
    assign Arbiter_msg_waddr_o   = (Arbiter_msg_awvalid_o) ? waddr_i[MSG_MEM_A_WIDTH-1:0] : 0;
    assign Arbiter_msg_wdata_o    = (Arbiter_msg_awvalid_o) ? wdata_i : 0;

    // To HASH Output Memory
    assign Arbiter_hash256_arvalid_o  = (arvalid_i && 
                                        (state_i == s_READ) && 
                                        (raddr_i[3] == HASH_MEM_BASE_ADDR)) ? 1'b1: 1'b0;

	assign Arbiter_hash256_raddr_o	  = raddr_i[HASH_MEM_A_WIDTH-1:0];

    always @(posedge clk_i or negedge rstn_i) begin
		if (!rstn_i) begin
			arvalid_r <= 0;
			raddr_r   <= {BUS_RA_WIDTH{1'b0}};;
        end else begin
			arvalid_r <= arvalid_i;
			raddr_r   <= raddr_i;	
		end		
	end

    assign rdata_o = (arvalid_r && raddr_r[3] == HASH_MEM_BASE_ADDR) ? Arbiter_hash256_rdata_i : {31'h0, hash_valid_flag_i};

    // ila_arbiter u_ila_arbiter (
    //     .clk                    (clk_i),

    //     .probe0                 (awvalid_i),                 // 1 bit
    //     .probe1                 (waddr_i),                   // 7 bits
    //     .probe2                 (wdata_i),                   // 32 bits

    //     .probe3                 (arvalid_i),                 // 1 bit
    //     .probe4                 (raddr_i),                   // 3 bits
    //     .probe5                 (rdata_o),                   // 32 bits

    //     .probe6                 (load_flag_o),               // 1 bit
    //     .probe7                 (start_flag_o),              // 1 bit
    //     .probe8                 (done_flag_o),               // 1 bit

    //     .probe9                 (complete_i),                // 1 bit
    //     .probe10                (state_i),                   // 2 bits

    //     .probe11                (Arbiter_MBM_waddr_o),       // 4 bits
    //     .probe12                (Arbiter_MBM_awvalid_o),     // 1 bit
    //     .probe13                (Arbiter_MBM_data_o),        // 32 bits

    //     .probe14                (Arbiter_VIBM_waddr_o),      // 2 bits
    //     .probe15                (Arbiter_VIBM_awvalid_o),    // 1 bit
    //     .probe16                (Arbiter_VIBM_data_o),       // 32 bits

    //     .probe17                (Arbiter_VOM_raddr_o),       // 2 bits
    //     .probe18                (Arbiter_VOM_arvalid_o),     // 1 bit
    //     .probe19                (Arbiter_VOM_rdata_i),       // 32 bits

    //     .probe20                (arvalid_r),                 // 1 bit
    //     .probe21                (raddr_r)                    // 3 bits
    // );


endmodule