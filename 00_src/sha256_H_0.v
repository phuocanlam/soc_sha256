// initial hash values
    module sha256_H_0(
        output [255:0] H_0
    );

    assign H_0 = {
        32'h6A09E667, 32'hBB67AE85, 32'h3C6EF372, 32'hA54FF53A,
        32'h510E527F, 32'h9B05688C, 32'h1F83D9AB, 32'h5BE0CD19
    };

    endmodule
