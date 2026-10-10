module ex_stage (
    input  [31:0] ex_rd1, ex_rd2, ex_imm,
    input  [31:0] ex_pc,
    input  [3:0]  ex_alu_ctrl,
    input         ex_alu_src,
    input  [1:0]  fwd_a, fwd_b,
    input  [31:0] mem_alu_result,
    input  [31:0] wb_data,
    output [31:0] ex_alu_result,
    output [31:0] ex_rd2_out,
    output        ex_zero,
    output [31:0] ex_branch_target
);
    // forwarding muxes
    reg [31:0] alu_a, alu_b_reg;

    always @(*) begin
        case (fwd_a)
            2'b00: alu_a    = ex_rd1;
            2'b10: alu_a    = mem_alu_result;
            2'b01: alu_a    = wb_data;
            default: alu_a  = ex_rd1;
        endcase

        case (fwd_b)
            2'b00: alu_b_reg  = ex_rd2;
            2'b10: alu_b_reg  = mem_alu_result;
            2'b01: alu_b_reg  = wb_data;
            default: alu_b_reg = ex_rd2;
        endcase
    end

    wire [31:0] alu_b = ex_alu_src ? ex_imm : alu_b_reg;

    alu al (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (ex_alu_result),
        .zero     (ex_zero)
    );

    assign ex_rd2_out      = alu_b_reg;
    assign ex_branch_target = ex_pc + (ex_imm << 1);

endmodule