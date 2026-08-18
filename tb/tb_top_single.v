// tb_top_single.v - Updated Testbench with Automatic Execution Termination

`timescale 1ns / 1ps

module tb_top_single;

    // Inputs to Top Module
    reg clk;
    reg rst;

    // Clock Period Definitions (100 MHz)
    localparam CLK_PERIOD = 10;

    // Instantiate Unit Under Test (UUT)
    top_single uut (
        .clk(clk),
        .rst(rst)
    );

    // ------------------------------------------------------------------------
    // Clock Generation
    // ------------------------------------------------------------------------
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ------------------------------------------------------------------------
    // Test Procedure
    // ------------------------------------------------------------------------
    initial begin
        // Waveform Dump Setup
        $dumpfile("top_single_waveform.vcd");
        $dumpvars(0, tb_top_single);

        // Initialize Signals & Apply Reset
        clk = 0;
        rst = 1;
        #(CLK_PERIOD * 2);
        rst = 0;

        $display("[%0t ns] Reset released. Processor running...\n", $time);
    end

    // ------------------------------------------------------------------------
    // Execution Monitor & Automatic Halt Logic
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            $display("Time=%0t | PC=0x%8h | Instr=0x%8h | RegWrite=%b | ALU_Result=0x%8h",
                     $time, uut.pc, uut.instr, uut.reg_write, uut.alu_result);

            // Automatically stop simulation when PC exceeds the program boundary (5 instructions = 0x14)
            if (uut.pc >= 32'h00000014) begin
                $display("\n[%0t ns] Program execution completed successfully. Terminating simulation.", $time);
                $finish;
            end
        end
    end

endmodule