module top_single (
    input         clk,
    input         rst,
    output [31:0] pc_out,
    output [31:0] alu_result_out,
    output [31:0] reg_out
);

    // ── Program Counter ────────────────────────────────────
    reg [31:0] pc;

    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'hFFFFFFFC; // start at -4 so first instruction is at 0
        else     pc <= pc + 4;
    end

    // ── Instruction Memory ─────────────────────────────────
    reg [31:0] imem [0:255];
    initial begin
        $readmemh("program.hex", imem);
        $display("Memory initialized from program.hex");
    end

    wire [31:0] instr = imem[pc[9:2]];

    // ── Instruction fields ─────────────────────────────────
    wire [4:0] rd     = instr[11:7];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [2:0] funct3 = instr[14:12];

    // ── Decoder ────────────────────────────────────────────
    wire        reg_write, alu_src, mem_write, mem_read;
    wire        mem_to_reg, branch, jump;
    wire [3:0]  alu_ctrl;

    decoder dec (
        .instr      (instr),
        .reg_write  (reg_write),
        .alu_src    (alu_src),
        .mem_write  (mem_write),
        .mem_read   (mem_read),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .jump       (jump),
        .alu_ctrl   (alu_ctrl)
    );

    // ── Immediate Generator ────────────────────────────────
    wire [31:0] imm;

    imm_gen ig (
        .instr (instr),
        .imm   (imm)
    );

    // ── Register File ──────────────────────────────────────
    wire [31:0] rd1, rd2;
    wire [31:0] wb_data;

    regfile rf (
        .clk  (clk),
        .we   (reg_write),
        .rs1  (rs1),
        .rs2  (rs2),
        .rd   (rd),
        .wd   (wb_data),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    // ── ALU ───────────────────────────────────────────────
    wire [31:0] alu_b = alu_src ? imm : rd2;
    wire [31:0] alu_result;
    wire        zero;

    alu al (
        .a        (rd1),
        .b        (alu_b),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (zero)
    );

    // ── Data Memory ────────────────────────────────────────
    wire [31:0] mem_read_data;

    memory mem (
        .clk        (clk),
        .mem_write  (mem_write),
        .mem_read   (mem_read),
        .funct3     (funct3),
        .addr       (alu_result),
        .write_data (rd2),
        .read_data  (mem_read_data)
    );

    // ── Writeback ──────────────────────────────────────────
    assign wb_data = mem_to_reg ? mem_read_data : alu_result;

    // ── Outputs ────────────────────────────────────────────
    assign pc_out         = pc;
    assign alu_result_out = alu_result;
    assign reg_out        = wb_data;

endmodule