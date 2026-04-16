module SignExt_22_to_32_Module (
    input  wire [21:0] in,
    output wire [31:0] out
);
    assign out = {{10{in[21]}}, in};
endmodule
