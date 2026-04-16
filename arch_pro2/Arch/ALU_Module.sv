module ALU_Module (
    input  wire [31:0] A,          // Operand 1
    input  wire [31:0] B,          // Operand 2
    input  wire [2:0]  ALUOpSel,    // ALU operation selector

    output reg  [31:0] Result     // ALU result
);

    // Combinational ALU
    always @(*) begin
        case (ALUOpSel)
            3'b000: Result = A + B;       // ADD
            3'b001: Result = A - B;       // SUB
            3'b010: Result = A | B;       // OR
            3'b011: Result = ~(A | B);    // NOR
            3'b100: Result = A & B;       // AND
            default: Result = 32'd0;
        endcase
    end


endmodule
