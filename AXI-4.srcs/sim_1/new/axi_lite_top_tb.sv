`timescale 1ns / 1ps
//=====================================================================
// Testbench for axi_lite_top (master + slave integration)
// Drives the CPU-facing interface directly - start/addr/data/write_en/
// read_en - exactly as a real controller would. No AXI-level knowledge
// needed here since that's entirely internal to axi_lite_top now.
//=====================================================================

module tb_axi_lite_top;

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 4;
    localparam int CLK_PERIOD = 10;

    logic                  clk;
    logic                  rst_n;
    logic [DATA_WIDTH-1:0] data;
    logic [ADDR_WIDTH-1:0] addr;
    logic                  start;
    logic                  write_en;
    logic                  read_en;
    logic                  done;
    logic                  error;
    logic [DATA_WIDTH-1:0] rdata_out;

    int pass_count = 0;
    int fail_count = 0;

    axi_lite_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .data       (data),
        .addr       (addr),
        .start      (start),
        .write_en   (write_en),
        .read_en    (read_en),
        .done       (done),
        .error      (error),
        .rdata_out  (rdata_out)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    task automatic reset_dut();
        rst_n    = 0;
        start    = 0;
        write_en = 0;
        read_en  = 0;
        addr     = '0;
        data     = '0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);
    endtask

    task automatic do_write(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] d);
        @(posedge clk);
        addr     = a;
        data     = d;
        write_en = 1;
        read_en  = 0;
        start    = 1;
        @(posedge clk);
        start    = 0;
        write_en = 0;
    endtask

    task automatic do_read(input [ADDR_WIDTH-1:0] a);
        @(posedge clk);
        addr     = a;
        write_en = 0;
        read_en  = 1;
        start    = 1;
        @(posedge clk);
        start    = 0;
        read_en  = 0;
    endtask

    task automatic wait_for_done(output bit timed_out);
        int timeout_cycles;
        timeout_cycles = 0;
        timed_out = 0;
        while (!done) begin
            @(posedge clk);
            timeout_cycles++;
            if (timeout_cycles > 200) begin
                timed_out = 1;
                return;
            end
        end
    endtask

    task automatic check(input bit condition, input string msg);
        if (condition) begin
            pass_count++;
            $display("[PASS] %s", msg);
        end else begin
            fail_count++;
            $display("[FAIL] %s", msg);
        end
    endtask

    bit timed_out;
    logic [DATA_WIDTH-1:0] captured;

    initial begin
        $display("=== AXI-Lite Top (Master+Slave) Integration Testbench ===");
        reset_dut();

        // ---------------------------------------------------------
        // Test 1: write reg0 (addr 0x0), read it back
        // ---------------------------------------------------------
        do_write(4'h0, 32'hDEAD_BEEF);
        wait_for_done(timed_out);
        check(!timed_out && done && !error, "T1a: write to reg0 completed cleanly");
        @(posedge clk);

        do_read(4'h0);
        wait_for_done(timed_out);
        captured = rdata_out;
        check(!timed_out && done && !error, "T1b: read from reg0 completed cleanly");
        check(captured == 32'hDEAD_BEEF, "T1c: reg0 read back matches what was written");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 2: write all four registers with distinct values,
        // then read all four back - checks for cross-talk between
        // registers (i.e. one write accidentally clobbering another)
        // ---------------------------------------------------------
        do_write(4'h0, 32'h1111_1111);
        wait_for_done(timed_out);
        @(posedge clk);
        do_write(4'h4, 32'h2222_2222);
        wait_for_done(timed_out);
        @(posedge clk);
        do_write(4'h8, 32'h3333_3333);
        wait_for_done(timed_out);
        @(posedge clk);
        do_write(4'hC, 32'h4444_4444);
        wait_for_done(timed_out);
        @(posedge clk);

        do_read(4'h0);
        wait_for_done(timed_out);
        check(rdata_out == 32'h1111_1111, "T2a: reg0 holds correct value, unaffected by later writes");
        @(posedge clk);

        do_read(4'h4);
        wait_for_done(timed_out);
        check(rdata_out == 32'h2222_2222, "T2b: reg1 holds correct value");
        @(posedge clk);

        do_read(4'h8);
        wait_for_done(timed_out);
        check(rdata_out == 32'h3333_3333, "T2c: reg2 holds correct value");
        @(posedge clk);

        do_read(4'hC);
        wait_for_done(timed_out);
        check(rdata_out == 32'h4444_4444, "T2d: reg3 holds correct value");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 3: overwrite an existing register, confirm the new
        // value replaces the old one (not just gets OR'd in etc.)
        // ---------------------------------------------------------
        do_write(4'h4, 32'hFFFF_0000);
        wait_for_done(timed_out);
        @(posedge clk);
        do_read(4'h4);
        wait_for_done(timed_out);
        check(rdata_out == 32'hFFFF_0000, "T3: reg1 correctly overwritten with new value");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 4: read an address the slave doesn't decode to a
        // register (unaligned / out-of-range within ADDR_WIDTH) -
        // slave's default case returns 32'h0
        // ---------------------------------------------------------
        do_read(4'h1);
        wait_for_done(timed_out);
        check(!timed_out && done, "T4a: read from undecoded address still completes (no hang)");
        check(rdata_out == 32'h0, "T4b: undecoded address returns default value 0");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 5: back-to-back write immediately followed by read of
        // the SAME address, no idle gap - checks the slave's
        // aw_done/w_done handshake clears properly between txns and
        // doesn't stall or return stale data
        // ---------------------------------------------------------
        do_write(4'h8, 32'hABCD_EF01);
        wait_for_done(timed_out);
        do_read(4'h8);
        wait_for_done(timed_out);
        check(!timed_out && done && !error, "T5a: back-to-back write->read completed cleanly");
        check(rdata_out == 32'hABCD_EF01, "T5b: read immediately after write returns fresh data, not stale");

        // ---------------------------------------------------------
        // Summary
        // ---------------------------------------------------------
        @(posedge clk);
        $display("=====================================");
        $display("TESTS PASSED: %0d", pass_count);
        $display("TESTS FAILED: %0d", fail_count);
        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: %0d TEST(S) FAILED", fail_count);
        $display("=====================================");

        $finish;
    end

    initial begin
        #100000;
        $display("[ERROR] Global simulation timeout - something hung");
        $finish;
    end

endmodule