`timescale 1ns/1ps

module top_pipeline_tb;

    reg         clk, rst;
    wire [31:0] pc_out;

    top_pipeline uut (
        .clk    (clk),
        .rst    (rst),
        .pc_out (pc_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("pipeline.vcd");
        $dumpvars(0, top_pipeline_tb);

        rst = 1;
        @(posedge clk); @(posedge clk);
        #2; rst = 0;

        repeat (30) begin
            @(posedge clk); #1;
            $display("PC=%0d | x1=%0d | x2=%0d | x3=%0d",
                pc_out,
                uut.ID.rf.regs[1],
                uut.ID.rf.regs[2],
                uut.ID.rf.regs[3]);
        end

        repeat (5) @(posedge clk);
        #1;

        $display("--- Final register check ---");
        $display("x1 = %0d (expected 5)",  uut.ID.rf.regs[1]);
        $display("x2 = %0d (expected 10)", uut.ID.rf.regs[2]);
        $display("x3 = %0d (expected 15)", uut.ID.rf.regs[3]);

        $display("--- Memory check ---");
        $display("mem[0] = %0d (expected 15)", uut.MEM.dmem.mem[0]);

        $finish;
    end

endmodule