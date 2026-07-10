//=============================================================
// alu_control.v
// Generates the 4-bit ALU operation code from:
//   - alu_op (2-bit, coarse category from main control unit)
//   - funct3 (instr[14:12])
//   - funct7[5] (instr[30], the R-type/SRAI "alt" bit)
//
// alu_op encoding:
//   00 -> ADD  (loads, stores, AUIPC, JAL/JALR target calc)
//   01 -> LUI passthrough (result = operand_b)
//   10 -> R-type / I-type ALU op, decode via funct3/funct7[5]
//   11 -> unused
//=============================================================
`include "defines.vh"

module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_b5,
    input  wire       is_itype,   // 1 = I-type ALU instr (SRAI/SLLI use funct7 too, but immediate variants of ADD/SLT/etc never use funct7_b5 for ADD)
    output reg  [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = `ALU_ADD;
            2'b01: alu_ctrl = `ALU_PASSB;
            2'b10: begin
                case (funct3)
                    3'b000: alu_ctrl = (funct7_b5 && !is_itype) ? `ALU_SUB : `ALU_ADD; // ADD/SUB or ADDI
                    3'b001: alu_ctrl = `ALU_SLL;
                    3'b010: alu_ctrl = `ALU_SLT;
                    3'b011: alu_ctrl = `ALU_SLTU;
                    3'b100: alu_ctrl = `ALU_XOR;
                    3'b101: alu_ctrl = funct7_b5 ? `ALU_SRA : `ALU_SRL; // SRA(I) or SRL(I)
                    3'b110: alu_ctrl = `ALU_OR;
                    3'b111: alu_ctrl = `ALU_AND;
                    default: alu_ctrl = `ALU_ADD;
                endcase
            end
            default: alu_ctrl = `ALU_ADD;
        endcase
    end

endmodule
