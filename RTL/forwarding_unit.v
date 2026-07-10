//=============================================================
// forwarding_unit.v
// Resolves RAW data hazards by forwarding results from
// EX/MEM and MEM/WB pipeline registers back into the EX
// stage ALU operand muxes. EX/MEM (most recent) has priority
// over MEM/WB.
//=============================================================
`include "defines.vh"

module forwarding_unit (
    input  wire [4:0] id_ex_rs1_addr,
    input  wire [4:0] id_ex_rs2_addr,

    input  wire [4:0] ex_mem_rd_addr,
    input  wire       ex_mem_reg_write,

    input  wire [4:0] mem_wb_rd_addr,
    input  wire       mem_wb_reg_write,

    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);

    always @(*) begin
        // ---- operand A (rs1) ----
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'd0) &&
            (ex_mem_rd_addr == id_ex_rs1_addr))
            forward_a = `FWD_EXMEM;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'd0) &&
                 (mem_wb_rd_addr == id_ex_rs1_addr))
            forward_a = `FWD_MEMWB;
        else
            forward_a = `FWD_NONE;

        // ---- operand B (rs2) ----
        if (ex_mem_reg_write && (ex_mem_rd_addr != 5'd0) &&
            (ex_mem_rd_addr == id_ex_rs2_addr))
            forward_b = `FWD_EXMEM;
        else if (mem_wb_reg_write && (mem_wb_rd_addr != 5'd0) &&
                 (mem_wb_rd_addr == id_ex_rs2_addr))
            forward_b = `FWD_MEMWB;
        else
            forward_b = `FWD_NONE;
    end

endmodule
