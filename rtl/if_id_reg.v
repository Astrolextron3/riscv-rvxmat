module if_id_reg (
    input         clk, rst,
    input         stall, flush,
    input  [31:0] if_pc,
    input  [31:0] if_instr,
    output reg [31:0] id_pc,
    output reg [31:0] id_instr
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            id_pc    <= 32'b0;
            id_instr <= 32'b0;
        end else if (!stall) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
        end
    end
endmodule