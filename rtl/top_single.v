// top_single.v - Single-Cycle RISC-V Top Level Module

module top_single (
    input  wire        clk,
    input  wire        rst
);

    // ------------------------------------------------------------------------
    // Internal Signals & Wires
    // ------------------------------------------------------------------------
    reg  [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_target;

    wire [31:0] instr;

    // Control Signals
    wire        reg_write;
    wire        alu_src;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        branch;
    wire        jump;
    wire [3:0]  alu_ctrl;

    // Register File Wires
    wire [31:0] reg_read_data1;
    wire [31:0] reg_read_data2;
    wire [31:0] reg_write_data;

    // Immediate & ALU Wires
    wire [31:0] imm;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    // Memory Read Data
    wire [31:0] mem_read_data;

    // ------------------------------------------------------------------------
    // Program Counter (PC) Register & Next-PC Logic
    // ------------------------------------------------------------------------
    assign pc_plus_4 = pc + 32'd4;
    assign pc_target = pc + imm;
    assign next_pc   = (jump || (branch && alu_zero)) ? pc_target : pc_plus_4;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'b0;
        else
            pc <= next_pc;
    end

    // ------------------------------------------------------------------------
    // Submodule Instantiations
    // ------------------------------------------------------------------------

    // Instruction Memory Instance
    memory instruction_mem (
        .clk       (clk),
        .mem_read  (1'b1),
        .mem_write (1'b0),
        .funct3    (3'b010),        // LW mode to read full 32-bit instructions
        .addr      (pc),
        .write_data(32'b0),
        .read_data (instr)
    );

    // Decoder / Control Unit Instance
    decoder control_unit (
        .instr     (instr),
        .reg_write (reg_write),
        .alu_src   (alu_src),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .mem_to_reg(mem_to_reg),
        .branch    (branch),
        .jump      (jump),
        .alu_ctrl  (alu_ctrl)
    );

    // Immediate Generator Instance
    imm_gen immediate_generator (
        .instr     (instr),
        .imm       (imm)
    );

    // Register File Instance
    regfile register_file (
        .clk (clk),
        .we  (reg_write),
        .rs1 (instr[19:15]),
        .rs2 (instr[24:20]),
        .rd  (instr[11:7]),
        .wd  (reg_write_data),
        .rd1 (reg_read_data1),
        .rd2 (reg_read_data2)
    );

    // ALU Execution Unit & Data Multiplexer
    assign alu_operand_b = alu_src ? imm : reg_read_data2;

    alu alu_unit (
        .a         (reg_read_data1),
        .b         (alu_operand_b),
        .alu_ctrl  (alu_ctrl),
        .result    (alu_result),
        .zero      (alu_zero)
    );

    // Data Memory Instance
    memory data_mem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .funct3    (instr[14:12]),  // Controls byte, halfword, and word access
        .addr      (alu_result),
        .write_data(reg_read_data2),
        .read_data (mem_read_data)
    );

    // Writeback Multiplexer
    assign reg_write_data = mem_to_reg ? mem_read_data : alu_result;

endmodule