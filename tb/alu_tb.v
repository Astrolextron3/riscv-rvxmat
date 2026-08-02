`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] a, b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    alu uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        a = 32'd10; b = 32'd5; alu_ctrl = 4'b0000;
        #10; $display("ADD: %0d + %0d = %0d", a, b, result);

        a = 32'd10; b = 32'd5; alu_ctrl = 4'b0001;
        #10; $display("SUB: %0d - %0d = %0d", a, b, result);

        a = 32'hF0; b = 32'hFF; alu_ctrl = 4'b0010;
        #10; $display("AND: %h & %h = %h", a, b, result);

        a = 32'hF0; b = 32'hF; alu_ctrl = 4'b0011;
        #10; $display("OR:  %h | %h = %h", a, b, result);

        a = 32'hFF; b = 32'hFF; alu_ctrl = 4'b0100;
        #10; $display("XOR: %h ^ %h = %h", a, b, result);

        a = 32'd3; b = 32'd5; alu_ctrl = 4'b0101;
        #10; $display("SLT: %0d < %0d = %0d", a, b, result);

        a = 32'd1; b = 32'd4; alu_ctrl = 4'b0110;
        #10; $display("SLL: %0d << %0d = %0d", a, b, result);

        a = 32'd16; b = 32'd2; alu_ctrl = 4'b0111;
        #10; $display("SRL: %0d >> %0d = %0d", a, b, result);

        a = -32'd8; b = 32'd1; alu_ctrl = 4'b1000;
        #10; $display("SRA: -8 >>> 1 = %0d", $signed(result));

        a = 32'd5; b = 32'd5; alu_ctrl = 4'b0001;
        #10; $display("ZERO flag: %0d", zero);

        $finish;
    end

endmodule