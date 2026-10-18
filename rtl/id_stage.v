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
    output [3:0]  id_alu_ctrl,
    // RVX-MAT control (custom-0 opcode 0001011)
    output        id_mac_en, id_clr_en
);
    assign id_rs1   = id_instr[19:15];
    assign id_rs2   = id_instr[24:20];
    assign id_rd    = id_instr[11:7];
    assign id_funct3 = id_instr[14:12];

    wire [31:0] rf_rd1, rf_rd2;

    regfile rf (
        .clk (clk),
        .we  (we),
        .rs1 (id_rs1),
        .rs2 (id_rs2),
        .rd  (wb_rd),
        .wd  (wb_data),
        .rd1 (rf_rd1),
        .rd2 (rf_rd2)
    );

    // Write-through bypass. WB writes the register file on the clock edge, so an
    // instruction that is in ID in the same cycle as its producer is in WB (3
    // instructions apart) would otherwise latch the OLD value into ID/EX, and the
    // forwarding unit can no longer help because the producer has left the pipe.
    // (Kept here, not in regfile.v, so the single-cycle tops see no comb. loop.)
    wire byp1 = we && (wb_rd != 5'b0) && (wb_rd == id_rs1);
    wire byp2 = we && (wb_rd != 5'b0) && (wb_rd == id_rs2);
    assign id_rd1 = byp1 ? wb_data : rf_rd1;
    assign id_rd2 = byp2 ? wb_data : rf_rd2;

    imm_gen ig (
        .instr (id_instr),
        .imm   (id_imm)
    );

    wire dec_reg_write;

    decoder dec (
        .instr      (id_instr),
        .reg_write  (dec_reg_write),
        .alu_src    (id_alu_src),
        .mem_write  (id_mem_write),
        .mem_read   (id_mem_read),
        .mem_to_reg (id_mem_to_reg),
        .branch     (id_branch),
        .jump       (id_jump),
        .alu_ctrl   (id_alu_ctrl)
    );

    wire rvx_reg_write;

    rvxmat_decoder RVXDEC (
        .instr            (id_instr),
        .mac_en           (id_mac_en),
        .clr_en           (id_clr_en),
        .rvxmat_reg_write (rvx_reg_write),
        .rvxmat_rd        (),
        .rvxmat_rs1       (),
        .rvxmat_rs2       ()
    );

    // rd/rs1/rs2 of the custom R-type format sit in the standard fields, so the
    // normal id_rs1/id_rs2/id_rd above already serve VCLR/VMAC.
    assign id_reg_write = dec_reg_write | rvx_reg_write;

endmodule
