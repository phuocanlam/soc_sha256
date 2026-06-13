// Compression Round
// S0(x) = RotR2(x) xor RotR13(x) xor RotR22(x)
module compress_sigma0(
    input  wire [31:0] x_i,
    output wire [31:0] S0_o
);

    wire [31:0] rotr2  = {x_i[1:0],  x_i[31:2]};
    wire [31:0] rotr13 = {x_i[12:0], x_i[31:13]};
    wire [31:0] rotr22 = {x_i[21:0], x_i[31:22]};

    assign S0_o = rotr2 ^ rotr13 ^ rotr22;

endmodule