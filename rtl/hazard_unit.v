module hazard_unit (
    input  [4:0]  id_rs1, id_rs2,
    input  [4:0]  ex_rd,
    input         ex_mem_read,
    output reg    stall,
    output reg    if_id_flush
);
    always @(*) begin
        // load-use hazard detection
        if (ex_mem_read &&
            (ex_rd == id_rs1 || ex_rd == id_rs2)) begin
            stall      = 1'b1;
            if_id_flush = 1'b1;
        end else begin
            stall      = 1'b0;
            if_id_flush = 1'b0;
        end
    end

endmodule