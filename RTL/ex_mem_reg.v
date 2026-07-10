//=============================================================
// ex_mem_reg.v
// EX/MEM pipeline register.
//=============================================================
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [1:0]  wb_sel_in,
    input  wire [2:0]  funct3_in,

    input  wire [31:0] alu_result_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] store_data_in,
    input  wire [4:0]  rd_addr_in,

    output reg          reg_write_out,
    output reg          mem_read_out,
    output reg          mem_write_out,
    output reg  [1:0]   wb_sel_out,
    output reg  [2:0]   funct3_out,

    output reg  [31:0] alu_result_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] store_data_out,
    output reg  [4:0]  rd_addr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            wb_sel_out     <= 2'b00;
            funct3_out     <= 3'h0;
            alu_result_out <= 32'h0;
            pc_plus4_out   <= 32'h0;
            store_data_out <= 32'h0;
            rd_addr_out    <= 5'h0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            wb_sel_out     <= wb_sel_in;
            funct3_out     <= funct3_in;
            alu_result_out <= alu_result_in;
            pc_plus4_out   <= pc_plus4_in;
            store_data_out <= store_data_in;
            rd_addr_out    <= rd_addr_in;
        end
    end

endmodule
