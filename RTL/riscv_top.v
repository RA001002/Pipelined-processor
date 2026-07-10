//=============================================================
// riscv_top.v
// Top-level 32-bit, 5-stage pipelined RV32I core.
//
//   IF -> ID -> EX -> MEM -> WB
//
// Hazard handling:
//   - Full EX/MEM and MEM/WB forwarding into EX operands.
//   - Load-use hazard detected in ID, stalls PC + IF/ID for
//     one cycle and bubbles ID/EX.
//   - Branches/jumps resolved in EX; on taken, IF/ID and
//     ID/EX are flushed (2-cycle bubble) and PC is redirected.
//=============================================================
`include "defines.vh"

module riscv_top #(
    parameter IMEM_INIT_FILE = "program.hex"
) (
    input  wire clk,
    input  wire rst_n
);

    //=========================================================
    // ------------------------- IF ---------------------------
    //=========================================================
    wire [31:0] pc_current;
    wire [31:0] pc_plus4_if  = pc_current + 32'd4;
    wire [31:0] if_instr;

    wire        pc_write;
    wire [31:0] pc_next;
    wire        branch_taken_ex;
    wire        jump_taken_ex;
    wire [31:0] branch_target_ex;

    assign pc_next = (branch_taken_ex || jump_taken_ex) ? branch_target_ex
                                                          : pc_plus4_if;

    program_counter u_pc (
        .clk      (clk),
        .rst_n    (rst_n),
        .pc_write (pc_write),
        .pc_next  (pc_next),
        .pc_out   (pc_current)
    );

    instr_mem #(.INIT_FILE(IMEM_INIT_FILE)) u_imem (
        .addr  (pc_current),
        .instr (if_instr)
    );

    //=========================================================
    // ----------------------- IF/ID ---------------------------
    //=========================================================
    wire        if_id_write;
    wire        if_id_flush;

    wire [31:0] id_pc;
    wire [31:0] id_pc_plus4;
    wire [31:0] id_instr;

    if_id_reg u_if_id (
        .clk          (clk),
        .rst_n        (rst_n),
        .stall        (~if_id_write),
        .flush        (if_id_flush),
        .pc_in        (pc_current),
        .pc_plus4_in  (pc_plus4_if),
        .instr_in     (if_instr),
        .pc_out       (id_pc),
        .pc_plus4_out (id_pc_plus4),
        .instr_out    (id_instr)
    );

    //=========================================================
    // ------------------------- ID -----------------------------
    //=========================================================
    wire [6:0] id_opcode   = id_instr[6:0];
    wire [4:0] id_rd_addr  = id_instr[11:7];
    wire [2:0] id_funct3   = id_instr[14:12];
    wire [4:0] id_rs1_addr = id_instr[19:15];
    wire [4:0] id_rs2_addr = id_instr[24:20];
    wire       id_funct7b5 = id_instr[30];

    wire id_reg_write, id_mem_read, id_mem_write;
    wire [1:0] id_wb_sel;
    wire id_alu_src, id_branch, id_jump, id_jalr, id_auipc, id_is_itype, id_illegal;
    wire [1:0] id_alu_op;
    wire [2:0] id_imm_sel;

    control_unit u_ctrl (
        .opcode        (id_opcode),
        .reg_write     (id_reg_write),
        .mem_read      (id_mem_read),
        .mem_write     (id_mem_write),
        .wb_sel        (id_wb_sel),
        .alu_src       (id_alu_src),
        .branch        (id_branch),
        .jump          (id_jump),
        .jalr          (id_jalr),
        .auipc         (id_auipc),
        .alu_op        (id_alu_op),
        .imm_sel       (id_imm_sel),
        .is_itype      (id_is_itype),
        .illegal_instr (id_illegal)
    );

    wire [31:0] id_imm;
    imm_gen u_immgen (
        .instr   (id_instr),
        .imm_sel (id_imm_sel),
        .imm_out (id_imm)
    );

    // ---- WB stage writeback wires (declared here, driven below) ----
    wire        wb_reg_write;
    wire [4:0]  wb_rd_addr;
    wire [31:0] wb_write_data;

    wire [31:0] id_rs1_data, id_rs2_data;
    register_file u_rf (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_write (wb_reg_write),
        .rs1_addr  (id_rs1_addr),
        .rs2_addr  (id_rs2_addr),
        .rd_addr   (wb_rd_addr),
        .rd_data   (wb_write_data),
        .rs1_data  (id_rs1_data),
        .rs2_data  (id_rs2_data)
    );

    //=========================================================
    // -------------------- Hazard detection --------------------
    //=========================================================
    wire ex_mem_read_for_hazard;   // = ID/EX.mem_read (declared after id_ex regs)
    wire [4:0] ex_rd_for_hazard;   // = ID/EX.rd_addr

    hazard_unit u_hazard (
        .id_ex_mem_read  (ex_mem_read_for_hazard),
        .id_ex_rd_addr   (ex_rd_for_hazard),
        .if_id_rs1_addr  (id_rs1_addr),
        .if_id_rs2_addr  (id_rs2_addr),
        .branch_taken    (branch_taken_ex),
        .jump_taken      (jump_taken_ex),
        .pc_write        (pc_write),
        .if_id_write     (if_id_write),
        .if_id_flush     (if_id_flush),
        .id_ex_flush     (id_ex_flush)
    );

    wire id_ex_flush;

    //=========================================================
    // ----------------------- ID/EX -----------------------------
    //=========================================================
    wire ex_reg_write, ex_mem_read, ex_mem_write;
    wire [1:0] ex_wb_sel;
    wire ex_alu_src, ex_branch, ex_jump, ex_jalr, ex_auipc, ex_is_itype;
    wire [1:0] ex_alu_op;

    wire [31:0] ex_pc, ex_pc_plus4, ex_rs1_data, ex_rs2_data, ex_imm;
    wire [4:0]  ex_rs1_addr, ex_rs2_addr, ex_rd_addr;
    wire [2:0]  ex_funct3;
    wire        ex_funct7b5;

    id_ex_reg u_id_ex (
        .clk            (clk),
        .rst_n          (rst_n),
        .flush          (id_ex_flush),

        .reg_write_in   (id_reg_write),
        .mem_read_in    (id_mem_read),
        .mem_write_in   (id_mem_write),
        .wb_sel_in      (id_wb_sel),
        .alu_src_in     (id_alu_src),
        .branch_in      (id_branch),
        .jump_in        (id_jump),
        .jalr_in        (id_jalr),
        .auipc_in       (id_auipc),
        .alu_op_in      (id_alu_op),
        .is_itype_in    (id_is_itype),

        .pc_in          (id_pc),
        .pc_plus4_in    (id_pc_plus4),
        .rs1_data_in    (id_rs1_data),
        .rs2_data_in    (id_rs2_data),
        .imm_in         (id_imm),
        .rs1_addr_in    (id_rs1_addr),
        .rs2_addr_in    (id_rs2_addr),
        .rd_addr_in     (id_rd_addr),
        .funct3_in      (id_funct3),
        .funct7_b5_in   (id_funct7b5),

        .reg_write_out  (ex_reg_write),
        .mem_read_out   (ex_mem_read),
        .mem_write_out  (ex_mem_write),
        .wb_sel_out     (ex_wb_sel),
        .alu_src_out    (ex_alu_src),
        .branch_out     (ex_branch),
        .jump_out       (ex_jump),
        .jalr_out       (ex_jalr),
        .auipc_out      (ex_auipc),
        .alu_op_out     (ex_alu_op),
        .is_itype_out   (ex_is_itype),

        .pc_out         (ex_pc),
        .pc_plus4_out   (ex_pc_plus4),
        .rs1_data_out   (ex_rs1_data),
        .rs2_data_out   (ex_rs2_data),
        .imm_out        (ex_imm),
        .rs1_addr_out   (ex_rs1_addr),
        .rs2_addr_out   (ex_rs2_addr),
        .rd_addr_out    (ex_rd_addr),
        .funct3_out     (ex_funct3),
        .funct7_b5_out  (ex_funct7b5)
    );

    assign ex_mem_read_for_hazard = ex_mem_read;
    assign ex_rd_for_hazard       = ex_rd_addr;

    //=========================================================
    // ------------------------- EX -------------------------------
    //=========================================================
    // ---- forwarding ----
    wire [1:0] fwd_a_sel, fwd_b_sel;

    wire [31:0] memstage_alu_result;   // EX/MEM.alu_result (fwd source)
    wire [4:0]  memstage_rd_addr;
    wire        memstage_reg_write;

    forwarding_unit u_fwd (
        .id_ex_rs1_addr    (ex_rs1_addr),
        .id_ex_rs2_addr    (ex_rs2_addr),
        .ex_mem_rd_addr    (memstage_rd_addr),
        .ex_mem_reg_write  (memstage_reg_write),
        .mem_wb_rd_addr    (wb_rd_addr),
        .mem_wb_reg_write  (wb_reg_write),
        .forward_a         (fwd_a_sel),
        .forward_b         (fwd_b_sel)
    );

    reg [31:0] ex_rs1_fwd, ex_rs2_fwd;
    always @(*) begin
        case (fwd_a_sel)
            `FWD_EXMEM: ex_rs1_fwd = memstage_alu_result;
            `FWD_MEMWB: ex_rs1_fwd = wb_write_data;
            default:    ex_rs1_fwd = ex_rs1_data;
        endcase
        case (fwd_b_sel)
            `FWD_EXMEM: ex_rs2_fwd = memstage_alu_result;
            `FWD_MEMWB: ex_rs2_fwd = wb_write_data;
            default:    ex_rs2_fwd = ex_rs2_data;
        endcase
    end

    wire [31:0] ex_alu_operand_a = ex_auipc ? ex_pc : ex_rs1_fwd;
    wire [31:0] ex_alu_operand_b = ex_alu_src ? ex_imm : ex_rs2_fwd;

    wire [3:0] ex_alu_ctrl;
    alu_control u_alu_ctrl (
        .alu_op     (ex_alu_op),
        .funct3     (ex_funct3),
        .funct7_b5  (ex_funct7b5),
        .is_itype   (ex_is_itype),
        .alu_ctrl   (ex_alu_ctrl)
    );

    wire [31:0] ex_alu_result;
    wire        ex_zero, ex_lt, ex_ltu;
    alu u_alu (
        .operand_a (ex_alu_operand_a),
        .operand_b (ex_alu_operand_b),
        .alu_ctrl  (ex_alu_ctrl),
        .result    (ex_alu_result),
        .zero      (ex_zero),
        .lt        (ex_lt),
        .ltu       (ex_ltu)
    );

    // ---- branch condition resolution ----
    reg branch_cond_met;
    always @(*) begin
        case (ex_funct3)
            3'b000:  branch_cond_met = ex_zero;        // BEQ
            3'b001:  branch_cond_met = ~ex_zero;       // BNE
            3'b100:  branch_cond_met = ex_lt;          // BLT
            3'b101:  branch_cond_met = ~ex_lt;         // BGE
            3'b110:  branch_cond_met = ex_ltu;         // BLTU
            3'b111:  branch_cond_met = ~ex_ltu;        // BGEU
            default: branch_cond_met = 1'b0;
        endcase
    end

    assign branch_taken_ex = ex_branch && branch_cond_met;
    assign jump_taken_ex   = ex_jump;

    // target: JALR -> (rs1 + imm) & ~1 ; JAL/branch -> PC + imm
    wire [31:0] pc_rel_target = ex_pc + ex_imm;
    wire [31:0] jalr_target   = (ex_rs1_fwd + ex_imm) & 32'hFFFF_FFFE;
    assign branch_target_ex = ex_jalr ? jalr_target : pc_rel_target;

    //=========================================================
    // ----------------------- EX/MEM -----------------------------
    //=========================================================
    ex_mem_reg u_ex_mem (
        .clk             (clk),
        .rst_n           (rst_n),
        .reg_write_in    (ex_reg_write),
        .mem_read_in     (ex_mem_read),
        .mem_write_in    (ex_mem_write),
        .wb_sel_in       (ex_wb_sel),
        .funct3_in       (ex_funct3),
        .alu_result_in   (ex_alu_result),
        .pc_plus4_in     (ex_pc_plus4),
        .store_data_in   (ex_rs2_fwd),
        .rd_addr_in      (ex_rd_addr),

        .reg_write_out   (memstage_reg_write),
        .mem_read_out    (mem_mem_read),
        .mem_write_out   (mem_mem_write),
        .wb_sel_out      (mem_wb_sel),
        .funct3_out      (mem_funct3),
        .alu_result_out  (memstage_alu_result),
        .pc_plus4_out    (mem_pc_plus4),
        .store_data_out  (mem_store_data),
        .rd_addr_out     (memstage_rd_addr)
    );

    wire mem_mem_read, mem_mem_write;
    wire [1:0] mem_wb_sel;
    wire [2:0] mem_funct3;
    wire [31:0] mem_pc_plus4, mem_store_data;

    //=========================================================
    // ------------------------- MEM -------------------------------
    //=========================================================
    wire [31:0] mem_read_data;
    data_mem u_dmem (
        .clk        (clk),
        .addr       (memstage_alu_result),
        .write_data (mem_store_data),
        .mem_read   (mem_mem_read),
        .mem_write  (mem_mem_write),
        .funct3     (mem_funct3),
        .read_data  (mem_read_data)
    );

    //=========================================================
    // ----------------------- MEM/WB -----------------------------
    //=========================================================
    mem_wb_reg u_mem_wb (
        .clk            (clk),
        .rst_n          (rst_n),
        .reg_write_in   (memstage_reg_write),
        .wb_sel_in      (mem_wb_sel),
        .alu_result_in  (memstage_alu_result),
        .mem_data_in    (mem_read_data),
        .pc_plus4_in    (mem_pc_plus4),
        .rd_addr_in     (memstage_rd_addr),

        .reg_write_out  (wb_reg_write),
        .wb_sel_out     (wb_wb_sel),
        .alu_result_out (wb_alu_result),
        .mem_data_out   (wb_mem_data),
        .pc_plus4_out   (wb_pc_plus4),
        .rd_addr_out    (wb_rd_addr)
    );

    wire [1:0] wb_wb_sel;
    wire [31:0] wb_alu_result, wb_mem_data, wb_pc_plus4;

    //=========================================================
    // -------------------------- WB --------------------------------
    //=========================================================
    reg [31:0] wb_data_mux;
    always @(*) begin
        case (wb_wb_sel)
            `WB_ALU: wb_data_mux = wb_alu_result;
            `WB_MEM: wb_data_mux = wb_mem_data;
            `WB_PC4: wb_data_mux = wb_pc_plus4;
            default: wb_data_mux = wb_alu_result;
        endcase
    end
    assign wb_write_data = wb_data_mux;

endmodule
