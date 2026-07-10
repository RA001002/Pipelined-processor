//=============================================================
// defines.vh - Shared opcode / ALU-control / immediate-type
//              parameters for the RV32I pipelined core
//=============================================================
`ifndef DEFINES_VH
`define DEFINES_VH

// ---------------- RV32I opcodes (bits [6:0]) ----------------
`define OP_RTYPE   7'b0110011   // R-type   ADD/SUB/AND/OR/...
`define OP_ITYPE   7'b0010011   // I-type   ADDI/ANDI/...
`define OP_LOAD    7'b0000011   // LW/LH/LB/LHU/LBU
`define OP_STORE   7'b0100011   // SW/SH/SB
`define OP_BRANCH  7'b1100011   // BEQ/BNE/BLT/BGE/BLTU/BGEU
`define OP_JAL     7'b1101111
`define OP_JALR    7'b1100111
`define OP_LUI     7'b0110111
`define OP_AUIPC   7'b0010111

// ---------------- ALU control codes --------------------------
`define ALU_ADD    4'b0000
`define ALU_SUB    4'b0001
`define ALU_AND    4'b0010
`define ALU_OR     4'b0011
`define ALU_XOR    4'b0100
`define ALU_SLL    4'b0101
`define ALU_SRL    4'b0110
`define ALU_SRA    4'b0111
`define ALU_SLT    4'b1000
`define ALU_SLTU   4'b1001
`define ALU_PASSB  4'b1010   // used for LUI (result = operand_b)

// ---------------- Immediate-type select -----------------------
`define IMM_I      3'b000
`define IMM_S      3'b001
`define IMM_B      3'b010
`define IMM_U      3'b011
`define IMM_J      3'b100

// ---------------- WB mux select ---------------------------------
`define WB_ALU     2'b00   // ALU result
`define WB_MEM     2'b01   // data memory read
`define WB_PC4     2'b10   // PC + 4  (JAL / JALR link)

// ---------------- Forwarding mux select ---------------------------
`define FWD_NONE   2'b00
`define FWD_EXMEM  2'b10
`define FWD_MEMWB  2'b01

`endif
