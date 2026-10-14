module perf_counters (
    input         clk, rst,
    input         instr_valid,
    input         icache_hit, icache_miss,
    input         dcache_hit, dcache_miss,
    output reg [31:0] total_cycles,
    output reg [31:0] total_instrs,
    output reg [31:0] icache_hits,
    output reg [31:0] icache_misses,
    output reg [31:0] dcache_hits,
    output reg [31:0] dcache_misses
);
       always @(posedge clk or posedge rst) begin
        if (rst) begin
            total_cycles  <= 32'b0;
            total_instrs  <= 32'b0;
            icache_hits   <= 32'b0;
            icache_misses <= 32'b0;
            dcache_hits   <= 32'b0;
            dcache_misses <= 32'b0;
        end else begin
            total_cycles <= total_cycles + 1;
            if (instr_valid)
                total_instrs <= total_instrs + 1;
            // count on negedge equivalent — sample after posedge update
            if (icache_hit)  icache_hits   <= icache_hits   + 1;
            if (icache_miss) icache_misses <= icache_misses + 1;
            if (dcache_hit)  dcache_hits   <= dcache_hits   + 1;
            if (dcache_miss) dcache_misses <= dcache_misses + 1;
        end
    end
endmodule