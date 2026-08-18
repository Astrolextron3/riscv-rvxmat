`timescale 1ns/1ps

module memory_tb;

    reg         clk, mem_write, mem_read;
    reg  [2:0]  funct3;
    reg  [31:0] addr, write_data;
    wire [31:0] read_data;

    memory uut (
        .clk        (clk),
        .mem_write  (mem_write),
        .mem_read   (mem_read),
        .funct3     (funct3),
        .addr       (addr),
        .write_data (write_data),
        .read_data  (read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task write_mem;
        input [31:0] a;
        input [31:0] data;
        input [2:0]  f3;
        begin
            addr = a; write_data = data;
            funct3 = f3; mem_write = 1; mem_read = 0;
            @(posedge clk); #1;
            mem_write = 0;
        end
    endtask

    task read_mem;
        input [31:0] a;
        input [2:0]  f3;
        begin
            addr = a; funct3 = f3;
            mem_read = 1; mem_write = 0;
            #1;
        end
    endtask

    initial begin
        $dumpfile("memory.vcd");
        $dumpvars(0, memory_tb);

        mem_write = 0; mem_read = 0;
        addr = 0; write_data = 0; funct3 = 0;
        #10;

        // TEST 1 — SW + LW
        write_mem(32'h00, 32'hDEADBEEF, 3'b010);
        read_mem(32'h00, 3'b010);
        $display("TEST 1 SW+LW:  expected DEADBEEF, got %h %s",
            read_data, read_data == 32'hDEADBEEF ? "PASS" : "FAIL");

        // TEST 2 — SB + LB (byte 0, positive)
        write_mem(32'h04, 32'h0000007F, 3'b000);
        read_mem(32'h04, 3'b000);
        $display("TEST 2 SB+LB+: expected 0000007F, got %h %s",
            read_data, read_data == 32'h0000007F ? "PASS" : "FAIL");

        // TEST 3 — SB + LB (byte 0, negative — sign extend)
        write_mem(32'h08, 32'h00000080, 3'b000);
        read_mem(32'h08, 3'b000);
        $display("TEST 3 SB+LB-: expected FFFFFF80, got %h %s",
            read_data, read_data == 32'hFFFFFF80 ? "PASS" : "FAIL");

        // TEST 4 — SB + LBU (unsigned, no sign extension)
        write_mem(32'h0C, 32'h00000080, 3'b000);
        read_mem(32'h0C, 3'b100);
        $display("TEST 4 SB+LBU: expected 00000080, got %h %s",
            read_data, read_data == 32'h00000080 ? "PASS" : "FAIL");

        // TEST 5 — SH + LH (negative halfword)
        write_mem(32'h10, 32'h00008000, 3'b001);
        read_mem(32'h10, 3'b001);
        $display("TEST 5 SH+LH-: expected FFFF8000, got %h %s",
            read_data, read_data == 32'hFFFF8000 ? "PASS" : "FAIL");

        // TEST 6 — SH + LHU (unsigned halfword)
        write_mem(32'h14, 32'h00008000, 3'b001);
        read_mem(32'h14, 3'b101);
        $display("TEST 6 SH+LHU: expected 00008000, got %h %s",
            read_data, read_data == 32'h00008000 ? "PASS" : "FAIL");

        // TEST 7 — byte independence
        // write 0xAB to byte offset 1, check byte 0 untouched
        write_mem(32'h18, 32'hDEADBEEF, 3'b010); // first store full word
        write_mem(32'h19, 32'h000000AB, 3'b000); // overwrite byte 1 only
        read_mem(32'h18, 3'b010);                // read full word back
        $display("TEST 7 BYTE INDEP: expected DEADABEF, got %h %s",
            read_data, read_data == 32'hDEADABEF ? "PASS" : "FAIL");

        $finish;
    end

endmodule