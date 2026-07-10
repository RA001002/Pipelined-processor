//=============================================================
// id_ex_reg.v
// ID/EX pipeline register.
//   flush -> clears all control signals (inserts a bubble),
//            used both for load-use stalls and taken
//            branch/jump squashes.
//=============================================================
module id_ex_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,

    // ---- control in ----
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [1:0]  wb_sel_in,
    input  wire        alu_src_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire        jalr_in,
    input  wire        auipc_in,
    input  wire [1:0]  alu_op_in,
    input  wire        is_itype_in,

    // ---- data in ----
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [2:0]  funct3_in,
    input  wire        funct7_b5_in,

    // ---- control out ----
    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg  [1:0]  wb_sel_out,
    output reg         alu_src_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg         jalr_out,
    output reg         auipc_out,
    output reg  [1:0]  alu_op_out,
    output reg         is_itype_out,

    // ---- data out ----
    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [4:0]  rd_addr_out,
    output reg  [2:0]  funct3_out,
    output reg         funct7_b5_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            reg_write_out <= 1'b0;
            mem_read_out  <= 1'b0;
            mem_write_out <= 1'b0;
            wb_sel_out    <= 2'b00;
            alu_src_out   <= 1'b0;
            branch_out    <= 1'b0;
            jump_out      <= 1'b0;
            jalr_out      <= 1'b0;
            auipc_out     <= 1'b0;
            alu_op_out    <= 2'b00;
            is_itype_out  <= 1'b0;

            pc_out        <= 32'h0;
            pc_plus4_out  <= 32'h0;
            rs1_data_out  <= 32'h0;
            rs2_data_out  <= 32'h0;
            imm_out       <= 32'h0;
            rs1_addr_out  <= 5'h0;
            rs2_addr_out  <= 5'h0;
            rd_addr_out   <= 5'h0;
            funct3_out    <= 3'h0;
            funct7_b5_out <= 1'b0;
        end else begin
            reg_write_out <= reg_write_in;
            mem_read_out  <= mem_read_in;
            mem_write_out <= mem_write_in;
            wb_sel_out    <= wb_sel_in;
            alu_src_out   <= alu_src_in;
            branch_out    <= branch_in;
            jump_out      <= jump_in;
            jalr_out      <= jalr_in;
            auipc_out     <= auipc_in;
            alu_op_out    <= alu_op_in;
            is_itype_out  <= is_itype_in;

            pc_out        <= pc_in;
            pc_plus4_out  <= pc_plus4_in;
            rs1_data_out  <= rs1_data_in;
            rs2_data_out  <= rs2_data_in;
            imm_out       <= imm_in;
            rs1_addr_out  <= rs1_addr_in;
            rs2_addr_out  <= rs2_addr_in;
            rd_addr_out   <= rd_addr_in;
            funct3_out    <= funct3_in;
            funct7_b5_out <= funct7_b5_in;
        end
    end

endmodule
