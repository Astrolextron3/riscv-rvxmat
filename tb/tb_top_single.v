`timescale 1ns/1ps

module top_single_tb;

    reg         clk, rst;
    wire [31:0] pc_out, alu_result_out, reg_out;

    top_single uut (
        .clk            (clk),
        .rst            (rst),
        .pc_out         (pc_out),
        .alu_result_out (alu_result_out),
        .reg_out        (reg_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_single.vcd");
        $dumpvars(0, top_single_tb);

        // hold reset for 2 full cycles then release before clock edge
        rst = 1;
        @(posedge clk); @(posedge clk);
        #2; rst = 0;

        // run 20 cycles
                repeat (20) begin
            @(posedge clk); #1;
            $display("PC=%0d | instr=%h | alu=%0d | wb=%0d | we=%b | rd=%0d | wd=%0d | x1=%0d | x2=%0d | x3=%0d",
                pc_out, uut.instr, alu_result_out, reg_out,
                uut.rf.we, uut.rf.rd, uut.rf.wd,
                uut.rf.regs[1], uut.rf.regs[2], uut.rf.regs[3]);
        end

        // extra cycles for writebacks to settle
            // wait long enough for all writes to complete
        repeat (10) @(posedge clk);
        #1;

        $display("--- Final register check ---");
        $display("x1 = %0d (expected 5)",  uut.rf.regs[1]);
        $display("x2 = %0d (expected 10)", uut.rf.regs[2]);
        $display("x3 = %0d (expected 15)", uut.rf.regs[3]);
        $display("x4 = %0d (expected 15)", uut.rf.regs[4]);

        $display("--- Memory check ---");
        $display("mem[0] = %0d (expected 15)", uut.mem.mem[0]);

        $finish;
    end

endmodule