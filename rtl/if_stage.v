module if_stage #(
    parameter HEX_FILE = "program.hex"
) (
    input         clk, rst,
    input         stall,
    input         pc_src,
    input  [31:0] branch_target,
    output reg [31:0] if_pc,
    output [31:0] if_instr
);
    reg [31:0] imem [0:255];
    initial $readmemh(HEX_FILE, imem);

    always @(posedge clk or posedge rst) begin
        if (rst)
            if_pc <= 32'hFFFFFFFC;
        else if (!stall)
            if_pc <= pc_src ? branch_target : if_pc + 4;
    end

    assign if_instr = imem[if_pc[9:2]];

endmodule