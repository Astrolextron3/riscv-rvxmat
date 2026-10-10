module wb_stage (
    input         wb_mem_to_reg,
    input  [31:0] wb_read_data,
    input  [31:0] wb_alu_result,
    output [31:0] wb_data
);
    assign wb_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

endmodule