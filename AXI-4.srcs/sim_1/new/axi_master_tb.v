`timescale 1ns / 1ps
//=====================================================================
// Testbench for axi_lite_master
// Strategy: this module cannot talk AXI to anything by itself, so the
// testbench plays the role of a well-behaved (and later, misbehaving)
// AXI-Lite SLAVE. We drive *ready/valid/resp/data on the slave side,
// issue start/write_en/read_en/addr/data from the "CPU" side, and
// self-check done/error/rdata_out against what we expect.
//=====================================================================

module axi_master_tb (

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 4;
    localparam int CLK_PERIOD = 10; // 100 MHz

    // ---- DUT connections ----
    logic clk;
    logic rst_n;

    logic [ADDR_WIDTH-1:0] m_axi_awaddr;
    logic                  m_axi_awvalid;
    logic                  m_axi_awready;

    logic [DATA_WIDTH-1:0] m_axi_wdata;
    logic                  m_axi_wvalid;
    logic                  m_axi_wready;

    logic [1:0]            m_axi_bresp;
    logic                  m_axi_bvalid;
    logic                  m_axi_bready;

    logic [ADDR_WIDTH-1:0] m_axi_araddr;
    logic                  m_axi_arvalid;
    logic                  m_axi_arready;

    logic [DATA_WIDTH-1:0] m_axi_rdata;
    logic [1:0]            m_axi_rresp;
    logic                  m_axi_rvalid;
    logic                  m_axi_rready;

    logic [DATA_WIDTH-1:0] data;
    logic [ADDR_WIDTH-1:0] addr;
    logic                  start;
    logic                  done;
    logic                  error;
    logic                  write_en;
    logic                  read_en;
    logic [DATA_WIDTH-1:0] rdata_out;

    // ---- test bookkeeping ----
    int pass_count = 0;
    int fail_count = 0;

    // ---- DUT instantiation ----
    axi_lite_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .m_axi_awaddr   (m_axi_awaddr),
        .m_axi_awvalid  (m_axi_awvalid),
        .m_axi_awready  (m_axi_awready),
        .m_axi_wdata    (m_axi_wdata),
        .m_axi_wvalid   (m_axi_wvalid),
        .m_axi_wready   (m_axi_wready),
        .m_axi_bresp    (m_axi_bresp),
        .m_axi_bvalid   (m_axi_bvalid),
        .m_axi_bready   (m_axi_bready),
        .m_axi_araddr   (m_axi_araddr),
        .m_axi_arvalid  (m_axi_arvalid),
        .m_axi_arready  (m_axi_arready),
        .m_axi_rdata    (m_axi_rdata),
        .m_axi_rresp    (m_axi_rresp),
        .m_axi_rvalid   (m_axi_rvalid),
        .m_axi_rready   (m_axi_rready),
        .data           (data),
        .addr           (addr),
        .start          (start),
        .done           (done),
        .error          (error),
        .write_en       (write_en),
        .read_en        (read_en),
        .rdata_out      (rdata_out)
    );

    // ---- clock ----
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //=================================================================
    // Simple AXI-Lite SLAVE model
    // Behavior is controlled by a handful of "knobs" the tests can set
    // before each transaction: response delay, response code, and the
    // read data to return.
    //=================================================================
    int  slave_aw_delay   = 0;   // cycles before awready asserts
    int  slave_w_delay    = 0;
    int  slave_b_delay    = 0;
    int  slave_ar_delay   = 0;
    int  slave_r_delay    = 0;
    logic [1:0] slave_bresp_code = 2'b00;
    logic [1:0] slave_rresp_code = 2'b00;
    logic [DATA_WIDTH-1:0] slave_rdata_to_return = '0;

    // AW channel
    initial begin
        m_axi_awready = 0;
        forever begin
            @(posedge clk);
            if (m_axi_awvalid && !m_axi_awready) begin
                repeat (slave_aw_delay) @(posedge clk);
                m_axi_awready <= 1;
                @(posedge clk);
                m_axi_awready <= 0;
            end
        end
    end

    // W channel
    initial begin
        m_axi_wready = 0;
        forever begin
            @(posedge clk);
            if (m_axi_wvalid && !m_axi_wready) begin
                repeat (slave_w_delay) @(posedge clk);
                m_axi_wready <= 1;
                @(posedge clk);
                m_axi_wready <= 0;
            end
        end
    end

    // B channel (write response) - fires shortly after W handshake completes
    initial begin
        m_axi_bvalid = 0;
        m_axi_bresp  = 2'b00;
        forever begin
            @(posedge clk);
            if (m_axi_wvalid && m_axi_wready) begin
                repeat (slave_b_delay) @(posedge clk);
                m_axi_bvalid <= 1;
                m_axi_bresp  <= slave_bresp_code;
                @(posedge clk);
                while (!m_axi_bready) @(posedge clk);
                m_axi_bvalid <= 0;
            end
        end
    end

    // AR channel
    initial begin
        m_axi_arready = 0;
        forever begin
            @(posedge clk);
            if (m_axi_arvalid && !m_axi_arready) begin
                repeat (slave_ar_delay) @(posedge clk);
                m_axi_arready <= 1;
                @(posedge clk);
                m_axi_arready <= 0;
            end
        end
    end

    // R channel (read data/response) - fires shortly after AR handshake completes
    initial begin
        m_axi_rvalid = 0;
        m_axi_rresp  = 2'b00;
        m_axi_rdata  = '0;
        forever begin
            @(posedge clk);
            if (m_axi_arvalid && m_axi_arready) begin
                repeat (slave_r_delay) @(posedge clk);
                m_axi_rvalid <= 1;
                m_axi_rresp  <= slave_rresp_code;
                m_axi_rdata  <= slave_rdata_to_return;
                @(posedge clk);
                while (!m_axi_rready) @(posedge clk);
                m_axi_rvalid <= 0;
            end
        end
    end

    //=================================================================
    // Helper tasks
    //=================================================================
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

    // Pulses start for exactly one cycle (as discussed - the FSM only
    // needs a single-cycle pulse; holding it high is a caller bug, not
    // something this testbench should rely on)
    task automatic do_write(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] d);
        @(posedge clk);
        addr     = a;
        data     = d;
        write_en = 1;
        read_en  = 0;
        start    = 1;
        @(posedge clk);
        start    = 0;
    endtask

    task automatic do_read(input [ADDR_WIDTH-1:0] a);
        @(posedge clk);
        addr     = a;
        write_en = 0;
        read_en  = 1;
        start    = 1;
        @(posedge clk);
        start    = 0;
    endtask

    // Waits for done to pulse, with a timeout so a stuck FSM doesn't hang
    // the simulation forever.
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

    //=================================================================
    // Test sequence
    //=================================================================
    bit timed_out;

    initial begin
        $display("=== AXI-Lite Master Testbench ===");
        reset_dut();

        // ---------------------------------------------------------
        // Test 1: Basic write, immediate slave response, OKAY
        // ---------------------------------------------------------
        slave_aw_delay = 0; slave_w_delay = 0; slave_b_delay = 0;
        slave_bresp_code = 2'b00;
        do_write(4'hA, 32'hDEAD_BEEF);
        wait_for_done(timed_out);
        check(!timed_out, "T1: write completed without timeout");
        check(done && !error, "T1: done asserted, no error, OKAY response");
        check(m_axi_awaddr == 4'hA, "T1: awaddr matched requested address");
        check(m_axi_wdata  == 32'hDEAD_BEEF, "T1: wdata matched requested data");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 2: Write with slave inserting wait states on AW and W
        // ---------------------------------------------------------
        slave_aw_delay = 3; slave_w_delay = 2; slave_b_delay = 1;
        slave_bresp_code = 2'b00;
        do_write(4'h3, 32'h1234_5678);
        wait_for_done(timed_out);
        check(!timed_out, "T2: write with slave delays completed without timeout");
        check(done && !error, "T2: done asserted, no error, despite wait states");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 3: Write receives SLVERR - error flag must assert
        // ---------------------------------------------------------
        slave_aw_delay = 0; slave_w_delay = 0; slave_b_delay = 0;
        slave_bresp_code = 2'b10; // SLVERR
        do_write(4'h5, 32'hCAFEF00D);
        wait_for_done(timed_out);
        check(!timed_out, "T3: write with SLVERR completed without timeout");
        check(done && error, "T3: error flag correctly set on SLVERR response");
        slave_bresp_code = 2'b00; // reset for later tests
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 4: Basic read, immediate slave response, OKAY
        // ---------------------------------------------------------
        slave_ar_delay = 0; slave_r_delay = 0;
        slave_rresp_code = 2'b00;
        slave_rdata_to_return = 32'hABCD_1234;
        do_read(4'h7);
        wait_for_done(timed_out);
        check(!timed_out, "T4: read completed without timeout");
        check(done && !error, "T4: done asserted, no error, OKAY response");
        check(m_axi_araddr == 4'h7, "T4: araddr matched requested address");
        check(rdata_out == 32'hABCD_1234, "T4: rdata_out captured correct read data");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 5: Read with slave wait states on AR and R
        // ---------------------------------------------------------
        slave_ar_delay = 2; slave_r_delay = 3;
        slave_rdata_to_return = 32'h5555_AAAA;
        do_read(4'h1);
        wait_for_done(timed_out);
        check(!timed_out, "T5: read with slave delays completed without timeout");
        check(done && !error, "T5: done asserted, no error, despite wait states");
        check(rdata_out == 32'h5555_AAAA, "T5: rdata_out correct despite wait states");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 6: Read receives DECERR - error flag must assert
        // ---------------------------------------------------------
        slave_ar_delay = 0; slave_r_delay = 0;
        slave_rresp_code = 2'b11; // DECERR
        do_read(4'hF);
        wait_for_done(timed_out);
        check(!timed_out, "T6: read with DECERR completed without timeout");
        check(done && error, "T6: error flag correctly set on DECERR response");
        slave_rresp_code = 2'b00;
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 7: Back-to-back write then read, verify no state bleed
        // ---------------------------------------------------------
        slave_bresp_code = 2'b00;
        slave_rresp_code = 2'b00;
        slave_rdata_to_return = 32'h1111_2222;
        do_write(4'h2, 32'hFFFF_0000);
        wait_for_done(timed_out);
        check(!timed_out && done && !error, "T7a: back-to-back write ok");
        @(posedge clk);
        do_read(4'h2);
        wait_for_done(timed_out);
        check(!timed_out && done && !error, "T7b: back-to-back read ok");
        check(rdata_out == 32'h1111_2222, "T7c: read data correct after preceding write");
        @(posedge clk);

        // ---------------------------------------------------------
        // Test 8: addr/data change during transaction must NOT
        // disturb an in-flight transfer (checks addr_reg/data_reg
        // latching actually holds the bus stable)
        // ---------------------------------------------------------
        slave_aw_delay = 4; slave_w_delay = 0; slave_b_delay = 0;
        @(posedge clk);
        addr = 4'h9; data = 32'hA0A0_A0A0;
        write_en = 1; read_en = 0; start = 1;
        @(posedge clk);
        start = 0;
        // Mimic a sloppy caller changing addr/data while the master
        // is still waiting on awready
        @(posedge clk);
        addr = 4'h0; data = 32'h0;
        wait_for_done(timed_out);
        check(!timed_out, "T8: transaction completed despite caller changing addr/data mid-flight");
        check(m_axi_awaddr == 4'h9, "T8: awaddr stayed stable at latched value, not corrupted by later addr change");
        check(m_axi_wdata  == 32'hA0A0_A0A0, "T8: wdata stayed stable at latched value, not corrupted by later data change");
        slave_aw_delay = 0;

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

    // Safety timeout for the whole simulation
    initial begin
        #100000;
        $display("[ERROR] Global simulation timeout - something hung");
        $finish;
    end

endmodule