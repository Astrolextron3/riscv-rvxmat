module id_ex_reg (
    input         clk, rst, flush,
    input  [31:0] id_pc,
    input  [31:0] id_rd1, id_rd2, id_imm,
    input  [4:0]  id_rs1, id_rs2, id_rd,
    input  [3:0]  id_alu_ctrl,
    input         id_alu_src, id_mem_write, id_mem_read,
    input         id_mem_to_reg, id_reg_write,
    input  [2:0]  id_funct3,
    input         id_mac_en, id_clr_en,
    output reg [31:0] ex_pc,
    output reg [31:0] ex_rd1, ex_rd2, ex_imm,
    output reg [4:0]  ex_rs1, ex_rs2, ex_rd,
    output reg [3:0]  ex_alu_ctrl,
    output reg        ex_alu_src, ex_mem_write, ex_mem_read,
    output reg        ex_mem_to_reg, ex_reg_write,
    output reg [2:0]  ex_funct3,
    output reg        ex_mac_en, ex_clr_en
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            ex_pc         <= 32'b0;
            ex_rd1        <= 32'b0;
            ex_rd2        <= 32'b0;
            ex_imm        <= 32'b0;
            ex_rs1        <= 5'b0;
            ex_rs2        <= 5'b0;
            ex_rd         <= 5'b0;
            ex_alu_ctrl   <= 4'b0;
            ex_alu_src    <= 1'b0;
            ex_mem_write  <= 1'b0;
            ex_mem_read   <= 1'b0;
            ex_mem_to_reg <= 1'b0;
            ex_reg_write  <= 1'b0;
            ex_funct3     <= 3'b0;
            ex_mac_en     <= 1'b0;
            ex_clr_en     <= 1'b0;
        end else begin
            ex_pc         <= id_pc;
            ex_rd1        <= id_rd1;
            ex_rd2        <= id_rd2;
            ex_imm        <= id_imm;
            ex_rs1        <= id_rs1;
            ex_rs2        <= id_rs2;
            ex_rd         <= id_rd;
            ex_alu_ctrl   <= id_alu_ctrl;
            ex_alu_src    <= id_alu_src;
            ex_mem_write  <= id_mem_write;
            ex_mem_read   <= id_mem_read;
            ex_mem_to_reg <= id_mem_to_reg;
            ex_reg_write  <= id_reg_write;
            ex_funct3     <= id_funct3;
            ex_mac_en     <= id_mac_en;
            ex_clr_en     <= id_clr_en;
        end
    end
endmodule