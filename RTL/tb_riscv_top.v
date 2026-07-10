//=============================================================
// tb_riscv_top.v
// Self-checking testbench for riscv_top.
//
// Loads sim/program.hex (see scripts/mini_asm.py for how it
// was generated) which exercises:
//   - back-to-back ALU forwarding (EX/MEM -> EX)
//   - load-use hazard stall
//   - store / load
//   - taken branch with pipeline flush
//   - JAL with pipeline flush and link-register capture
//
// At the end of simulation the architectural register file is
// checked against the expected golden values.
//=============================================================
`timescale 1ns/1ps

module tb_riscv_top;

    reg clk;
    reg rst_n;

    riscv_top #(
        .IMEM_INIT_FILE("program.hex")
    ) dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ---- 100 MHz simulated clock ----
    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer i;
    integer errors;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_riscv_top);

        rst_n  = 1'b0;
        errors = 0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // Program is 14 instructions long and ends in a self-loop
        // (BEQ x0,x0,0). Give it comfortably more cycles than
        // needed to drain the pipeline, then sample architectural
        // state.
        repeat (60) @(posedge clk);

        $display("=====================================================");
        $display(" Register file snapshot after simulation");
        $display("=====================================================");
        for (i = 0; i < 12; i = i + 1)
            $display(" x%0d = %0d", i, $signed(dut.u_rf.regs[i]));
        $display(" x20 = %0d", $signed(dut.u_rf.regs[20]));
        $display(" x21 = %0d", $signed(dut.u_rf.regs[21]));

        check(1,  5,   "x1  (addi)");
        check(2,  10,  "x2  (addi)");
        check(3,  15,  "x3  (add, forwarded)");
        check(4,  10,  "x4  (sub, forwarded)");
        check(5,  15,  "x5  (lw)");
        check(6,  15,  "x6  (add after load-use hazard)");
        check(8,  1,   "x8  (branch target, post-flush)");
        check(9,  44,  "x9  (JAL link address)");
        check(11, 7,   "x11 (JAL target)");
        check(20, 0,   "x20 (must be squashed by branch flush)");
        check(21, 0,   "x21 (must be squashed by JAL flush)");

        $display("=====================================================");
        if (errors == 0)
            $display(" ALL CHECKS PASSED");
        else
            $display(" %0d CHECK(S) FAILED", errors);
        $display("=====================================================");

        $finish;
    end

    task check(input integer reg_num, input integer expected, input [255:0] label);
        reg signed [31:0] actual;
        begin
            actual = dut.u_rf.regs[reg_num];
            if (actual !== expected) begin
                $display(" [FAIL] %0s : expected=%0d actual=%0d", label, expected, actual);
                errors = errors + 1;
            end else begin
                $display(" [PASS] %0s : %0d", label, actual);
            end
        end
    endtask

endmodule
