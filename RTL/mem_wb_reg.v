//=============================================================
// mem_wb_reg.v
// MEM/WB pipeline register.
//=============================================================
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        reg_write_in,
    input  wire [1:0]  wb_sel_in,

    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_data_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [4:0]  rd_addr_in,

    output reg          reg_write_out,
    output reg  [1:0]   wb_sel_out,

    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_data_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [4:0]  rd_addr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            wb_sel_out     <= 2'b00;
            alu_result_out <= 32'h0;
            mem_data_out   <= 32'h0;
            pc_plus4_out   <= 32'h0;
            rd_addr_out    <= 5'h0;
        end else begin
            reg_write_out  <= reg_write_in;
            wb_sel_out     <= wb_sel_in;
            alu_result_out <= alu_result_in;
            mem_data_out   <= mem_data_in;
            pc_plus4_out   <= pc_plus4_in;
            rd_addr_out    <= rd_addr_in;
        end
    end

endmodule
