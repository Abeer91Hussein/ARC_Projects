module Reg_File (
    input  wire        clk,
    input  wire        reset,

    // -------- Register addresses --------
    input  wire [4:0]  Rs,
    input  wire [4:0]  Rt,
    input  wire [4:0]  Rp,
    input  wire [4:0]  Rd,

    // -------- Write-back --------
    input  wire        RegWriteEnable,
    input  wire [31:0] WB_data,

    // -------- Hardwired registers --------
    input  wire [31:0] Reg30,   // PC
    input  wire [31:0] Reg31,   // Return Address

    // -------- Read outputs --------
    output wire [31:0] A_bus,
    output wire [31:0] B_bus,
    output wire [31:0] D_bus,
    output wire [31:0] Pred_bus
);

    // Internal wires for registers R1–R29
    wire [31:0] reg_q [1:29];
    wire [29:1] reg_en;

    genvar i;

    // -------------------------------
    // Write-enable decoder
    // -------------------------------
    generate
        for (i = 1; i <= 29; i = i + 1) begin : EN_DECODE
            assign reg_en[i] = RegWriteEnable && (Rd == i[4:0]);
        end
    endgenerate

    // -------------------------------
    // Register instances (R1–R29)
    // -------------------------------
    generate
        for (i = 1; i <= 29; i = i + 1) begin : REG_ARRAY
            Reg_Module R (
                .clk    (clk),
                .reset  (reset),
                .enable (reg_en[i]),
                .D      (WB_data),
                .Q      (reg_q[i])
            );
        end
    endgenerate

    // -------------------------------
    // Read multiplexers
    // -------------------------------
    function [31:0] read_reg;
        input [4:0] addr;
        begin
            case (addr)
                5'd0:  read_reg = 32'd0;      // R0 = 0
                5'd30: read_reg = Reg30;      // R30 = PC
                5'd31: read_reg = Reg31;      // R31 = RA
                default: read_reg = reg_q[addr];
            endcase
        end
    endfunction

    assign A_bus    = read_reg(Rs);
    assign B_bus    = read_reg(Rt);
    assign Pred_bus = read_reg(Rp);
    assign D_bus = read_reg(Rd);
    

endmodule
