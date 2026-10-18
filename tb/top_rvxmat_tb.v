`timescale 1ns/1ps

module top_rvxmat_tb;

    localparam [31:0] ECALL    = 32'h00000073;   // halt marker at end of each program
    localparam [31:0] EXPECTED = 32'd67;         // dot([3,5,7,2],[4,6,1,9])
    localparam        TIMEOUT  = 2000;

    reg clk, rst;

    // ---------------- scalar core ----------------
    wire [31:0] s_pc, s_cycles, s_instrs;
    wire [31:0] s_ic_hits, s_ic_misses, s_dc_hits, s_dc_misses;

    top_scalar SCALAR (
        .clk(clk), .rst(rst),
        .pc_out(s_pc),
        .total_cycles(s_cycles), .total_instrs(s_instrs),
        .icache_hits(s_ic_hits), .icache_misses(s_ic_misses),
        .dcache_hits(s_dc_hits), .dcache_misses(s_dc_misses)
    );

    // ---------------- RVX-MAT core ----------------
    wire [31:0] r_pc, r_cycles, r_instrs;
    wire [31:0] r_ic_hits, r_ic_misses, r_dc_hits, r_dc_misses;
    wire [31:0] r_mac;

    top_rvxmat2 RVXMAT (
        .clk(clk), .rst(rst),
        .pc_out(r_pc),
        .total_cycles(r_cycles), .total_instrs(r_instrs),
        .icache_hits(r_ic_hits), .icache_misses(r_ic_misses),
        .dcache_hits(r_dc_hits), .dcache_misses(r_dc_misses),
        .mac_result_out(r_mac)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------- per-core halt capture ----------------
    // Counters keep running after a core halts, so snapshot them the cycle ECALL
    // is on the bus (values sampled here are the pre-edge, i.e. final, ones).
    reg        s_done, r_done;
    reg [31:0] s_cyc, s_ins, s_ich, s_icm, s_x11;
    reg [31:0] r_cyc, r_ins, r_ich, r_icm, r_x11, r_accum;

    initial begin s_done = 0; r_done = 0; end

    always @(posedge clk) begin
        if (!rst && !s_done && SCALAR.instr === ECALL) begin
            s_done <= 1;
            s_cyc <= s_cycles;  s_ins <= s_instrs;
            s_ich <= s_ic_hits; s_icm <= s_ic_misses;
            s_x11 <= SCALAR.rf.regs[11];
        end
        if (!rst && !r_done && RVXMAT.instr === ECALL) begin
            r_done <= 1;
            r_cyc <= r_cycles;  r_ins <= r_instrs;
            r_ich <= r_ic_hits; r_icm <= r_ic_misses;
            r_x11 <= RVXMAT.rf.regs[11];
            r_accum <= RVXMAT.MAC.accumulator[31:0];
        end
    end

    // trace every VCLR/VMAC as it executes
    always @(posedge clk) begin
        if (!rst && RVXMAT.clr_en)
            $display("[%0t] VCLR            -> acc = 0", $time);
        if (!rst && RVXMAT.mac_en)
            $display("[%0t] VMAC rs1=%0d rs2=%0d -> acc = %0d",
                     $time, RVXMAT.rd1, RVXMAT.rd2, RVXMAT.mac_result);
    end

    // ---------------- sequencing ----------------
    integer n;
    initial begin
        $dumpfile("rvxmat.vcd");
        $dumpvars(0, top_rvxmat_tb);

        rst = 1;
        @(posedge clk); @(posedge clk);
        #2; rst = 0;

        n = 0;
        while (!(s_done && r_done) && n < TIMEOUT) begin
            @(posedge clk);
            n = n + 1;
        end
        #1;

        if (!(s_done && r_done)) begin
            $display("TIMEOUT after %0d cycles (scalar done=%b, rvxmat done=%b)",
                     TIMEOUT, s_done, r_done);
            $finish;
        end

        $display("============================================");
        $display("       RVX-MAT BENCHMARK RESULTS            ");
        $display("============================================");
        $display("--- Scalar RV32I ---");
        $display("  Cycles:          %0d", s_cyc);
        $display("  Instructions:    %0d", s_ins);
        $display("  I-cache hits:    %0d", s_ich);
        $display("  I-cache misses:  %0d", s_icm);
        $display("--- RVX-MAT ---");
        $display("  Cycles:          %0d", r_cyc);
        $display("  Instructions:    %0d", r_ins);
        $display("  I-cache hits:    %0d", r_ich);
        $display("  I-cache misses:  %0d", r_icm);
        $display("--- Results ---");
        $display("  Instr reduction: %0d -> %0d  (%0.2fx fewer)",
                 s_ins, r_ins, $itor(s_ins) / $itor(r_ins));
        $display("  Cycle speedup:   %0d / %0d = %0.2fx",
                 s_cyc, r_cyc, $itor(s_cyc) / $itor(r_cyc));
        $display("============================================");
        $display("--- Correctness (expected x11 = %0d) ---", EXPECTED);
        $display("  SCALAR x11 = %0d  %s", s_x11, (s_x11 === EXPECTED) ? "PASS" : "FAIL");
        $display("  RVXMAT x11 = %0d  %s", r_x11, (r_x11 === EXPECTED) ? "PASS" : "FAIL");
        $display("  MAC accumulator = %0d  %s", r_accum, (r_accum === EXPECTED) ? "PASS" : "FAIL");

        $finish;
    end

endmodule