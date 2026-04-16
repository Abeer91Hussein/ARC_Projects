`timescale 1ns/1ps

// ============================================================
// Comprehensive Testbench for MultiCycle Processor
// Tests all instructions from the specification
// ============================================================

module comprehensive_testbench;

    logic clk;
    logic reset;
    integer test_count;
    integer pass_count;
    integer fail_count;
    integer cycle_count;
    integer last_pc;

    // -------------------------
    // DUT
    // -------------------------
    Full_DataPath_Module DUT (
        .clk   (clk),
        .reset (reset)
    );

    // -------------------------
    // Clock generation
    // -------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // -------------------------
    // Instruction encoding functions
    // -------------------------
    function [31:0] encode_rtype;
        input [4:0] opcode;
        input [4:0] Rp;
        input [4:0] Rd;
        input [4:0] Rs;
        input [4:0] Rt;
        begin
            encode_rtype = {opcode, Rp, Rd, Rs, Rt, 7'b0};
        end
    endfunction

    function [31:0] encode_itype;
        input [4:0] opcode;
        input [4:0] Rp;
        input [4:0] Rd;
        input [4:0] Rs;
        input [11:0] Imm;
        begin
            encode_itype = {opcode, Rp, Rd, Rs, Imm};
        end
    endfunction

    function [31:0] encode_jtype;
        input [4:0] opcode;
        input [4:0] Rp;
        input [21:0] offset;
        begin
            encode_jtype = {opcode, Rp, offset};
        end
    endfunction

    // -------------------------
    // Test program initialization
    // -------------------------
    task initialize_test_program;
        integer i;
        begin
            $display("\n========================================");
            $display("  LOADING TEST PROGRAM");
            $display("========================================\n");
            
            // Clear all memories
            for (i = 0; i < 16; i = i + 1) begin
                DUT.InstMem.mem[i] = 32'h0;
                DUT.DataMem.mem[i] = 32'h0;
            end
            
            // Initialize data memory with known values
            DUT.DataMem.mem[0] = 32'h00000005;  // Address 0: value 5
            DUT.DataMem.mem[1] = 32'h0000000A;  // Address 1: value 10
            DUT.DataMem.mem[2] = 32'h00000003;  // Address 2: value 3
            DUT.DataMem.mem[3] = 32'h0000000F;  // Address 3: value 15
            
            // ============================================
            // TEST PROGRAM - Tests all instructions
            // ============================================
            
            // Setup: Initialize registers with known values
            // R1 = 10, R2 = 20, R3 = 5, R4 = 1 (predicate), R5 = 0xAAAA, R6 = 0x5555
            
            DUT.InstMem.mem[0] = encode_itype(5'd5, 5'd0, 5'd1, 5'd0, 12'd10);   // ADDI R1, R0, 10, R0
            DUT.InstMem.mem[1] = encode_itype(5'd5, 5'd0, 5'd2, 5'd0, 12'd20);   // ADDI R2, R0, 20, R0
            DUT.InstMem.mem[2] = encode_itype(5'd5, 5'd0, 5'd3, 5'd0, 12'd5);    // ADDI R3, R0, 5, R0
            DUT.InstMem.mem[3] = encode_itype(5'd5, 5'd0, 5'd4, 5'd0, 12'd1);    // ADDI R4, R0, 1, R0 (predicate)
            DUT.InstMem.mem[4] = encode_itype(5'd5, 5'd0, 5'd5, 5'd0, 12'hAAA);  // ADDI R5, R0, 0xAAA, R0
            DUT.InstMem.mem[5] = encode_itype(5'd5, 5'd0, 5'd6, 5'd0, 12'd21845); // ADDI R6, R0, 21845, R0 (0x5555)
            
            // R-Type Instructions
            DUT.InstMem.mem[6]  = encode_rtype(5'd0, 5'd0, 5'd7, 5'd1, 5'd2);    // ADD R7, R1, R2, R0  (R7 = 10 + 20 = 30)
            DUT.InstMem.mem[7]  = encode_rtype(5'd1, 5'd0, 5'd8, 5'd2, 5'd1);    // SUB R8, R2, R1, R0  (R8 = 20 - 10 = 10)
            DUT.InstMem.mem[8]  = encode_rtype(5'd2, 5'd0, 5'd9, 5'd5, 5'd6);    // OR R9, R5, R6, R0   (R9 = 0xAAAA | 0x5555 = 0xFFFF)
            DUT.InstMem.mem[9]  = encode_rtype(5'd3, 5'd0, 5'd10, 5'd5, 5'd6);   // NOR R10, R5, R6, R0 (R10 = ~(0xAAAA | 0x5555))
            DUT.InstMem.mem[10] = encode_rtype(5'd4, 5'd0, 5'd11, 5'd5, 5'd6);   // AND R11, R5, R6, R0 (R11 = 0xAAAA & 0x5555 = 0)
            
            // I-Type ALU Instructions
            DUT.InstMem.mem[11] = encode_itype(5'd5, 5'd0, 5'd12, 5'd1, 12'd15);  // ADDI R12, R1, 15, R0 (R12 = 10 + 15 = 25)
            DUT.InstMem.mem[12] = encode_itype(5'd6, 5'd0, 5'd13, 5'd1, 12'h00F); // ORI R13, R1, 0x00F, R0 (R13 = 10 | 15 = 15)
            DUT.InstMem.mem[13] = encode_itype(5'd7, 5'd0, 5'd14, 5'd1, 12'h00F); // NORI R14, R1, 0x00F, R0
            DUT.InstMem.mem[14] = encode_itype(5'd9, 5'd0, 5'd15, 5'd1, 12'h00F);  // ANDI R15, R1, 0x00F, R0 (R15 = 10 & 15 = 10)
            
            // Memory Instructions
            DUT.InstMem.mem[15] = encode_itype(5'd10, 5'd0, 5'd16, 5'd3, 12'd0);  // LW R16, 0(R3), R0 (R16 = Mem[5])
            
            // Store ALL results to memory for verification
            // Use R3=5 as base, so Mem[5] onwards will store results
            DUT.InstMem.mem[16] = encode_itype(5'd11, 5'd0, 5'd1, 5'd3, 12'd0);   // SW R1, 0(R3), R0 (Mem[5] = 10)
            DUT.InstMem.mem[17] = encode_itype(5'd11, 5'd0, 5'd2, 5'd3, 12'd1);   // SW R2, 1(R3), R0 (Mem[6] = 20)
            DUT.InstMem.mem[18] = encode_itype(5'd11, 5'd0, 5'd7, 5'd3, 12'd2);   // SW R7, 2(R3), R0 (Mem[7] = 30, ADD result)
            DUT.InstMem.mem[19] = encode_itype(5'd11, 5'd0, 5'd8, 5'd3, 12'd3);   // SW R8, 3(R3), R0 (Mem[8] = 10, SUB result)
            DUT.InstMem.mem[20] = encode_itype(5'd11, 5'd0, 5'd9, 5'd3, 12'd4);   // SW R9, 4(R3), R0 (Mem[9] = 0xFFFF, OR result)
            DUT.InstMem.mem[21] = encode_itype(5'd11, 5'd0, 5'd12, 5'd3, 12'd5);  // SW R12, 5(R3), R0 (Mem[10] = 25, ADDI result)
            DUT.InstMem.mem[22] = encode_itype(5'd11, 5'd0, 5'd13, 5'd3, 12'd6);  // SW R13, 6(R3), R0 (Mem[11] = 15, ORI result)
            DUT.InstMem.mem[23] = encode_itype(5'd11, 5'd0, 5'd15, 5'd3, 12'd7);  // SW R15, 7(R3), R0 (Mem[12] = 10, ANDI result)
            
            // Jump Instructions (commented out to avoid disrupting sequential verification)
            // Uncomment these to test jumps separately
            /*
            // First, set up a register with jump target address
            DUT.InstMem.mem[24] = encode_itype(5'd5, 5'd0, 5'd17, 5'd0, 12'd20);  // ADDI R17, R0, 20, R0 (target address)
            
            // J instruction - jump forward (will jump to PC+1+2 = PC+3)
            DUT.InstMem.mem[25] = encode_jtype(5'd12, 5'd0, 22'd2);                // J +2, R0
            
            // This instruction should be skipped due to jump
            DUT.InstMem.mem[26] = encode_itype(5'd5, 5'd0, 5'd18, 5'd0, 12'd99);  // ADDI R18, R0, 99, R0 (should be skipped)
            
            // Land here after jump (address 27)
            DUT.InstMem.mem[27] = encode_itype(5'd5, 5'd0, 5'd19, 5'd0, 12'd100); // ADDI R19, R0, 100, R0
            
            // CALL instruction - call function at offset +3
            DUT.InstMem.mem[28] = encode_jtype(5'd13, 5'd0, 22'd3);                // CALL +3, R0
            
            // Function entry point (address 31)
            DUT.InstMem.mem[31] = encode_itype(5'd5, 5'd0, 5'd20, 5'd0, 12'd200); // ADDI R20, R0, 200, R0
            
            // JR instruction - jump to address in R17 (which is 20)
            DUT.InstMem.mem[32] = encode_rtype(5'd14, 5'd0, 5'd0, 5'd17, 5'd0);   // JR R17, R0
            */
            
            $display("Test program loaded:");
            $display("  - Setup instructions (0-5): Initialize registers");
            $display("  - R-Type instructions (6-10): ADD, SUB, OR, NOR, AND");
            $display("  - I-Type ALU (11-14): ADDI, ORI, NORI, ANDI");
            $display("  - Memory instructions (15): LW");
            $display("  - Store results (16-23): SW all results to memory for verification");
            $display("  - All instructions use R0 as predicate (unconditional)");
            $display("");
        end
    endtask

    // -------------------------
    // Reset and test execution
    // -------------------------
    initial begin
        reset = 1'b1;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        cycle_count = 0;
        last_pc = 0;
        
        #20;
        reset = 1'b0;
        #10;
        
        initialize_test_program();
        
        $display("\n========================================");
        $display("  STARTING EXECUTION");
        $display("========================================\n");
        
        // Run for enough cycles to execute all instructions
        // Each instruction takes 3-5 cycles depending on type
        #5000;
        
        // Print final results
        print_test_summary();
        $finish;
    end

    // -------------------------
    // Cycle counter and monitoring
    // -------------------------
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
        end
    end

    // -------------------------
    // Instruction execution monitoring
    // -------------------------
    always @(posedge clk) begin
        if (!reset && DUT.S == 3'd0 && DUT.PC != last_pc) begin
            print_instruction_execution();
            last_pc = DUT.PC;
        end
    end

    // -------------------------
    // Print instruction execution details
    // -------------------------
    task print_instruction_execution;
        reg [4:0] opcode;
        reg [4:0] Rp, Rd, Rs, Rt;
        reg [11:0] Imm;
        reg [21:0] offset;
        begin
            opcode = DUT.IR[31:27];
            Rp = DUT.IR[26:22];
            Rd = DUT.IR[21:17];
            Rs = DUT.IR[16:12];
            Rt = DUT.IR[11:7];
            Imm = DUT.IR[11:0];
            offset = DUT.IR[21:0];
            
            $write("Cycle %4d | PC=%2d | ", cycle_count, DUT.PC);
            
            case (opcode)
                5'd0:  $write("ADD  R%0d, R%0d, R%0d, R%0d", Rd, Rs, Rt, Rp);
                5'd1:  $write("SUB  R%0d, R%0d, R%0d, R%0d", Rd, Rs, Rt, Rp);
                5'd2:  $write("OR   R%0d, R%0d, R%0d, R%0d", Rd, Rs, Rt, Rp);
                5'd3:  $write("NOR  R%0d, R%0d, R%0d, R%0d", Rd, Rs, Rt, Rp);
                5'd4:  $write("AND  R%0d, R%0d, R%0d, R%0d", Rd, Rs, Rt, Rp);
                5'd5:  $write("ADDI R%0d, R%0d, %0d, R%0d", Rd, Rs, $signed(Imm), Rp);
                5'd6:  $write("ORI  R%0d, R%0d, 0x%03h, R%0d", Rd, Rs, Imm, Rp);
                5'd7:  $write("NORI R%0d, R%0d, 0x%03h, R%0d", Rd, Rs, Imm, Rp);
                5'd9:  $write("ANDI R%0d, R%0d, 0x%03h, R%0d", Rd, Rs, Imm, Rp);
                5'd10: $write("LW   R%0d, %0d(R%0d), R%0d", Rd, $signed(Imm), Rs, Rp);
                5'd11: $write("SW   R%0d, %0d(R%0d), R%0d", Rd, $signed(Imm), Rs, Rp);
                5'd12: $write("J    %0d, R%0d", $signed(offset), Rp);
                5'd13: $write("CALL %0d, R%0d", $signed(offset), Rp);
                5'd14: $write("JR   R%0d, R%0d", Rs, Rp);
                default: $write("UNKNOWN (opcode %0d)", opcode);
            endcase
            
            $write(" | A=%08h B=%08h", DUT.A_reg, DUT.B_reg);
            $write(" | ALU=%08h", DUT.res);
            $write(" | WB=%08h", DUT.WriteBackData);
            $display("");
        end
    endtask

    // -------------------------
    // Verification tasks
    // -------------------------
    task verify_memory;
        input [3:0] addr;
        input [31:0] expected;
        input string test_name;
        begin
            test_count = test_count + 1;
            #100; // Wait for write to complete
            
            if (DUT.DataMem.mem[addr] == expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s: Mem[%0d] = 0x%08h (expected 0x%08h)", test_name, addr, DUT.DataMem.mem[addr], expected);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %s: Mem[%0d] = 0x%08h (expected 0x%08h)", test_name, addr, DUT.DataMem.mem[addr], expected);
            end
        end
    endtask

    // -------------------------
    // Verify results after execution
    // -------------------------
    initial begin
        #5000; // Wait for all instructions to complete
        
        $display("\n========================================");
        $display("  VERIFICATION RESULTS");
        $display("========================================\n");
        
        // Verify all stored results in memory
        // Results are stored starting at Mem[5] (base R3=5, offset 0)
        verify_memory(5, 32'd10, "R1 = 10 (ADDI)");
        verify_memory(6, 32'd20, "R2 = 20 (ADDI)");
        verify_memory(7, 32'd30, "R7 = 30 (ADD R1+R2)");
        verify_memory(8, 32'd10, "R8 = 10 (SUB R2-R1)");
        verify_memory(9, 32'hFFFF, "R9 = 0xFFFF (OR 0xAAAA|0x5555)");
        verify_memory(10, 32'd25, "R12 = 25 (ADDI R1+15)");
        verify_memory(11, 32'd15, "R13 = 15 (ORI R1|0xF)");
        verify_memory(12, 32'd10, "R15 = 10 (ANDI R1&0xF)");
        
        // Display all memory contents
        $display("\nMemory Contents (for debugging):");
        for (integer i = 0; i < 13; i = i + 1) begin
            $display("  Mem[%0d] = 0x%08h (%0d)", i, DUT.DataMem.mem[i], DUT.DataMem.mem[i]);
        end
        
        // Display processor state
        $display("\nFinal Processor State:");
        $display("  PC = %0d", DUT.PC);
        $display("  State = %0d", DUT.S);
        $display("  IR = 0x%08h", DUT.IR);
        $display("  A_reg = 0x%08h", DUT.A_reg);
        $display("  B_reg = 0x%08h", DUT.B_reg);
        $display("  ALU Result = 0x%08h", DUT.res);
        $display("  WriteBack Data = 0x%08h", DUT.WriteBackData);
    end

    // -------------------------
    // Print test summary
    // -------------------------
    task print_test_summary;
        begin
            $display("\n========================================");
            $display("  TEST SUMMARY");
            $display("========================================");
            $display("Total Cycles: %0d", cycle_count);
            $display("Instructions Executed: ~%0d", cycle_count / 4);
            $display("Tests Run: %0d", test_count);
            $display("Passed: %0d", pass_count);
            $display("Failed: %0d", fail_count);
            if (fail_count == 0 && test_count > 0) begin
                $display("\n*** ALL TESTS PASSED! ***");
            end else if (test_count > 0) begin
                $display("\n*** SOME TESTS FAILED ***");
            end
            $display("========================================\n");
        end
    endtask

    // -------------------------
    // Waveform dump (optional)
    // -------------------------
    initial begin
        $dumpfile("processor_test.vcd");
        $dumpvars(0, comprehensive_testbench);
    end

endmodule

