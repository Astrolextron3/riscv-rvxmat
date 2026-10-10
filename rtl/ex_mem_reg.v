module ex_mem_reg (
    input         clk, rst,
    input  [31:0] ex_alu_result,
    input  [31:0] ex_rd2,
    input  [4:0]  ex_rd,
    input         ex_mem_write, ex_mem_read,
    input         ex_mem_to_reg, ex_reg_write,
    input  [2:0]  ex_funct3,
    input         ex_zero,
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rd2,
    output reg [4:0]  mem_rd,
    output reg        mem_mem_write, mem_mem_read,
    output reg        mem_mem_to_reg, mem_reg_write,
    output reg [2:0]  mem_funct3,
    output reg        mem_zero
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_alu_result <= 32'b0;
            mem_rd2        <= 32'b0;
            mem_rd         <= 5'b0;
            mem_mem_write  <= 1'b0;
            mem_mem_read   <= 1'b0;
            mem_mem_to_reg <= 1'b0;
            mem_reg_write  <= 1'b0;
            mem_funct3     <= 3'b0;
            mem_zero       <= 1'b0;
        end else begin
            mem_alu_result <= ex_alu_result;
            mem_rd2        <= ex_rd2;
            mem_rd         <= ex_rd;
            mem_mem_write  <= ex_mem_write;
            mem_mem_read   <= ex_mem_read;
            mem_mem_to_reg <= ex_mem_to_reg;
            mem_reg_write  <= ex_reg_write;
            mem_funct3     <= ex_funct3;
            mem_zero       <= ex_zero;
        end
    end
endmodule