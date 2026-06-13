module Maj #(
    parameter WORD_WIDTH = 0
) (
    input  wire [WORD_WIDTH-1:0]  x_i, y_i, z_i,
    output wire [WORD_WIDTH-1:0]  Maj_o
);
    assign Maj_o = ((x_i & y_i) ^ (x_i & z_i) ^ (y_i & z_i));
endmodule