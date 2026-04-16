module Full_DataPath_Module (
		input  wire clk,
		input  wire reset
);
	logic [2:0] S;
	 State_Unit_Module state_u (
    .clk   (clk),
    .reset (reset),
    .S     (S)
    );
    logic [1:0] PCSrc;
	logic       WBData,PCWrite, IRWrite;
	logic       ImmExtSel, RegWrite, ALUSrc;
	logic [2:0] ALUOpSel;
	logic       MemWrite;
	logic       AWrite, BWrite, DWrite;
	logic       ALUOutWrite, MDRWrite;
	Control_Unit_Module control_u (
    .S           (S),
    .O           (IR[31:27]),   // opcode comes later
    .PCSrc       (PCSrc),
    .PCWrite     (PCWrite),
    .IRWrite     (IRWrite),
    .ImmExtSel   (ImmExtSel),
    .RegWrite    (RegWrite),
    .ALUSrc      (ALUSrc),
    .ALUOpSel    (ALUOpSel),
    .MemWrite    (MemWrite),
    .WBData      (WBData),
    .AWrite      (AWrite),
    .BWrite      (BWrite),
    .DWrite      (DWrite),
    .ALUOutWrite (ALUOutWrite),
    .MDRWrite    (MDRWrite)
    );
    
    logic [31:0] PC, PC_next,offsetext;
    logic [31:0] InstrMemOut, B_reg;
    logic [31:0] PC_plus1;
	assign PC_plus1 = PC + 32'd1;
	logic PCW;
	And_Module PCW_AU(.A(PCWrite),.B(MUXO),.Y(PCW));
    SignExt_22_to_32_Module offsetexter(.in(IR[21:0]),.out(offsetext));
	MUX4_32_Module PC_MUX(.A(PC_plus1),.B(PC+offsetext),.C(B_reg),.D(32'd0),.sel(PCSrc),.Y(PC_next));

	Reg_Module PC_reg (
    .clk   (clk),
    .reset(reset),
    .enable(PCW),
    .D     (PC_next),
    .Q     (PC)
	);
	logic [31:0] IR;
	Memory_Module InstMem (
    .clk       (clk),
    .enable    (1'b0),        // instruction memory is read-only
    .writeData (32'b0),
    .addr      (PC[5:2]),   // WORD address
    .readData  (InstrMemOut)
);
	Reg_Module IR_reg (
    .clk   (clk),
    .reset (reset),
    .enable(IRWrite),
    .D     (InstrMemOut),
    .Q     (IR)
	);
	
    
    logic RegFW;
    And_Module RFW(.A(RegWrite),.B(MUXO),.Y(RegFW));
    logic [31:0] A_bus, B_bus,D_bus,Pred_bus, WriteBackData;
    Reg_File regfile (
    .clk      (clk),
    .reset    (reset),

    // Register addresses from R-type instruction format
    .Rp       (IR[26:22]),
    .Rd       (IR[21:17]),
    .Rs       (IR[16:12]),
    .Rt       (IR[11:7]),

    // Write-back
    .RegWriteEnable (RegFW),
    .WB_data  (WriteBackData),

    // Hardwired registers
    .Reg30    (PC),
    .Reg31    (PC_plus1),

    // Read outputs
    .A_bus    (A_bus),
    .B_bus    (B_bus),
    .D_bus    (D_bus),
    .Pred_bus (Pred_bus)
    );
    logic [31:0] A_reg,D_reg;

	Reg_Module A_reg_u (.clk(clk), .enable(AWrite), .D(A_bus), .Q(A_reg));
	Reg_Module B_reg_u (.clk(clk), .enable(BWrite), .D(B_bus), .Q(B_reg));
	Reg_Module D_reg_u (.clk(clk), .enable(DWrite), .D(D_bus), .Q(D_reg));
	
	logic cond,pred,MUXO;
	
	Comp5bit_Module coditional_test(.A(IR[26:22]),.A_is_zero(cond));
	Comp32bit_Module condetion_test(.A(Pred_bus),.A_not_zero(pred));
	Mux_1bit_Module condition_MUX(.A(pred),.B(1'b1),.Sel(cond),.Y(MUXO));
	logic [31:0]ImmExt,ALU_B;
	ImmExt_12_to_32_Module  ImmExt_u(.in(IR[11:0]),.ExtSel(ImmExtSel),.out(ImmExt));
	
	MUX2_32_Module ALUScr(.A(B_reg),.B(ImmExt),.sel(ALUSrc),.Y(ALU_B));
	logic [31:0] res,ALU_RegOUT;
	ALU_Module ALU_u(.A(A_reg),.B(ALU_B),.ALUOpSel(ALUOpSel),.Result(res));
	Reg_Module ALU_OUT(.clk(clk),.reset(reset),.enable(ALUOutWrite),.D(res),.Q(ALU_RegOUT));
	logic MW;
	logic [31:0]RM,MDRO;
	And_Module MW_AU(.A(MemWrite),.B(MUXO),.Y(MW));
	wire [3:0] dmem_addr;
	assign dmem_addr = ALU_RegOUT[5:2];   // word address

	Memory_Module DataMem (
    .clk       (clk),
    .enable    (MW),
    .writeData (D_reg),
    .addr   (dmem_addr),
    .readData  (RM)
);
	Reg_Module MDR(.clk(clk),.reset(reset),.enable(MDRWrite),.D(RM),.Q(MDRO));
	MUX2_32_Module WriteBackDate(.A(res),.B(MDRO),.sel(WBData),.Y(WriteBackData));
	


endmodule
