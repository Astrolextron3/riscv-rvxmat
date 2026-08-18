module memory (
    input         clk,
    input         mem_write,
    input         mem_read,
    input  [2:0]  funct3,
    input  [31:0] addr,
    input  [31:0] write_data,
    output reg [31:0] read_data
);

    reg [31:0] mem [0:1023];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'b0;

        // Load hex instructions into memory array
        $readmemh("program.hex", mem, 0, 4);
        $display("Memory initialized from program.hex");
    end

    wire [9:0]  word_addr   = addr[11:2];
    wire [1:0]  byte_offset = addr[1:0];

    // READS (combinational)
    always @(*) begin
        read_data = 32'b0;
        if (mem_read) begin
            case (funct3)
                3'b010: read_data = mem[word_addr];
                3'b001: begin
                    case (byte_offset)
                        2'b00: read_data = {{16{mem[word_addr][15]}}, mem[word_addr][15:0]};
                        2'b10: read_data = {{16{mem[word_addr][31]}}, mem[word_addr][31:16]};
                        default: read_data = 32'b0;
                    endcase
                end
                3'b000: begin
                    case (byte_offset)
                        2'b00: read_data = {{24{mem[word_addr][7]}},  mem[word_addr][7:0]};
                        2'b01: read_data = {{24{mem[word_addr][15]}}, mem[word_addr][15:8]};
                        2'b10: read_data = {{24{mem[word_addr][23]}}, mem[word_addr][23:16]};
                        2'b11: read_data = {{24{mem[word_addr][31]}}, mem[word_addr][31:24]};
                    endcase
                end
                3'b101: begin
                    case (byte_offset)
                        2'b00: read_data = {16'b0, mem[word_addr][15:0]};
                        2'b10: read_data = {16'b0, mem[word_addr][31:16]};
                        default: read_data = 32'b0;
                    endcase
                end
                3'b100: begin
                    case (byte_offset)
                        2'b00: read_data = {24'b0, mem[word_addr][7:0]};
                        2'b01: read_data = {24'b0, mem[word_addr][15:8]};
                        2'b10: read_data = {24'b0, mem[word_addr][23:16]};
                        2'b11: read_data = {24'b0, mem[word_addr][31:24]};
                    endcase
                end
                default: read_data = 32'b0;
            endcase
        end
    end

    // WRITES (synchronous)
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b010: mem[word_addr] <= write_data;
                3'b001: begin
                    case (byte_offset)
                        2'b00: mem[word_addr][15:0]  <= write_data[15:0];
                        2'b10: mem[word_addr][31:16] <= write_data[15:0];
                    endcase
                end
                3'b000: begin
                    case (byte_offset)
                        2'b00: mem[word_addr][7:0]   <= write_data[7:0];
                        2'b01: mem[word_addr][15:8]  <= write_data[7:0];
                        2'b10: mem[word_addr][23:16] <= write_data[7:0];
                        2'b11: mem[word_addr][31:24] <= write_data[7:0];
                    endcase
                end
            endcase
        end
    end

endmodule