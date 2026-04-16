module Mux_1bit_Module (
    input  wire A,     // input 0
    input  wire B,     // input 1
    input  wire Sel,   // select signal
    output wire Y      // output
);

    assign Y = Sel ? B : A;

endmodule