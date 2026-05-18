module Ch #(
    parameter WORDSIZE = 0
) (
    input  wire [WORDSIZE-1:0]  x_i, y_i, z_i,
    output wire [WORDSIZE-1:0]  Ch_o
);
    assign Ch_o = ((x_i & y_i) ^ (~x_i & z_i));
endmodule