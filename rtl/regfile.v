module regfile(
    input clk,
    input we,
    input [4:0] rs1,rs2,rd,
    input [31:0] wd,
    output [31:0] rd1,rd2
);

    reg [31:0] regs[0:31];

    integer i;
    initial begin 
        for(i=0;i<32;i=i+1)
            regs[i]=31'b0;
    end

    always @(posedge clk) begin
        if(we && rd!=5'b0)
        regs[rd]<=wd;
    end

    assign rd1 = (rs1==5'b0)?32'b0:regs[rs1];
    assign rd2 = (rs2==5'b0)?32'b0:regs[rs2];
endmodule