module top_rvxmat2 (
    input         clk, rst,
    output [31:0] pc_out,
    output [31:0] total_cycles,
    output [31:0] total_instrs,
    output [31:0] icache_hits,
    output [31:0] icache_misses,
    output [31:0] dcache_hits,
    output [31:0] dcache_misses,
    output [31:0] mac_result_out
);
    reg [31:0] pc;
    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 32'hFFFFFFFC;
        else     pc <= pc + 4;
    end

    wire [31:0] instr;
    wire        ic_hit, ic_miss;

    icache #(.HEX_FILE("benchmarks/matmul_rvxmat.hex")) IC (
        .clk      (clk), .rst(rst),
        .addr     (pc),  .read_en(1'b1),
        .data_out (instr),
        .hit      (ic_hit), .miss(ic_miss)
    );

    wire        reg_write, alu_src, mem_write, mem_read;
    wire        mem_to_reg, branch, jump;
    wire [3:0]  alu_ctrl;

    decoder dec (
        .instr(instr), .reg_write(reg_write),
        .alu_src(alu_src), .mem_write(mem_write),
        .mem_read(mem_read), .mem_to_reg(mem_to_reg),
        .branch(branch), .jump(jump), .alu_ctrl(alu_ctrl)
    );

    wire        mac_en, clr_en, rvxmat_reg_write;
    wire [4:0]  rvxmat_rd, rvxmat_rs1, rvxmat_rs2;

    rvxmat_decoder RVXDEC (
        .instr(instr), .mac_en(mac_en), .clr_en(clr_en),
        .rvxmat_reg_write(rvxmat_reg_write),
        .rvxmat_rd(rvxmat_rd), .rvxmat_rs1(rvxmat_rs1),
        .rvxmat_rs2(rvxmat_rs2)
    );

    wire [31:0] imm;
    imm_gen ig (.instr(instr), .imm(imm));

    wire [4:0] rd     = instr[11:7];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [2:0] funct3 = instr[14:12];

    wire        eff_reg_write = reg_write | rvxmat_reg_write;
    wire [4:0]  eff_rd        = rvxmat_reg_write ? rvxmat_rd  : rd;
    wire [4:0]  eff_rs1       = rvxmat_reg_write ? rvxmat_rs1 : rs1;
    wire [4:0]  eff_rs2       = rvxmat_reg_write ? rvxmat_rs2 : rs2;
    wire [31:0] mac_result;
    wire [31:0] rd1, rd2, wb_data;

    regfile rf (
        .clk(clk), .we(eff_reg_write),
        .rs1(eff_rs1), .rs2(eff_rs2),
        .rd(eff_rd), .wd(wb_data),
        .rd1(rd1), .rd2(rd2)
    );

    wire [31:0] alu_result;
    wire        zero;

    alu al (
        .a(rd1), .b(alu_src ? imm : rd2),
        .alu_ctrl(alu_ctrl), .result(alu_result), .zero(zero)
    );

    mac_unit MAC (
        .clk(clk), .rst(rst),
        .a(rd1), .b(rd2),
        .mac_en(mac_en), .clr_en(clr_en),
        .result(mac_result)
    );

    wire [31:0] dc_data_out;
    wire        dc_hit, dc_miss;

    dcache DC (
        .clk(clk), .rst(rst),
        .addr(alu_result), .write_data(rd2),
        .read_en(mem_read), .write_en(mem_write),
        .funct3(funct3), .data_out(dc_data_out),
        .hit(dc_hit), .miss(dc_miss)
    );

    assign wb_data = rvxmat_reg_write ? mac_result :
                     mem_to_reg       ? dc_data_out : alu_result;

    wire instr_valid = (instr[6:0] != 7'b0) && (instr != 32'h00000073);  // ECALL = halt marker, not counted

    perf_counters PERF (
        .clk(clk), .rst(rst),
        .instr_valid(instr_valid),
        .icache_hit(ic_hit), .icache_miss(ic_miss),
        .dcache_hit(dc_hit), .dcache_miss(dc_miss),
        .total_cycles(total_cycles), .total_instrs(total_instrs),
        .icache_hits(icache_hits), .icache_misses(icache_misses),
        .dcache_hits(dcache_hits), .dcache_misses(dcache_misses)
    );

    assign pc_out        = pc;
    assign mac_result_out = mac_result;
endmodule