module dcache #(
    parameter LINES = 32
)(
    input         clk, rst,
    input  [31:0] addr,
    input  [31:0] write_data,
    input         read_en,
    input         write_en,
    input  [2:0]  funct3,
    output reg [31:0] data_out,
    output reg    hit,
    output reg    miss
);
    reg        valid [0:LINES-1];
    reg [24:0] tags  [0:LINES-1];
    reg [31:0] cache [0:LINES-1];

    // backing memory
    reg [31:0] mem [0:1023];

    wire [4:0]  index      = addr[6:2];
    wire [24:0] tag        = addr[31:7];
    wire [9:0]  word_addr  = addr[11:2];
    wire [1:0]  byte_off   = addr[1:0];

    integer i;
    initial begin
        for (i = 0; i < LINES; i = i + 1) begin
            valid[i] = 1'b0;
            tags[i]  = 25'b0;
            cache[i] = 32'b0;
        end
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'b0;
    end

    // ---- combinational read path (single-cycle core needs data in the same cycle) ----
    wire        line_hit = valid[index] && (tags[index] == tag);
    wire [31:0] line     = line_hit ? cache[index] : mem[word_addr];

    always @(*) begin
        data_out = 32'b0;
        if (read_en) begin
            case (funct3)
                3'b010: data_out = line;                                   // LW
                3'b001: case (byte_off)                                    // LH
                            2'b00:   data_out = {{16{line[15]}}, line[15:0]};
                            2'b10:   data_out = {{16{line[31]}}, line[31:16]};
                            default: data_out = 32'b0;
                        endcase
                3'b101: case (byte_off)                                    // LHU
                            2'b00:   data_out = {16'b0, line[15:0]};
                            2'b10:   data_out = {16'b0, line[31:16]};
                            default: data_out = 32'b0;
                        endcase
                3'b000: case (byte_off)                                    // LB
                            2'b00: data_out = {{24{line[7]}},  line[7:0]};
                            2'b01: data_out = {{24{line[15]}}, line[15:8]};
                            2'b10: data_out = {{24{line[23]}}, line[23:16]};
                            2'b11: data_out = {{24{line[31]}}, line[31:24]};
                        endcase
                3'b100: case (byte_off)                                    // LBU
                            2'b00: data_out = {24'b0, line[7:0]};
                            2'b01: data_out = {24'b0, line[15:8]};
                            2'b10: data_out = {24'b0, line[23:16]};
                            2'b11: data_out = {24'b0, line[31:24]};
                        endcase
                default: data_out = 32'b0;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < LINES; i = i + 1) begin
                valid[i] <= 1'b0;
                tags[i]  <= 25'b0;
                cache[i] <= 32'b0;
            end
            hit      <= 1'b0;
            miss     <= 1'b0;
        end else if (write_en) begin
            // write-through — write to both cache and memory
            case (funct3)
                3'b010: begin // SW
                    cache[index]    <= write_data;
                    mem[word_addr]  <= write_data;
                end
                3'b001: begin // SH
                    case (byte_off)
                        2'b00: begin
                            cache[index][15:0]   <= write_data[15:0];
                            mem[word_addr][15:0] <= write_data[15:0];
                        end
                        2'b10: begin
                            cache[index][31:16]   <= write_data[15:0];
                            mem[word_addr][31:16] <= write_data[15:0];
                        end
                    endcase
                end
                3'b000: begin // SB
                    case (byte_off)
                        2'b00: begin
                            cache[index][7:0]   <= write_data[7:0];
                            mem[word_addr][7:0] <= write_data[7:0];
                        end
                        2'b01: begin
                            cache[index][15:8]   <= write_data[7:0];
                            mem[word_addr][15:8] <= write_data[7:0];
                        end
                        2'b10: begin
                            cache[index][23:16]   <= write_data[7:0];
                            mem[word_addr][23:16] <= write_data[7:0];
                        end
                        2'b11: begin
                            cache[index][31:24]   <= write_data[7:0];
                            mem[word_addr][31:24] <= write_data[7:0];
                        end
                    endcase
                end
            endcase
            tags[index]  <= tag;
            valid[index] <= 1'b1;
            hit          <= 1'b0;
            miss         <= 1'b0;

        end else if (read_en) begin
            if (valid[index] && tags[index] == tag) begin
                hit  <= 1'b1;
                miss <= 1'b0;
            end else begin
                // miss: refill the line (data_out is already served combinationally from mem)
                cache[index] <= mem[word_addr];
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