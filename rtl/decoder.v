module decoder(
    input  [31:0] instr,
    output reg reg_write,
    output reg alu_src,
    output reg mem_write,
    output reg mem_read,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    output reg [3:0] alu_ctrl
);
    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    always @(*) begin
        reg_write = 0;
        alu_src = 0;
        mem_write = 0;
        mem_read = 0;
        mem_to_reg = 0;
        branch = 0;
        jump = 0;
        alu_ctrl = 4'b0000;
        case(opcode)
             7'b0110011: begin
                reg_write  = 1;
                alu_src    = 0;
                mem_to_reg = 0;
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b010: alu_ctrl = 4'b0101; // SLT
                    3'b001: alu_ctrl = 4'b0110; // SLL
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b1000 : 4'b0111; // SRA : SRL
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            // I-type arithmetic: ADDI ANDI ORI XORI SLTI SLLI SRLI SRAI
            7'b0010011: begin
                reg_write  = 1;
                alu_src    = 1;
                mem_to_reg = 0;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b010: alu_ctrl = 4'b0101; // SLTI
                    3'b001: alu_ctrl = 4'b0110; // SLLI
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b1000 : 4'b0111; // SRAI : SRLI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            // I-type load: LW LH LB
            7'b0000011: begin
                reg_write  = 1;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                alu_ctrl   = 4'b0000; // ADD for address
            end

            // S-type: SW SH SB
            7'b0100011: begin
                alu_src   = 1;
                mem_write = 1;
                alu_ctrl  = 4'b0000; // ADD for address
            end

            // B-type: BEQ BNE BLT BGE
            7'b1100011: begin
                branch   = 1;
                alu_src  = 0;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0001; // BEQ uses SUB, check zero
                    3'b001: alu_ctrl = 4'b0001; // BNE uses SUB, check zero
                    3'b100: alu_ctrl = 4'b0101; // BLT uses SLT
                    3'b101: alu_ctrl = 4'b0101; // BGE uses SLT
                    default: alu_ctrl = 4'b0001;
                endcase
            end

            // U-type: LUI
            7'b0110111: begin
                reg_write  = 1;
                alu_src    = 1;
                mem_to_reg = 0;
                alu_ctrl   = 4'b0000;
            end

            // U-type: AUIPC
            7'b0010111: begin
                reg_write  = 1;
                alu_src    = 1;
                mem_to_reg = 0;
                alu_ctrl   = 4'b0000;
            end

            // J-type: JAL
            7'b1101111: begin
                reg_write  = 1;
                jump       = 1;
                alu_ctrl   = 4'b0000;
            end

            // I-type: JALR
            7'b1100111: begin
                reg_write  = 1;
                alu_src    = 1;
                jump       = 1;
                alu_ctrl   = 4'b0000;
            end

            default: begin
                reg_write  = 0;
                alu_src    = 0;
                mem_write  = 0;
                mem_read   = 0;
                mem_to_reg = 0;
                branch     = 0;
                jump       = 0;
                alu_ctrl   = 4'b0000;
            end
        endcase
    end
endmodule
