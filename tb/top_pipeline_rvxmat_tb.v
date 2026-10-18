`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// Counts cycles / retired instructions / load-use stalls for ONE pipeline and
// raises `done` once the program's ECALL halt marker has drained, i.e. at the end
// of the cycle in which the last real instruction writes back.
//   cycles  : cycles since reset release up to and including that WB cycle
//   instrs  : instructions that left ID into EX (no bubbles, no ECALL, no X words)
//   stalls  : cycles ID was held by the load-use hazard unit
// ---------------------------------------------------------------------------
module pipe_monitor (
    input             clk, rst,
    input      [31:0] id_instr,
    input             stall,
    output reg        done,
    output reg [31:0] cycles, instrs, stalls
);
    localparam [31:0] ECALL = 32'h00000073;
    reg       seen;
    reg [1:0] drain;

    initial begin
        done = 0; cycles = 0; instrs = 0; stalls = 0; seen = 0; drain = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            done <= 0; cycles <= 0; instrs <= 0; stalls <= 0; seen <= 0; drain <= 0;
        end else if (!done) begin
            cycles <= cycles + 1;
            if (!seen) begin
                if (id_instr === ECALL)
                    seen <= 1;
                else if (stall === 1'b1)
                    stalls <= stalls + 1;
                else if (id_instr !== 32'h0 && (^id_instr) !== 1'bx)
                    instrs <= instrs + 1;
            end else begin
                drain <= drain + 1;
                if (drain == 2'd1) done <= 1;
            end
        end
    end
endmodule


module top_pipeline_rvxmat_tb;

    reg clk, rst;

    wire [31:0] s_pc, r_pc, h_pc;

    // Same pipeline RTL, three programs (HEX_FILE parameter)
    top_pipeline #(.HEX_FILE("benchmarks/matmul_scalar.hex"))  SP (.clk(clk), .rst(rst), .pc_out(s_pc));
    top_pipeline #(.HEX_FILE("benchmarks/matmul_rvxmat.hex"))  RP (.clk(clk), .rst(rst), .pc_out(r_pc));
    top_pipeline #(.HEX_FILE("benchmarks/rvxmat_hazard.hex"))  HP (.clk(clk), .rst(rst), .pc_out(h_pc));

    wire        s_done, r_done, h_done;
    wire [31:0] s_cyc, s_ins, s_stl;
    wire [31:0] r_cyc, r_ins, r_stl;
    wire [31:0] h_cyc, h_ins, h_stl;

    pipe_monitor SM (.clk(clk), .rst(rst), .id_instr(SP.id_instr), .stall(SP.stall),
                     .done(s_done), .cycles(s_cyc), .instrs(s_ins), .stalls(s_stl));
    pipe_monitor RM (.clk(clk), .rst(rst), .id_instr(RP.id_instr), .stall(RP.stall),
                     .done(r_done), .cycles(r_cyc), .instrs(r_ins), .stalls(r_stl));
    pipe_monitor HM (.clk(clk), .rst(rst), .id_instr(HP.id_instr), .stall(HP.stall),
                     .done(h_done), .cycles(h_cyc), .instrs(h_ins), .stalls(h_stl));

    initial clk = 0;
    always #5 clk = ~clk;

    // ---- trace every VCLR/VMAC in the RVX-MAT pipeline as it executes in EX ----
    always @(posedge clk) begin
        if (!rst && RP.ex_clr_en === 1'b1)
            $display("[%0t] EX: VCLR            -> acc/result = 0", $time);
        if (!rst && RP.ex_mac_en === 1'b1)
            $display("[%0t] EX: VMAC  a=%0d b=%0d -> acc/result = %0d",
                     $time, $signed(RP.EX.alu_a), $signed(RP.EX.alu_b_reg), RP.EX.mac_result);
    end

    integer fails;

    task check_reg;
        input integer regnum;
        input [31:0]  got, expected;
        begin
            if (got === expected)
                $display("  x%0d = %0d  PASS", regnum, got);
            else begin
                $display("  x%0d = %0d  FAIL (expected %0d)", regnum, got, expected);
                fails = fails + 1;
            end
        end
    endtask

    task check_val;
        input [31:0] got, expected;
        begin
            if (got === expected)
                $display("  %0d  PASS", got);
            else begin
                $display("  %0d  FAIL (expected %0d)", got, expected);
                fails = fails + 1;
            end
        end
    endtask

    integer n;

    initial begin
        $dumpfile("pipeline_rvxmat.vcd");
        $dumpvars(0, top_pipeline_rvxmat_tb);

        fails = 0;
        rst = 1;
        @(posedge clk); @(posedge clk);
        #2; rst = 0;

        n = 0;
        while (!(s_done && r_done && h_done) && n < 1000) begin
            @(posedge clk);
            n = n + 1;
        end
        #1;

        if (!(s_done && r_done && h_done)) begin
            $display("TIMEOUT: scalar done=%b rvxmat done=%b hazard done=%b", s_done, r_done, h_done);
            $finish;
        end

        $display("============================================");
        $display("   RVX-MAT ON THE 5-STAGE PIPELINE");
        $display("============================================");
        $display("--- Scalar RV32I (software multiply) ---");
        $display("  Cycles:        %0d", s_cyc);
        $display("  Instructions:  %0d", s_ins);
        $display("  Load-use stalls: %0d", s_stl);
        $display("--- RVX-MAT ---");
        $display("  Cycles:        %0d", r_cyc);
        $display("  Instructions:  %0d", r_ins);
        $display("  Load-use stalls: %0d", r_stl);
        $display("--- Results ---");
        $display("  Instr reduction: %0d -> %0d  (%0.2fx fewer)", s_ins, r_ins, $itor(s_ins) / $itor(r_ins));
        $display("  Cycle speedup:   %0d / %0d = %0.2fx", s_cyc, r_cyc, $itor(s_cyc) / $itor(r_cyc));
        $display("  CPI scalar %0.2f, rvxmat %0.2f  (5-cycle pipeline fill is amortised over fewer instrs)",
                 $itor(s_cyc) / $itor(s_ins), $itor(r_cyc) / $itor(r_ins));
        $display("============================================");

        $display("--- Dot-product correctness (expected x11 = 67) ---");
        $write("  scalar "); check_reg(11, SP.ID.rf.regs[11], 32'd67);
        $write("  rvxmat "); check_reg(11, RP.ID.rf.regs[11], 32'd67);
        $write("  MAC accumulator (low 32) =");  check_val(RP.EX.MAC.accumulator[31:0], 32'd67);

        $display("--- Hazard test (forwarding / bypass / load-use / VCLR / negative operand) ---");
        check_reg(11, HP.ID.rf.regs[11], 32'd239);
        check_reg(12, HP.ID.rf.regs[12], 32'd48);
        check_reg(6,  HP.ID.rf.regs[6],  32'd239);
        check_reg(13, HP.ID.rf.regs[13], 32'd1195);
        check_reg(14, HP.ID.rf.regs[14], 32'd0);
        check_reg(15, HP.ID.rf.regs[15], 32'd12);
        check_reg(17, HP.ID.rf.regs[17], 32'd3);
        $write("  mem[0] ="); check_val(HP.MEM.dmem.mem[0], 32'd239);
        $write("  load-use stalls (expect 1) ="); check_val(h_stl, 32'd1);

        if (fails == 0) $display("ALL CHECKS PASSED");
        else            $display("%0d CHECK(S) FAILED", fails);

        $finish;
    end

endmodule
