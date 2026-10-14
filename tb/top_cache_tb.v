`timescale 1ns/1ps

module top_cache_tb;

    reg         clk, rst;
    wire [31:0] pc_out;
    wire [31:0] total_cycles, total_instrs;
    wire [31:0] icache_hits, icache_misses;
    wire [31:0] dcache_hits, dcache_misses;

    top_cache uut (
        .clk           (clk),
        .rst           (rst),
        .pc_out        (pc_out),
        .total_cycles  (total_cycles),
        .total_instrs  (total_instrs),
        .icache_hits   (icache_hits),
        .icache_misses (icache_misses),
        .dcache_hits   (dcache_hits),
        .dcache_misses (dcache_misses)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("cache.vcd");
        $dumpvars(0, top_cache_tb);

        rst = 1;
        @(posedge clk); @(posedge clk);
        #2; rst = 0;

        repeat (40) @(posedge clk);
        #1;

        $display("=== Performance Counter Results ===");
        $display("Total cycles:    %0d", total_cycles);
        $display("Total instrs:    %0d", total_instrs);
        $display("IPC:             %0d / %0d", total_instrs, total_cycles);
        $display("I-cache hits:    %0d", icache_hits);
        $display("I-cache misses:  %0d", icache_misses);
        $display("D-cache hits:    %0d", dcache_hits);
        $display("D-cache misses:  %0d", dcache_misses);

        $display("=== Register check ===");
        $display("x1 = %0d (expected 5)",  uut.rf.regs[1]);
        $display("x2 = %0d (expected 10)", uut.rf.regs[2]);
        $display("x3 = %0d (expected 15)", uut.rf.regs[3]);

        $display("=== Memory check ===");
        $display("mem[0] = %0d (expected 15)", uut.DC.mem[0]);

        $finish;
    end

endmodule