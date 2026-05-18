// Compression Round
// S1(x) = RotR6(x) xor RotR11(x) xor RotR25(x)
module sha256_S1(
    input  wire [31:0] x_i,
    output wire [31:0] S1_o
);

    wire [31:0] rotr6  = {x_i[5:0],  x_i[31:6]};
    wire [31:0] rotr11 = {x_i[10:0], x_i[31:11]};
    wire [31:0] rotr25 = {x_i[24:0], x_i[31:25]};

    assign S1_o = rotr6 ^ rotr11 ^ rotr25;

endmodule