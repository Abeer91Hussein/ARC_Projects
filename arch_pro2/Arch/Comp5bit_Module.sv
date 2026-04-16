module Comp5bit_Module(
    input  [4:0] A,
    output       A_is_zero
);

    assign A_is_zero = (A == 5'd0) ? 1'b1 : 1'b0;

endmodule
