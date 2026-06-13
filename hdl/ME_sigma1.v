// Message Expansion Sigma1
// Sigma1 (x) = RotR17(x) xor RotR19(x) xor ShR10(x)
module ME_sigma1(
    input  wire [31:0] x_i,
    output wire [31:0] sigma1_o
);

    wire [31:0] rotr17  = {x_i[16:0], x_i[31:17]};
    wire [31:0] rotr19  = {x_i[18:0], x_i[31:19]};
    wire [31:0] shr10   = x_i >> 10;

    assign sigma1_o = rotr17 ^ rotr19 ^ shr10;

endmodule