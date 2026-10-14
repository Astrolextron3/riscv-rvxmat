module top_cache (
    input         clk, rst,
    output [31:0] pc_out,
    output [31:0] total_cycles,
    output [31:0] total_instrs,
    output [31:0] icache_hits,
    output [31:0] icache_misses,
    output [31:0] dcache_hits,
    output [31:0] dcache_misses
);
    // PC
    reg [31:0] pc;
    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'hFFFFFFFC;
        else     pc <= pc + 4;
    end

    // instruction cache
    wire [31:0] instr;
    wire        ic_hit, ic_miss;

    icache IC (
        .clk      (clk),
        .rst      (rst),
        .addr     (pc),
        .read_en  (1'b1),
        .data_out (instr),
        .hit      (ic_hit),
        .miss     (ic_miss)
    );

    // decode fields
    wire [4:0]  rd     = instr[11:7];
    wire [4:0]  rs1    = instr[19:15];
    wire [4:0]  rs2    = instr[24:20];
    wire [2:0]  funct3 = instr[14:12];

    // decoder
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

    // immediate
    wire [31:0] imm;
    imm_gen ig (.instr(instr), .imm(imm));

    // register file
    wire [31:0] rd1, rd2, wb_data;
    regfile rf (
        .clk (clk),
        .we  (reg_write),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd  (wb_data),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    // ALU
    wire [31:0] alu_result;
    wire        zero;
    alu al (
        .a        (rd1),
        .b        (alu_src ? imm : rd2),
        .alu_ctrl (alu_ctrl),
        .result   (alu_result),
        .zero     (zero)
    );

    // data cache
    wire [31:0] dc_data_out;
    wire        dc_hit, dc_miss;

    dcache DC (
        .clk       (clk),
        .rst       (rst),
        .addr      (alu_result),
        .write_data(rd2),
        .read_en   (mem_read),
        .write_en  (mem_write),
        .funct3    (funct3),
        .data_out  (dc_data_out),
        .hit       (dc_hit),
        .miss      (dc_miss)
    );

    // writeback
    assign wb_data = mem_to_reg ? dc_data_out : alu_result;

    // valid instruction signal — not NOP
    wire instr_valid = (instr[6:0] != 7'b0);

    // performance counters
    perf_counters PERF (
        .clk          (clk),
        .rst          (rst),
        .instr_valid  (instr_valid),
        .icache_hit   (ic_hit),
        .icache_miss  (ic_miss),
        .dcache_hit   (dc_hit),
        .dcache_miss  (dc_miss),
        .total_cycles  (total_cycles),
        .total_instrs  (total_instrs),
        .icache_hits   (icache_hits),
        .icache_misses (icache_misses),
        .dcache_hits   (dcache_hits),
        .dcache_misses (dcache_misses)
    );

    assign pc_out = pc;

endmodule