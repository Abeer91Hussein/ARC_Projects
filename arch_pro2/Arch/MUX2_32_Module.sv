module MUX2_32_Module (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire        sel,
    output wire [31:0] Y
);
    assign Y = sel ? B : A;
endmodule
