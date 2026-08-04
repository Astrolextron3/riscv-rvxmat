`timescale 1ns/1ps

module decoder_tb;

    reg  [31:0] instr;
    wire        reg_write, alu_src, mem_write;
    wire        mem_read, mem_to_reg, branch, jump;
    wire [3:0]  alu_ctrl;

    decoder uut (
        .instr     (instr),
        .reg_write (reg_write),
        .alu_src   (alu_src),
        .mem_write (mem_write),
        .mem_read  (mem_read),
        .mem_to_reg(mem_to_reg),
        .branch    (branch),
        .jump      (jump),
        .alu_ctrl  (alu_ctrl)
    );

    task check;
        input [8*20:1] name;
        input exp_rw, exp_as, exp_mw, exp_mr, exp_m2r, exp_br, exp_jmp;
        input [3:0] exp_alu;
        begin
            if (reg_write  == exp_rw  &&
                alu_src    == exp_as  &&
                mem_write  == exp_mw  &&
                mem_read   == exp_mr  &&
                mem_to_reg == exp_m2r &&
                branch     == exp_br  &&
                jump       == exp_jmp &&
                alu_ctrl   == exp_alu)
                $display("%s PASS", name);
            else
                $display("%s FAIL | rw=%b as=%b mw=%b mr=%b m2r=%b br=%b jmp=%b alu=%b",
                    name,
                    reg_write, alu_src, mem_write, mem_read,
                    mem_to_reg, branch, jump, alu_ctrl);
        end
    endtask

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, decoder_tb);

        // TEST 1 — R-type ADD
        // funct7=0000000 rs2=00001 rs1=00010 funct3=000 rd=00001 opcode=0110011
        instr = 32'b0000000_00001_00010_000_00001_0110011;
        #10;
        //                    rw as mw mr m2r br jmp alu
        check("TEST 1 ADD  ", 1, 0, 0, 0,  0,  0,  0, 4'b0000);

        // TEST 2 — R-type SUB
        // funct7=0100000 rs2=00001 rs1=00010 funct3=000 rd=00001 opcode=0110011
        instr = 32'b0100000_00001_00010_000_00001_0110011;
        #10;
        check("TEST 2 SUB  ", 1, 0, 0, 0,  0,  0,  0, 4'b0001);

        // TEST 3 — R-type AND
        // funct3=111
        instr = 32'b0000000_00001_00010_111_00001_0110011;
        #10;
        check("TEST 3 AND  ", 1, 0, 0, 0,  0,  0,  0, 4'b0010);

        // TEST 4 — I-type ADDI
        // imm=000000000001 rs1=00001 funct3=000 rd=00001 opcode=0010011
        instr = 32'b000000000001_00001_000_00001_0010011;
        #10;
        check("TEST 4 ADDI ", 1, 1, 0, 0,  0,  0,  0, 4'b0000);

        // TEST 5 — I-type LW
        // imm=000000000100 rs1=00001 funct3=010 rd=00001 opcode=0000011
        instr = 32'b000000000100_00001_010_00001_0000011;
        #10;
        check("TEST 5 LW   ", 1, 1, 0, 1,  1,  0,  0, 4'b0000);

        // TEST 6 — S-type SW
        // imm[11:5]=0000000 rs2=00010 rs1=00001 funct3=010 imm[4:0]=00100 opcode=0100011
        instr = 32'b0000000_00010_00001_010_00100_0100011;
        #10;
        check("TEST 6 SW   ", 0, 1, 1, 0,  0,  0,  0, 4'b0000);

        // TEST 7 — B-type BEQ
        // imm=0 rs2=00010 rs1=00001 funct3=000 imm=0 opcode=1100011
        instr = 32'b0_000000_00010_00001_000_0000_0_1100011;
        #10;
        check("TEST 7 BEQ  ", 0, 0, 0, 0,  0,  1,  0, 4'b0001);

        // TEST 8 — U-type LUI
        // imm=00000000000000000001 rd=00001 opcode=0110111
        instr = 32'b00000000000000000001_00001_0110111;
        #10;
        check("TEST 8 LUI  ", 1, 1, 0, 0,  0,  0,  0, 4'b0000);

        // TEST 9 — J-type JAL
        // imm=0 rd=00001 opcode=1101111
        instr = 32'b0_0000000000_0_00000000_00001_1101111;
        #10;
        check("TEST 9 JAL  ", 1, 0, 0, 0,  0,  0,  1, 4'b0000);

        // TEST 10 — I-type JALR
        // imm=000000000000 rs1=00001 funct3=000 rd=00001 opcode=1100111
        instr = 32'b000000000000_00001_000_00001_1100111;
        #10;
        check("TEST 10 JALR", 1, 1, 0, 0,  0,  0,  1, 4'b0000);

        $finish;
    end

endmodule