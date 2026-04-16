module Reg_Module (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,     // write enable
    input  wire [31:0] D,          // data input
    output reg  [31:0] Q           // data output
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 32'd0;
        else if (enable)
            Q <= D;
    end

endmodule
