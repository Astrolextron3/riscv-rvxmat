module icache #(
    parameter LINES    = 32,
    parameter HEX_FILE = "program.hex"
)(
    input         clk, rst,
    input  [31:0] addr,
    input         read_en,
    output [31:0] data_out,
    output reg    hit,
    output reg    miss
);
    reg       valid [0:LINES-1];
    reg [7:0] tags  [0:LINES-1];
    reg [31:0] cache [0:LINES-1];

    reg [31:0] mem [0:255];
    initial $readmemh(HEX_FILE, mem);

    wire [4:0] index = addr[6:2];
    wire [7:0] tag   = addr[14:7];

    integer i;
    initial begin
        for (i = 0; i < LINES; i = i + 1) begin
            valid[i] = 1'b0;
            tags[i]  = 8'b0;
            cache[i] = 32'b0;
        end
    end

    assign data_out = (valid[index] && tags[index] == tag) ?
                      cache[index] : mem[addr[9:2]];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < LINES; i = i + 1) begin
                valid[i] <= 1'b0;
                tags[i]  <= 8'b0;
                cache[i] <= 32'b0;
            end
            hit  <= 1'b0;
            miss <= 1'b0;
        end else if (read_en) begin
            if (valid[index] && tags[index] == tag) begin
                hit  <= 1'b1;
                miss <= 1'b0;
            end else begin
                cache[index] <= mem[addr[9:2]];
                tags[index]  <= tag;
                valid[index] <= 1'b1;
                hit          <= 1'b0;
                miss         <= 1'b1;
            end
        end else begin
            hit  <= 1'b0;
            miss <= 1'b0;
        end
    end

endmodule