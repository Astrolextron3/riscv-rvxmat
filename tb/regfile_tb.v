`timescale 1ns/1ps

module regfile_tb;
    reg clk,we;
    reg [4:0] rs1,rs2,rd;
    reg [31:0] wd;
    wire [31:0] rd1,rd2;


    regfile uut(
        .clk(clk),.we(we),
        .rs1(rs1),.rs2(rs2),
        .rd(rd),.wd(wd),
        .rd1(rd1),.rd2(rd2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task write_reg;
        input [4:0] addr;
        input[31:0] data;
        begin
            rd = addr; wd = data; we =1;
            @(posedge clk);#1;
            we = 0;
        end
    endtask
    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0,regfile_tb);

        we = 0; rs1 = 0; rs2 = 0; rd = 0; wd = 0 ;
        #10;

         write_reg(5'd1, 32'd42);
        rs1 = 5'd1;
        #1;
        $display("TEST 1 - Write/Read x1: expected 42, got %0d %s",
            rd1, rd1 == 32'd42 ? "PASS" : "FAIL");
        
        write_reg(5'd0, 32'd999);
        rs1 = 5'd0;
        #1;
        $display("TEST 2 - x0 always zero: expected 0, got %0d %s",
            rd1, rd1 == 32'd0 ? "PASS" : "FAIL");
        
        write_reg(5'd3, 32'd200);
        rs1 = 5'd2; rs2 = 5'd3;
        #1;
        $display("TEST 3 - Dual read: x2=%0d %s | x3=%0d %s",
            rd1, rd1 == 32'd100 ? "PASS" : "FAIL",
            rd2, rd2 == 32'd200 ? "PASS" : "FAIL");

        write_reg(5'd4, 32'd55);
        rd = 5'd4; wd = 32'd999; we = 0;
        @(posedge clk); #1;
        rs1 = 5'd4;
        #1;
        $display("TEST 4 - WE gate: expected 55, got %0d %s",
            rd1, rd1 == 32'd55 ? "PASS" : "FAIL");
        
        write_reg(5'd1, 32'd300);
        rs1 = 5'd1; rs2 = 5'd3;
        #1;
        $display("TEST 5 - WB scenario: x1=%0d x3=%0d sum=%0d %s",
            rd1, rd2, rd1+rd2,
            (rd1 == 32'd300 && rd2 == 32'd200) ? "PASS" : "FAIL");

        $finish;
    end
endmodule