//=============================================================
// alu.v
// 32-bit ALU. `zero`, `lt` (signed less-than) and `ltu`
// (unsigned less-than) flags are computed independently of
// alu_ctrl so the EX stage can resolve branch conditions
// without a dedicated "subtract for branches" ALU mode.
//=============================================================
`include "defines.vh"

module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire         zero,
    output wire         lt,     // signed   operand_a < operand_b
    output wire         ltu     // unsigned operand_a < operand_b
);

    wire signed [31:0] signed_a = operand_a;
    wire signed [31:0] signed_b = operand_b;

    always @(*) begin
        case (alu_ctrl)
            `ALU_ADD:   result = operand_a + operand_b;
            `ALU_SUB:   result = operand_a - operand_b;
            `ALU_AND:   result = operand_a & operand_b;
            `ALU_OR:    result = operand_a | operand_b;
            `ALU_XOR:   result = operand_a ^ operand_b;
            `ALU_SLL:   result = operand_a << operand_b[4:0];
            `ALU_SRL:   result = operand_a >> operand_b[4:0];
            `ALU_SRA:   result = signed_a >>> operand_b[4:0];
            `ALU_SLT:   result = {31'b0, (signed_a < signed_b)};
            `ALU_SLTU:  result = {31'b0, (operand_a < operand_b)};
            `ALU_PASSB: result = operand_b;
            default:    result = 32'h0;
        endcase
    end

    assign zero = (operand_a == operand_b);
    assign lt   = (signed_a < signed_b);
    assign ltu  = (operand_a < operand_b);

endmodule
