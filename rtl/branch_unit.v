module branch_unit (
    input         ex_branch, ex_jump,
    input         ex_zero,
    input  [2:0]  ex_funct3,
    input  [31:0] ex_alu_result,
    input  [31:0] ex_branch_target,
    output reg    pc_src,
    output reg    id_ex_flush,
    output [31:0] branch_target
);
    assign branch_target = ex_branch_target;

    always @(*) begin
        id_ex_flush = 1'b0;
        pc_src      = 1'b0;

        if (ex_jump) begin
            pc_src      = 1'b1;
            id_ex_flush = 1'b1;
        end else if (ex_branch) begin
            case (ex_funct3)
                3'b000: begin // BEQ
                    if (ex_zero) begin
                        pc_src      = 1'b1;
                        id_ex_flush = 1'b1;
                    end
                end
                3'b001: begin // BNE
                    if (!ex_zero) begin
                        pc_src      = 1'b1;
                        id_ex_flush = 1'b1;
                    end
                end
                3'b100: begin // BLT
                    if (ex_alu_result == 32'b1) begin
                        pc_src      = 1'b1;
                        id_ex_flush = 1'b1;
                    end
                end
                3'b101: begin // BGE
                    if (ex_alu_result == 32'b0) begin
                        pc_src      = 1'b1;
                        id_ex_flush = 1'b1;
                    end
                end
                default: pc_src = 1'b0;
            endcase
        end
    end

endmodule