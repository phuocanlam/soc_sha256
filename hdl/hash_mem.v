module hash_mem #(
    parameter ADDR_WIDTH = 3,
    parameter MEM_DEPTH  = 8,
    parameter DATA_WIDTH = 32,
    parameter HASH_WIDTH = 256
) (
    input  wire                         clk_i,
    input  wire                         rstn_i,

    // From Arbiter
    input  wire        [ADDR_WIDTH-1:0] Arbiter_hash256_raddr_i,
    input  wire                         Arbiter_hash256_arvalid_i,
    output reg         [DATA_WIDTH-1:0] Arbiter_hash256_rdata_o,

    // From SHA256
    input  wire signed [HASH_WIDTH-1:0] hash256_data_i,
    input  wire                         hash256_valid_i
);
    //----------------------------------------------//
    //              Local Parameter                 //
    //----------------------------------------------//
    integer i;

    //----------------------------------------------//
    //              Wire declaration                //
    //----------------------------------------------//

    //----------------------------------------------//
    //              Reg declaration                 //
    //----------------------------------------------//
    reg [DATA_WIDTH-1:0] hash_reg_array [0:MEM_DEPTH-1];

    //----------------------------------------------//
    //         Combinational circuits               //
    //----------------------------------------------//


    //----------------------------------------------//
    //            Sequential circuits               //
    //----------------------------------------------//
    // Write data to memory
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                hash_reg_array[i] = 32'h0;
            end
        end else if (hash256_valid_i) begin
            hash_reg_array[0] <= hash256_data_i[255:224];
            hash_reg_array[1] <= hash256_data_i[223:192];
            hash_reg_array[2] <= hash256_data_i[191:160];
            hash_reg_array[3] <= hash256_data_i[159:128];
            hash_reg_array[4] <= hash256_data_i[127:96];
            hash_reg_array[5] <= hash256_data_i[95:64];
            hash_reg_array[6] <= hash256_data_i[63:32];
            hash_reg_array[7] <= hash256_data_i[31:0];
        end
    end

    // Read data from memory
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            Arbiter_hash256_rdata_o <= 0;
        end else begin
            if (Arbiter_hash256_arvalid_i) begin
                Arbiter_hash256_rdata_o <= hash_reg_array[Arbiter_hash256_raddr_i];
            end else begin
                Arbiter_hash256_rdata_o <= 0;
            end
        end
    end


endmodule