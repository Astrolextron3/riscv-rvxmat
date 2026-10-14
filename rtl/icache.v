module icache #(
    parameter LINES = 32
)(
    input         clk, rst,
    input  [31:0] addr,
    input         read_en,
    output [31:0] data_out,
    output reg    hit,
    output reg    miss
);
    reg        valid [0:LINES-1];
    reg [22:0] tags  [0:LINES-1];
    reg [31:0] cache [0:LINES*4-1];

    reg [31:0] mem [0:255];
    initial $readmemh("program.hex", mem);

    wire [4:0]  index = addr[8:4];
    wire [1:0]  word_offset = addr[3:2];
    wire [22:0] tag   = addr[31:9];
    wire [7:0]  line_base = {addr[9:4], 2'b00};

    integer i, word;
    initial begin
        for (i = 0; i < LINES; i = i + 1) begin
            valid[i] = 1'b0;
            tags[i]  = 25'b0;
            for (word = 0; word < 4; word = word + 1)
                cache[i * 4 + word] = 32'b0;
        end
    end

    // combinational read
    assign data_out = (valid[index] && tags[index] == tag) ?
                      cache[index * 4 + word_offset] : mem[addr[9:2]];

    // synchronous update of cache state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < LINES; i = i + 1) begin
                valid[i] <= 1'b0;
                tags[i]  <= 25'b0;
                for (word = 0; word < 4; word = word + 1)
                    cache[i * 4 + word] <= 32'b0;
            end
            hit  <= 1'b0;
            miss <= 1'b0;
        end else if (read_en) begin
            if (valid[index] && tags[index] == tag) begin
                hit  <= 1'b1;
                miss <= 1'b0;
            end else begin
                for (word = 0; word < 4; word = word + 1)
                    cache[index * 4 + word] <= mem[line_base + word];
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