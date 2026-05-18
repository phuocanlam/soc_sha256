// Sigma0 (x) = RotR7(x)  xor RotR18(x) xor ShR3(x)
module sha256_sigma0(
    input  wire [31:0] x_i,
    output wire [31:0] sigma0_o
);

    wire [31:0] rotr7  = {x_i[6:0],  x_i[31:7]};
    wire [31:0] rotr18 = {x_i[17:0], x_i[31:18]};
    wire [31:0] shr3   = x_i >> 3;

    assign sigma0_o = rotr7 ^ rotr18 ^ shr3;

endmodule