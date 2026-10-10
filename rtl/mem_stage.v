module mem_stage (
    input         clk,
    input         mem_mem_write, mem_mem_read,
    input  [2:0]  mem_funct3,
    input  [31:0] mem_alu_result,
    input  [31:0] mem_rd2,
    output [31:0] mem_read_data
);
    memory dmem (
        .clk        (clk),
        .mem_write  (mem_mem_write),
        .mem_read   (mem_mem_read),
        .funct3     (mem_funct3),
        .addr       (mem_alu_result),
        .write_data (mem_rd2),
        .read_data  (mem_read_data)
    );

endmodule