module msg_mem #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 16,
    parameter MSG_WIDTH  = 512
) (
    input  wire                         clk_i,
    // From Arbiter
    input  wire        [ADDR_WIDTH-1:0] Arbiter_msg_waddr_i,
    input  wire                         Arbiter_msg_awvalid_i,
    input  wire        [DATA_WIDTH-1:0] Arbiter_msg_wdata_i,
    // From controller
    input  wire                         CTRL_MM_rd_en_i,
    // To datapath
    output wire signed [MSG_WIDTH-1:0]  msg_o
);
    //----------------------------------------------//
    //              Local Parameter                 //
    //----------------------------------------------//

    //----------------------------------------------//
    //              Wire declaration                //
    //----------------------------------------------//

    //----------------------------------------------//
    //              Reg declaration                 //
    //----------------------------------------------//
    // MSG Memory Buffer
    reg [DATA_WIDTH-1:0] msg_buffer [0:MEM_DEPTH-1];

    //----------------------------------------------//
    //         Combinational circuits               //
    //----------------------------------------------//

    //----------------------------------------------//
    //            Sequential circuits               //
    //----------------------------------------------//
    // Write to memory
    always @(posedge clk_i) begin
        if (Arbiter_msg_awvalid_i) begin
            msg_buffer[Arbiter_msg_waddr_i] <= Arbiter_msg_wdata_i;
        end
    end

    // Read 512-bit Message output to SHA256 block
    assign msg_o = (CTRL_MM_rd_en_i) ? {
                    msg_buffer[0],  msg_buffer[1],  msg_buffer[2],  msg_buffer[3],
                    msg_buffer[4],  msg_buffer[5],  msg_buffer[6],  msg_buffer[7],
                    msg_buffer[8],  msg_buffer[9],  msg_buffer[10], msg_buffer[11],
                    msg_buffer[12], msg_buffer[13], msg_buffer[14], msg_buffer[15]
               } : 512'h0;
    
endmodule