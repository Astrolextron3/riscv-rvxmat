module ex_stage (
    input         clk, rst,
    input         ex_mac_en, ex_clr_en,
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

    wire [31:0] alu_result_int;
    wire [31:0] mac_result;

    alu al (
        .a        (alu_a),
        .b        (alu_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (alu_result_int),
        .zero     (ex_zero)
    );

    // RVX-MAT: VMAC/VCLR execute here. Operands are the FORWARDED register values
    // (alu_a / alu_b_reg), never the immediate. The accumulator updates at the end
    // of the EX cycle, so back-to-back VMACs need no stall. mac_result is the value
    // the accumulator is about to hold; it travels down the pipe as the "ALU result"
    // and is therefore forwarded to later instructions by the existing forwarding unit.
    mac_unit MAC (
        .clk    (clk),
        .rst    (rst),
        .a      (alu_a),
        .b      (alu_b_reg),
        .mac_en (ex_mac_en),
        .clr_en (ex_clr_en),
        .result (mac_result)
    );

    assign ex_alu_result = (ex_mac_en | ex_clr_en) ? mac_result : alu_result_int;

    assign ex_rd2_out      = alu_b_reg;
    assign ex_branch_target = ex_pc + (ex_imm << 1);

endmodule