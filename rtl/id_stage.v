module id_stage (
    input  [31:0] id_pc,
    input  [31:0] id_instr,
    input         clk,
    input         we,
    input  [4:0]  wb_rd,
    input  [31:0] wb_data,
    output [31:0] id_rd1, id_rd2,
    output [31:0] id_imm,
    output [4:0]  id_rs1, id_rs2, id_rd,
    output [2:0]  id_funct3,
    output        id_reg_write, id_alu_src,
    output        id_mem_write, id_mem_read,
    output        id_mem_to_reg, id_branch, id_jump,
    output [3:0]  id_alu_ctrl
);
    assign id_rs1   = id_instr[19:15];
    assign id_rs2   = id_instr[24:20];
    assign id_rd    = id_instr[11:7];
    assign id_funct3 = id_instr[14:12];

    regfile rf (
        .clk (clk),
        .we  (we),
        .rs1 (id_rs1),
        .rs2 (id_rs2),
        .rd  (wb_rd),
        .wd  (wb_data),
        .rd1 (id_rd1),
        .rd2 (id_rd2)
    );

    imm_gen ig (
        .instr (id_instr),
        .imm   (id_imm)
    );

    decoder dec (
        .instr      (id_instr),
        .reg_write  (id_reg_write),
        .alu_src    (id_alu_src),
        .mem_write  (id_mem_write),
        .mem_read   (id_mem_read),
        .mem_to_reg (id_mem_to_reg),
        .branch     (id_branch),
        .jump       (id_jump),
        .alu_ctrl   (id_alu_ctrl)
    );

endmodule