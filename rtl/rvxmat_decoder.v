module rvxmat_decoder (
    input  [31:0] instr,
    output reg    mac_en,
    output reg    clr_en,
    output reg    rvxmat_reg_write,
    output reg [4:0] rvxmat_rd,
    output reg [4:0] rvxmat_rs1,
    output reg [4:0] rvxmat_rs2
);
    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];

    always @(*) begin
        mac_en           = 1'b0;
        clr_en           = 1'b0;
        rvxmat_reg_write = 1'b0;
        rvxmat_rd        = 5'b0;
        rvxmat_rs1       = 5'b0;
        rvxmat_rs2       = 5'b0;

        if (opcode == 7'b0001011) begin
            rvxmat_rd  = instr[11:7];
            rvxmat_rs1 = instr[19:15];
            rvxmat_rs2 = instr[24:20];

            case (funct3)
                3'b000: begin // VMAC
                    mac_en           = 1'b1;
                    rvxmat_reg_write = 1'b1;
                end
                3'b010: begin // VCLR
                    clr_en           = 1'b1;
                    rvxmat_reg_write = 1'b1;
                end
                default: begin
                    mac_en = 1'b0;
                    clr_en = 1'b0;
                end
            endcase
        end
    end

endmodule