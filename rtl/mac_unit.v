module mac_unit (
    input         clk, rst,
    input  [31:0] a, b,
    input         mac_en,
    input         clr_en,
    output [31:0] result
);
    reg  [63:0] accumulator;

    // Signed 32x32 -> 64 product, kept in its own signed 64-bit net so the operands
    // are sign-extended (mixing an unsigned accumulator into the same expression
    // would make Verilog treat the whole thing as unsigned).
    wire signed [63:0] product  = $signed(a) * $signed(b);
    wire        [63:0] next_acc = accumulator + product;

    // result is what the accumulator WILL hold after this cycle, so a VMAC/VCLR
    // that writes back to rd gets the up-to-date value in the same cycle.
    // When idle it simply reflects the accumulator.
    assign result = clr_en ? 32'b0 :
                    mac_en ? next_acc[31:0] :
                             accumulator[31:0];

    always @(posedge clk or posedge rst) begin
        if (rst)         accumulator <= 64'b0;
        else if (clr_en) accumulator <= 64'b0;
        else if (mac_en) accumulator <= next_acc;
    end
endmodule
