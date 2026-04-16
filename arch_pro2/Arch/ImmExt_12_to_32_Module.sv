module ImmExt_12_to_32_Module (
    input  wire [11:0] in,
    input  wire        ExtSel,   // 0 = zero extend, 1 = sign extend
    output reg  [31:0] out
);

    always @(*) begin
        if (ExtSel)
            out = {{20{in[11]}}, in};   // Sign extend
        else
            out = {20'd0, in};          // Zero extend
    end

endmodule
