module top_pipeline (
    input         clk, rst,
    output [31:0] pc_out
);

    // IF stage
    wire [31:0] if_pc, if_instr;

    // IF/ID register outputs
    wire [31:0] id_pc, id_instr;

    // ID stage outputs
    wire [31:0] id_rd1, id_rd2, id_imm;
    wire [4:0]  id_rs1, id_rs2, id_rd;
    wire [2:0]  id_funct3;
    wire        id_reg_write, id_alu_src;
    wire        id_mem_write, id_mem_read;
    wire        id_mem_to_reg, id_branch, id_jump;
    wire [3:0]  id_alu_ctrl;

    // ID/EX register outputs
    wire [31:0] ex_pc, ex_rd1, ex_rd2, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [3:0]  ex_alu_ctrl;
    wire        ex_alu_src, ex_mem_write, ex_mem_read;
    wire        ex_mem_to_reg, ex_reg_write;
    wire [2:0]  ex_funct3;

    // EX stage outputs
    wire [31:0] ex_alu_result, ex_rd2_out;
    wire        ex_zero;
    wire [31:0] ex_branch_target;

    // EX/MEM register outputs
    wire [31:0] mem_alu_result, mem_rd2;
    wire [4:0]  mem_rd;
    wire        mem_mem_write, mem_mem_read;
    wire        mem_mem_to_reg, mem_reg_write;
    wire [2:0]  mem_funct3;
    wire        mem_zero;

    // MEM stage outputs
    wire [31:0] mem_read_data;

    // MEM/WB register outputs
    wire [31:0] wb_read_data, wb_alu_result;
    wire [4:0]  wb_rd;
    wire        wb_mem_to_reg, wb_reg_write;

    // WB stage outputs
    wire [31:0] wb_data;

    // control wires
    wire        stall, if_id_flush_hz, id_ex_flush_br;
    wire        pc_src;
    wire [31:0] branch_target;
    wire [1:0]  fwd_a, fwd_b;

    wire if_id_flush = if_id_flush_hz | id_ex_flush_br;
    wire id_ex_flush = id_ex_flush_br;

    // ── Instantiations ─────────────────────────────────────

    if_stage IF (
        .clk           (clk),
        .rst           (rst),
        .stall         (stall),
        .pc_src        (pc_src),
        .branch_target (branch_target),
        .if_pc         (if_pc),
        .if_instr      (if_instr)
    );

    if_id_reg IF_ID (
        .clk      (clk),
        .rst      (rst),
        .stall    (stall),
        .flush    (if_id_flush),
        .if_pc    (if_pc),
        .if_instr (if_instr),
        .id_pc    (id_pc),
        .id_instr (id_instr)
    );

    id_stage ID (
        .id_pc        (id_pc),
        .id_instr     (id_instr),
        .clk          (clk),
        .we           (wb_reg_write),
        .wb_rd        (wb_rd),
        .wb_data      (wb_data),
        .id_rd1       (id_rd1),
        .id_rd2       (id_rd2),
        .id_imm       (id_imm),
        .id_rs1       (id_rs1),
        .id_rs2       (id_rs2),
        .id_rd        (id_rd),
        .id_funct3    (id_funct3),
        .id_reg_write (id_reg_write),
        .id_alu_src   (id_alu_src),
        .id_mem_write (id_mem_write),
        .id_mem_read  (id_mem_read),
        .id_mem_to_reg(id_mem_to_reg),
        .id_branch    (id_branch),
        .id_jump      (id_jump),
        .id_alu_ctrl  (id_alu_ctrl)
    );

    id_ex_reg ID_EX (
        .clk          (clk),
        .rst          (rst),
        .flush        (id_ex_flush),
        .id_pc        (id_pc),
        .id_rd1       (id_rd1),
        .id_rd2       (id_rd2),
        .id_imm       (id_imm),
        .id_rs1       (id_rs1),
        .id_rs2       (id_rs2),
        .id_rd        (id_rd),
        .id_alu_ctrl  (id_alu_ctrl),
        .id_alu_src   (id_alu_src),
        .id_mem_write (id_mem_write),
        .id_mem_read  (id_mem_read),
        .id_mem_to_reg(id_mem_to_reg),
        .id_reg_write (id_reg_write),
        .id_funct3    (id_funct3),
        .ex_pc        (ex_pc),
        .ex_rd1       (ex_rd1),
        .ex_rd2       (ex_rd2),
        .ex_imm       (ex_imm),
        .ex_rs1       (ex_rs1),
        .ex_rs2       (ex_rs2),
        .ex_rd        (ex_rd),
        .ex_alu_ctrl  (ex_alu_ctrl),
        .ex_alu_src   (ex_alu_src),
        .ex_mem_write (ex_mem_write),
        .ex_mem_read  (ex_mem_read),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_reg_write (ex_reg_write),
        .ex_funct3    (ex_funct3)
    );

    ex_stage EX (
        .ex_rd1           (ex_rd1),
        .ex_rd2           (ex_rd2),
        .ex_imm           (ex_imm),
        .ex_pc            (ex_pc),
        .ex_alu_ctrl      (ex_alu_ctrl),
        .ex_alu_src       (ex_alu_src),
        .fwd_a            (fwd_a),
        .fwd_b            (fwd_b),
        .mem_alu_result   (mem_alu_result),
        .wb_data          (wb_data),
        .ex_alu_result    (ex_alu_result),
        .ex_rd2_out       (ex_rd2_out),
        .ex_zero          (ex_zero),
        .ex_branch_target (ex_branch_target)
    );

    ex_mem_reg EX_MEM (
        .clk           (clk),
        .rst           (rst),
        .ex_alu_result (ex_alu_result),
        .ex_rd2        (ex_rd2_out),
        .ex_rd         (ex_rd),
        .ex_mem_write  (ex_mem_write),
        .ex_mem_read   (ex_mem_read),
        .ex_mem_to_reg (ex_mem_to_reg),
        .ex_reg_write  (ex_reg_write),
        .ex_funct3     (ex_funct3),
        .ex_zero       (ex_zero),
        .mem_alu_result(mem_alu_result),
        .mem_rd2       (mem_rd2),
        .mem_rd        (mem_rd),
        .mem_mem_write (mem_mem_write),
        .mem_mem_read  (mem_mem_read),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_reg_write (mem_reg_write),
        .mem_funct3    (mem_funct3),
        .mem_zero      (mem_zero)
    );

    mem_stage MEM (
        .clk           (clk),
        .mem_mem_write (mem_mem_write),
        .mem_mem_read  (mem_mem_read),
        .mem_funct3    (mem_funct3),
        .mem_alu_result(mem_alu_result),
        .mem_rd2       (mem_rd2),
        .mem_read_data (mem_read_data)
    );

    mem_wb_reg MEM_WB (
        .clk           (clk),
        .rst           (rst),
        .mem_read_data (mem_read_data),
        .mem_alu_result(mem_alu_result),
        .mem_rd        (mem_rd),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_reg_write (mem_reg_write),
        .wb_read_data  (wb_read_data),
        .wb_alu_result (wb_alu_result),
        .wb_rd         (wb_rd),
        .wb_mem_to_reg (wb_mem_to_reg),
        .wb_reg_write  (wb_reg_write)
    );

    wb_stage WB (
        .wb_mem_to_reg(wb_mem_to_reg),
        .wb_read_data (wb_read_data),
        .wb_alu_result(wb_alu_result),
        .wb_data      (wb_data)
    );

    hazard_unit HZ (
        .id_rs1      (id_rs1),
        .id_rs2      (id_rs2),
        .ex_rd       (ex_rd),
        .ex_mem_read (ex_mem_read),
        .stall       (stall),
        .if_id_flush (if_id_flush_hz)
    );

    forwarding_unit FWD (
        .ex_rs1       (ex_rs1),
        .ex_rs2       (ex_rs2),
        .mem_rd       (mem_rd),
        .wb_rd        (wb_rd),
        .mem_reg_write(mem_reg_write),
        .wb_reg_write (wb_reg_write),
        .fwd_a        (fwd_a),
        .fwd_b        (fwd_b)
    );

    branch_unit BR (
        .ex_branch        (id_branch),
        .ex_jump          (id_jump),
        .ex_zero          (ex_zero),
        .ex_funct3        (ex_funct3),
        .ex_alu_result    (ex_alu_result),
        .ex_branch_target (ex_branch_target),
        .pc_src           (pc_src),
        .id_ex_flush      (id_ex_flush_br),
        .branch_target    (branch_target)
    );

    assign pc_out = if_pc;

endmodule