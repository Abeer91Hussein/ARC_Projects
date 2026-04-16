// ============================================================
// Control Unit (combinational) ? implements your Boolean equations
// Inputs:  S2,S1,S0  (FSM state bits)
//          O4..O0    (opcode bits)
// Outputs: PCSrc[1:0], PCWrite, IRWrite, DestReg, ImmExtSel, RegWrite,
//          ALUSrc, ALUOpSel[2:0], MemWrite,
//          WBData[1:0], AWrite, BWrite, ALUOutWrite, MDRWrite
// ============================================================

module Control_Unit_Module (
    // FSM state bus
    input  logic [2:0] S,   // S[2]=S2, S[1]=S1, S[0]=S0

    // Opcode bus
    input  logic [4:0] O,   // O[4]=O4 ... O[0]=O0

    // Control outputs
    output logic [1:0] PCSrc,
    output logic       PCWrite,
    output logic       IRWrite,
    output logic       ImmExtSel,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic [2:0] ALUOpSel,
    output logic       MemWrite,
    output logic 	   WBData,
    output logic       AWrite,
    output logic       BWrite,
    output logic       DWrite,
    output logic       ALUOutWrite,
    output logic       MDRWrite
);

    // Unpack buses for readability (optional but keeps your equations unchanged)
    logic S2, S1, S0;
    logic O4, O3, O2, O1, O0;

    assign S2 = S[2];
    assign S1 = S[1];
    assign S0 = S[0];

    assign O4 = O[4];
    assign O3 = O[3];
    assign O2 = O[2];
    assign O1 = O[1];
    assign O0 = O[0];

    // Inversions
    logic nS2, nS1, nS0;
    logic nO4, nO3, nO2, nO1, nO0;

    always_comb begin
        nS2 = ~S2;  nS1 = ~S1;  nS0 = ~S0;
        nO4 = ~O4;  nO3 = ~O3;  nO2 = ~O2;  nO1 = ~O1;  nO0 = ~O0;

        // PCSrc
        PCSrc[1] = (nS2 &  S1 & nS0) & (nO4 & O3 & O2 & nO1 & O0);
        PCSrc[0] = (nS2 & nS1 & nS0);

        // PCWrite
        PCWrite  = (nS2 & nS1 & nS0) |
                   ((nS2 & S1 & nS0) & (nO4 & O3 & ((O2 & nO1) | (nO2 & O1 & O0))));

        // IRWrite
        IRWrite  = (nS2 & nS1 & nS0);

        // AWrite, BWrite
        AWrite   = (nS2 & nS1 & S0);
        BWrite   = (nS2 & nS1 & S0);
        // DWrite
        DWrite   = (nS2 & nS1 & S0) & (nO4 & O3 & nO2 & O1 & nO0);

        // MDRWrite
        MDRWrite = (nS2 & S1 & S0) & (nO4 & O3 & nO2 & nO1 & O0);

        // MemWrite
        MemWrite = (nS2 & S1 & S0) & (nO4 & O3 & nO2 & O1 & nO0);

        // ALUOutWrite
        ALUOutWrite = (nS2 & S1 & nS0) &
                      (nO4 & (nO3 | (O3 & nO2 & (nO1 | nO0))));

        // ImmExtSel and ALUSrc
        ImmExtSel = (nS2 & S1 & nS0) &
                    (nO4 & ((nO3 & O2 & (O1 | O0)) | (O3 & nO2 & (nO1 | nO0))));

        ALUSrc = ImmExtSel;

        // RegWrite
        RegWrite = ((S2 & nS1 & nS0) & (nO4 & (nO3 | (O3 & nO2 & nO1)))) |
                   ((nS2 & S1 & nS0) & (nO4 & O3 & O2 & nO1 & nO0));

        // WBData
        WBData = (S2 & nS1 & nS0) & (nO4 & O3 & nO2 & nO1 & O0);
        //WBData[0] = (nS2 & S1 & nS0) & (nO4 & O3 & O2 & nO1 & nO0);

   
        // ALUOpSel
        ALUOpSel[2] = (nS2 & S1 & nS0) &
                      (nO4 & nO1 & nO0 & ((nO3 & O2) | (O3 & nO2)));

        ALUOpSel[1] = (nS2 & S1 & nS0) & (nO4 & nO3 & O1);

        ALUOpSel[0] = (nS2 & S1 & nS0) & (nO4 & nO3 & nO0 & (nO2 | O1));
    end

endmodule
