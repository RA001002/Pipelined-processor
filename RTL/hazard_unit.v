//=============================================================
// hazard_unit.v
// Generates pipeline control overrides for:
//   1) Load-use data hazard  -> 1-cycle stall (bubble in EX)
//   2) Taken branch / jump   -> flush IF/ID and ID/EX
//
// Branch/jump resolution happens in EX, so on a taken branch
// the two younger instructions currently in IF and ID must be
// squashed.
//=============================================================
module hazard_unit (
    // load-use detection (compares ID/EX vs IF/ID)
    input  wire        id_ex_mem_read,
    input  wire [4:0]  id_ex_rd_addr,
    input  wire [4:0]  if_id_rs1_addr,
    input  wire [4:0]  if_id_rs2_addr,

    // control-flow resolution (from EX stage)
    input  wire        branch_taken,   // conditional branch resolved taken
    input  wire        jump_taken,     // JAL / JALR (always taken)

    output wire        pc_write,       // 0 = hold PC (stall)
    output wire        if_id_write,    // 0 = hold IF/ID (stall)
    output wire        if_id_flush,    // 1 = squash IF/ID (bubble)
    output wire        id_ex_flush     // 1 = squash ID/EX (bubble)
);

    wire load_use_hazard;
    assign load_use_hazard = id_ex_mem_read &&
                              (id_ex_rd_addr != 5'd0) &&
                              ((id_ex_rd_addr == if_id_rs1_addr) ||
                               (id_ex_rd_addr == if_id_rs2_addr));

    wire control_hazard = branch_taken || jump_taken;

    // Stall for load-use: freeze PC + IF/ID, bubble ID/EX
    assign pc_write    = ~load_use_hazard;
    assign if_id_write = ~load_use_hazard;

    // A resolved branch/jump always wins and squashes younger
    // instructions currently sitting in IF/ID and ID/EX.
    assign if_id_flush = control_hazard;
    assign id_ex_flush = load_use_hazard || control_hazard;

endmodule
