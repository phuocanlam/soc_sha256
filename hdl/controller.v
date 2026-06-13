module controller #(
    parameter   DATA_WIDTH       = 32,
    parameter   BUS_WA_WIDTH     = 6,
    parameter   BUS_RA_WIDTH     = 4,
    parameter   MSG_MEM_A_WIDTH  = 4,
    parameter   HASH_MEM_A_WIDTH = 3
) (
    input  wire                     clk_i,
    input  wire                     rstn_i,

	// From Arbiter
	input  wire 				    load_flag_i,
	input  wire 				    start_flag_i,
	input  wire 				    done_flag_i,
	// To Arbiter
	output wire 				    hash256_valid_flag_o,
	output wire [1:0]			    state_o,
	
	// To Message Input Memory
    output wire                     CTRL_MM_rd_en_o, // Read Message from MEM to SHA256 block

	// To SHA256 Block
    input  wire                     hash256_valid_i,        
    output wire                     CTRL_msg_valid_o
);
    //----------------------------------------------//
    //              Local Parameter                 //
    //----------------------------------------------//
    // State
    localparam s_IDLE               = 0;
    localparam s_LOAD               = 1;
    localparam s_EXEC               = 2;
    localparam s_READ               = 3;

    //----------------------------------------------//
    //                    Wires                     //
    //----------------------------------------------//


    //----------------------------------------------//
    //                   Register                   //
    //----------------------------------------------//
    reg [1:0]           current_state_r, next_state_r;
    reg [1:0]           CTRL_MBM_raddr_r;
    reg                 msg_valid_pulse_r;
    //----------------------------------------------//
    //                     FSM                      //
    //----------------------------------------------// 
    always @(posedge clk_i or negedge rstn_i) begin
		if (!rstn_i) begin
			current_state_r <= s_IDLE;
        end else begin
			current_state_r <= next_state_r;
		end		
	end

    always @(*) begin
        case (current_state_r)
            // Checking load_flag_i
            s_IDLE: begin
                if (load_flag_i) begin
                    next_state_r <= s_LOAD;
                end else begin
                    next_state_r <= s_IDLE;
                end
            end
            // Checking start_flag_i
            s_LOAD: begin
                if (start_flag_i) begin
                    next_state_r <= s_EXEC;
                end else begin
                    next_state_r <= s_LOAD;
                end
            end
            // Checking hash256_valid_i
            s_EXEC: begin
                if (hash256_valid_i) begin
                    next_state_r <= s_READ;
                end else begin
                    next_state_r <= s_EXEC;
                end
            end
            // Checking done_flag_i
            s_READ: begin
                if (done_flag_i) begin
                    next_state_r <= s_IDLE;
                end else begin
                    next_state_r <= s_READ;
                end
            end

            default: begin
                next_state_r <= s_IDLE;
            end
        endcase
    end

    //------------------------------------------------------//
    //           State Execute                              //
    // Create a pulse signal for message valid input        //
    // 1. Load Message Input from Memory to SHA256 Block    //
    // 2. Trigger SHA256 Block Calculation                  //
    //------------------------------------------------------//
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            msg_valid_pulse_r <= 1'b0;
        end else begin
            if (current_state_r == s_LOAD && start_flag_i) begin
                msg_valid_pulse_r <= 1'b1;
            end else begin
                msg_valid_pulse_r <= 1'b0;
            end
        end
    end
    // To Message Input Memory
    assign CTRL_MM_rd_en_o  = msg_valid_pulse_r;
    // To SHA256 Block
    assign CTRL_msg_valid_o = msg_valid_pulse_r;

    // To Arbiter for debug purpose
    assign state_o           = current_state_r;

    //----------------------------------------------//
    //           State READ                         //
    //----------------------------------------------//
    // assign hash256_valid_flag_o = (current_state_r == s_READ) ? 1'b1 : 1'b0;
    assign hash256_valid_flag_o = hash256_valid_i ? 1'b1 : 1'b0;


endmodule