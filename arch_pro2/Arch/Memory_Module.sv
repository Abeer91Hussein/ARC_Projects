module Memory_Module #(
    parameter WIDTH = 32,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = 4   // log2(DEPTH)
)(
    input  wire                 clk,
    input  wire                 enable,      // write enable
    input  wire [WIDTH-1:0]     writeData,
    input  wire [ADDR_WIDTH-1:0] addr    ,    // WORD address
    output wire [WIDTH-1:0]     readData
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    // Word read
    assign readData = mem[addr];

    // Word write
    always @(posedge clk) begin
        if (enable)
            mem[addr] <= writeData;
    end
endmodule
