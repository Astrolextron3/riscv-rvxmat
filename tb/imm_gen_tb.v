`timescale 1ns/1ps

module imm_gen_tb;

    reg  [31:0] instr;
    wire [31:0] imm;

    imm_gen uut (
        .instr(instr),
        .imm(imm)
    );

    initial begin
        $dumpfile("imm_gen.vcd");
        $dumpvars(0, imm_gen_tb);

        // TEST 1 — I-type positive: ADDI x1, x2, 5
        // imm=000000000101 rs1=00010 funct3=000 rd=00001 opcode=0010011
        instr = 32'b000000000101_00010_000_00001_0010011;
        #10;
        $display("TEST 1 - I-type positive: expected 5, got %0d %s",
            $signed(imm), $signed(imm) == 32'sd5 ? "PASS" : "FAIL");

        // TEST 2 — I-type negative: ADDI x1, x2, -1
        // imm=111111111111 rs1=00010 funct3=000 rd=00001 opcode=0010011
        instr = 32'b111111111111_00010_000_00001_0010011;
        #10;
        $display("TEST 2 - I-type negative: expected -1, got %0d %s",
            $signed(imm), $signed(imm) == -32'sd1 ? "PASS" : "FAIL");

        // TEST 3 — S-type: SW x2, 8(x1)
        // imm[11:5]=0000000 rs2=00010 rs1=00001 funct3=010 imm[4:0]=01000 opcode=0100011
        // immediate = 8 = 0b000000001000
        // imm[11:5] = 0000000, imm[4:0] = 01000
        instr = 32'b0000000_00010_00001_010_01000_0100011;
        #10;
        $display("TEST 3 - S-type: expected 8, got %0d %s",
            $signed(imm), $signed(imm) == 32'sd8 ? "PASS" : "FAIL");

        // TEST 4 — B-type: BEQ x1, x2, 16
        // immediate = 16 = 0b000000010000
        // imm[12]=0 imm[10:5]=000100 imm[4:1]=0000 imm[11]=0
        // instr: imm[12|10:5] rs2 rs1 funct3 imm[4:1|11] opcode
        instr = 32'b0_000000_00010_00001_000_1000_0_1100011;
        #10;
        $display("TEST 4 - B-type: expected 16, got %0d %s",
            $signed(imm), $signed(imm) == 32'sd16 ? "PASS" : "FAIL");
        // TEST 5 — U-type: LUI x1, 1
        // imm[31:12]=00000000000000000001 rd=00001 opcode=0110111
        instr = 32'b00000000000000000001_00001_0110111;
        #10;
        $display("TEST 5 - U-type: expected 4096, got %0d %s",
            imm, imm == 32'd4096 ? "PASS" : "FAIL");

        // TEST 6 — J-type: JAL x0, 8
        // immediate = 8 = 0b000000001000
        // imm[20|10:1|11|19:12]
        instr = 32'b0_0000000100_0_00000000_00000_1101111;
        #10;
        $display("TEST 6 - J-type: expected 8, got %0d %s",
            $signed(imm), $signed(imm) == 32'sd8 ? "PASS" : "FAIL");

        $finish;
    end

endmodule