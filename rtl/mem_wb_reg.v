module mem_wb_reg (
    input         clk, rst,
    input  [31:0] mem_read_data,
    input  [31:0] mem_alu_result,
    input  [4:0]  mem_rd,
    input         mem_mem_to_reg, mem_reg_write,
    output reg [31:0] wb_read_data,
    output reg [31:0] wb_alu_result,
    output reg [4:0]  wb_rd,
    output reg        wb_mem_to_reg, wb_reg_write
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_read_data   <= 32'b0;
            wb_alu_result  <= 32'b0;
            wb_rd          <= 5'b0;
            wb_mem_to_reg  <= 1'b0;
            wb_reg_write   <= 1'b0;
        end else begin
            wb_read_data   <= mem_read_data;
            wb_alu_result  <= mem_alu_result;
            wb_rd          <= mem_rd;
            wb_mem_to_reg  <= mem_mem_to_reg;
            wb_reg_write   <= mem_reg_write;
        end
    end
endmodule