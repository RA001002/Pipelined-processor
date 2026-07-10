//=============================================================
// control_unit.v
// Combinational main decoder. Produces the full set of
// datapath control signals from the opcode field only
// (funct3/funct7 are resolved later by alu_control.v).
//=============================================================
`include "defines.vh"

module control_unit (
    input  wire [6:0] opcode,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg  [1:0] wb_sel,      // WB_ALU / WB_MEM / WB_PC4
    output reg        alu_src,     // 0 = rs2, 1 = immediate
    output reg        branch,      // instruction is a conditional branch
    output reg        jump,        // instruction is JAL or JALR
    output reg        jalr,        // 1 for JALR (base = rs1, not PC)
    output reg        auipc,       // 1 for AUIPC (ALU operand_a = PC)
    output reg  [1:0] alu_op,
    output reg  [2:0] imm_sel,
    output reg        is_itype,    // 1 for OP_ITYPE (ADDI never treated as SUB)
    output reg        illegal_instr
);

    always @(*) begin
        // ---- safe defaults (NOP) ----
        reg_write     = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        wb_sel        = `WB_ALU;
        alu_src       = 1'b0;
        branch        = 1'b0;
        jump          = 1'b0;
        jalr          = 1'b0;
        auipc         = 1'b0;
        alu_op        = 2'b10;
        imm_sel       = `IMM_I;
        is_itype      = 1'b0;
        illegal_instr = 1'b0;

        case (opcode)
            `OP_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
                wb_sel    = `WB_ALU;
            end

            `OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b10;
                imm_sel   = `IMM_I;
                wb_sel    = `WB_ALU;
                is_itype  = 1'b1;
            end

            `OP_LOAD: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;   // address = rs1 + imm
                imm_sel   = `IMM_I;
                mem_read  = 1'b1;
                wb_sel    = `WB_MEM;
            end

            `OP_STORE: begin
                alu_src   = 1'b1;
                alu_op    = 2'b00;   // address = rs1 + imm
                imm_sel   = `IMM_S;
                mem_write = 1'b1;
            end

            `OP_BRANCH: begin
                alu_src   = 1'b0;    // compare rs1 vs rs2 directly
                alu_op    = 2'b00;
                imm_sel   = `IMM_B;
                branch    = 1'b1;
            end

            `OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                imm_sel   = `IMM_J;
                wb_sel    = `WB_PC4;
            end

            `OP_JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                jalr      = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;   // target = rs1 + imm
                imm_sel   = `IMM_I;
                wb_sel    = `WB_PC4;
            end

            `OP_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b01;   // pass-through immediate
                imm_sel   = `IMM_U;
                wb_sel    = `WB_ALU;
            end

            `OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                auipc     = 1'b1;
                alu_op    = 2'b00;   // result = PC + imm
                imm_sel   = `IMM_U;
                wb_sel    = `WB_ALU;
            end

            default: begin
                illegal_instr = 1'b1;
            end
        endcase
    end

endmodule
