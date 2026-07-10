//=============================================================
// register_file.v
// 32 x 32-bit general purpose registers.
// - Two combinational (asynchronous) read ports.
// - One synchronous write port.
// - x0 is hardwired to zero (writes to it are discarded).
// - Includes an internal "write-first" combinational bypass so
//   that a WB-stage write and an ID-stage read of the same
//   register in the same cycle return the NEW value (the
//   standard technique used to avoid a dedicated MEM/WB->ID
//   forwarding path).
//=============================================================
module register_file (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_write,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    reg [31:0] regs [0:31];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h0;
        end else if (reg_write && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

    wire rs1_bypass = reg_write && (rd_addr != 5'd0) && (rd_addr == rs1_addr);
    wire rs2_bypass = reg_write && (rd_addr != 5'd0) && (rd_addr == rs2_addr);

    assign rs1_data = (rs1_addr == 5'd0) ? 32'h0 :
                       rs1_bypass          ? rd_data :
                                             regs[rs1_addr];

    assign rs2_data = (rs2_addr == 5'd0) ? 32'h0 :
                       rs2_bypass          ? rd_data :
                                             regs[rs2_addr];

endmodule
