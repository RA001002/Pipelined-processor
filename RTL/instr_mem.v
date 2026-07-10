//=============================================================
// instr_mem.v
// Read-only instruction memory. 1024 x 32-bit words (4KB).
// Loaded at elaboration time from a $readmemh file so the
// program can be swapped without touching RTL.
//=============================================================
module instr_mem #(
    parameter MEM_WORDS = 1024,
    parameter INIT_FILE = "program.hex"
) (
    input  wire [31:0] addr,      // byte address (word-aligned)
    output wire [31:0] instr
);

    reg [31:0] mem [0:MEM_WORDS-1];

    initial begin
        // Zero-fill first so unused instruction slots are NOPs
        // (0x00000013 = ADDI x0,x0,0), then load the program.
        integer i;
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'h0000_0013;
        $readmemh(INIT_FILE, mem);
    end

    // word-aligned access, ignore addr[1:0]
    assign instr = mem[addr[31:2]];

endmodule
