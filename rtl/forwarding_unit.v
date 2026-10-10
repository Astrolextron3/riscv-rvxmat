module forwarding_unit (
    input  [4:0]  ex_rs1, ex_rs2,
    input  [4:0]  mem_rd, wb_rd,
    input         mem_reg_write, wb_reg_write,
    output reg [1:0] fwd_a, fwd_b
);
    always @(*) begin
        // forward A
        if (mem_reg_write && mem_rd != 5'b0 && mem_rd == ex_rs1)
            fwd_a = 2'b10;  // forward from MEM stage
        else if (wb_reg_write && wb_rd != 5'b0 && wb_rd == ex_rs1)
            fwd_a = 2'b01;  // forward from WB stage
        else
            fwd_a = 2'b00;  // no forwarding

        // forward B
        if (mem_reg_write && mem_rd != 5'b0 && mem_rd == ex_rs2)
            fwd_b = 2'b10;  // forward from MEM stage
        else if (wb_reg_write && wb_rd != 5'b0 && wb_rd == ex_rs2)
            fwd_b = 2'b01;  // forward from WB stage
        else
            fwd_b = 2'b00;  // no forwarding
    end

endmodule