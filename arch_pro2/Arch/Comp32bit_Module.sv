module Comp32bit_Module(
    input  [31:0] A,
    output        A_not_zero
);

    // Output is 1 if any bit of A is 1
    assign A_not_zero = |A;  // OR-reduce operator

endmodule
