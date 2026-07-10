//=============================================================
// program_counter.v
// Simple 32-bit program counter with synchronous reset and
// a stall (write-enable) input used by the hazard unit.
//=============================================================
module program_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire         pc_write,   // 0 = hold (stall)
    input  wire [31:0] pc_next,
    output reg  [31:0] pc_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_out <= 32'h0000_0000;
        else if (pc_write)
            pc_out <= pc_next;
    end

endmodule
