//=============================================================
// data_mem.v
// Byte-addressable data memory, 1024 x 32-bit words (4KB).
// Supports word / halfword / byte load-store per funct3,
// matching RV32I LB/LH/LW/LBU/LHU and SB/SH/SW.
//=============================================================
module data_mem #(
    parameter MEM_WORDS = 1024
) (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  funct3,     // load/store size + sign
    output reg  [31:0] read_data
);

    reg [7:0] mem [0:(MEM_WORDS*4)-1];

    wire [31:0] byte_addr = addr;

    // ---------------- Write ----------------
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB
                    mem[byte_addr] <= write_data[7:0];
                end
                3'b001: begin // SH
                    mem[byte_addr]   <= write_data[7:0];
                    mem[byte_addr+1] <= write_data[15:8];
                end
                default: begin // SW
                    mem[byte_addr]   <= write_data[7:0];
                    mem[byte_addr+1] <= write_data[15:8];
                    mem[byte_addr+2] <= write_data[23:16];
                    mem[byte_addr+3] <= write_data[31:24];
                end
            endcase
        end
    end

    // ---------------- Read (combinational, byte-assembled) ----------------
    wire [31:0] raw_word = {mem[byte_addr+3], mem[byte_addr+2],
                             mem[byte_addr+1], mem[byte_addr]};
    wire [15:0] raw_half = {mem[byte_addr+1], mem[byte_addr]};
    wire [7:0]  raw_byte = mem[byte_addr];

    always @(*) begin
        if (!mem_read)
            read_data = 32'h0000_0000;
        else begin
            case (funct3)
                3'b000: read_data = {{24{raw_byte[7]}},  raw_byte};        // LB
                3'b001: read_data = {{16{raw_half[15]}}, raw_half};        // LH
                3'b010: read_data = raw_word;                              // LW
                3'b100: read_data = {24'b0, raw_byte};                     // LBU
                3'b101: read_data = {16'b0, raw_half};                     // LHU
                default: read_data = raw_word;
            endcase
        end
    end

endmodule
