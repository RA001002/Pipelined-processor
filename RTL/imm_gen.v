//=============================================================
// imm_gen.v
// Sign-extends and reassembles the correct immediate field
// out of the 32-bit instruction based on imm_sel (from the
// control unit).
//=============================================================
`include "defines.vh"

module imm_gen (
    input  wire [31:0] instr,
    input  wire [2:0]  imm_sel,
    output reg  [31:0] imm_out
);

    always @(*) begin
        case (imm_sel)
            `IMM_I: imm_out = {{20{instr[31]}}, instr[31:20]};

            `IMM_S: imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            `IMM_B: imm_out = {{19{instr[31]}}, instr[31], instr[7],
                                instr[30:25], instr[11:8], 1'b0};

            `IMM_U: imm_out = {instr[31:12], 12'b0};

            `IMM_J: imm_out = {{11{instr[31]}}, instr[31], instr[19:12],
                                instr[20], instr[30:21], 1'b0};

            default: imm_out = 32'h0;
        endcase
    end

endmodule
