`timescale 1ns / 1ps
//=====================================================================
// axi_lite_top
// Wires axi_lite_master directly to axi_lite_slave (point-to-point,
// no interconnect/arbitration needed since there's exactly one master
// and one slave). The top level exposes the same "CPU-facing" control
// signals the master already had - start/addr/data/write_en/read_en/
// done/error/rdata_out - so a testbench can drive transactions without
// knowing anything about the AXI bus itself.
//=====================================================================

module axi_lite_top #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // CPU-facing control interface (passthrough to/from the master)
    input  logic [DATA_WIDTH-1:0] data,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic                  start,
    input  logic                  write_en,
    input  logic                  read_en,
    output logic                  done,
    output logic                  error,
    output logic [DATA_WIDTH-1:0] rdata_out
);

    // ---- internal AXI-Lite bus between master and slave ----
    logic [ADDR_WIDTH-1:0] axi_awaddr;
    logic                  axi_awvalid;
    logic                  axi_awready;

    logic [DATA_WIDTH-1:0] axi_wdata;
    logic                  axi_wvalid;
    logic                  axi_wready;

    logic [1:0]            axi_bresp;
    logic                  axi_bvalid;
    logic                  axi_bready;

    logic [ADDR_WIDTH-1:0] axi_araddr;
    logic                  axi_arvalid;
    logic                  axi_arready;

    logic [DATA_WIDTH-1:0] axi_rdata;
    logic [1:0]            axi_rresp;
    logic                  axi_rvalid;
    logic                  axi_rready;

    axi_lite_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_master (
        .clk            (clk),
        .rst_n          (rst_n),

        .m_axi_awaddr   (axi_awaddr),
        .m_axi_awvalid  (axi_awvalid),
        .m_axi_awready  (axi_awready),

        .m_axi_wdata    (axi_wdata),
        .m_axi_wvalid   (axi_wvalid),
        .m_axi_wready   (axi_wready),

        .m_axi_bresp    (axi_bresp),
        .m_axi_bvalid   (axi_bvalid),
        .m_axi_bready   (axi_bready),

        .m_axi_araddr   (axi_araddr),
        .m_axi_arvalid  (axi_arvalid),
        .m_axi_arready  (axi_arready),

        .m_axi_rdata    (axi_rdata),
        .m_axi_rresp    (axi_rresp),
        .m_axi_rvalid   (axi_rvalid),
        .m_axi_rready   (axi_rready),

        .data           (data),
        .addr           (addr),
        .start          (start),
        .done           (done),
        .error          (error),
        .write_en       (write_en),
        .read_en        (read_en),
        .rdata_out      (rdata_out)
    );

    axi_lite_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_slave (
        .clk            (clk),
        .rst_n          (rst_n),

        .s_axi_awaddr   (axi_awaddr),
        .s_axi_awvalid  (axi_awvalid),
        .s_axi_awready  (axi_awready),

        .s_axi_wdata    (axi_wdata),
        .s_axi_wvalid   (axi_wvalid),
        .s_axi_wready   (axi_wready),

        .s_axi_bresp    (axi_bresp),
        .s_axi_bvalid   (axi_bvalid),
        .s_axi_bready   (axi_bready),

        .s_axi_araddr   (axi_araddr),
        .s_axi_arvalid  (axi_arvalid),
        .s_axi_arready  (axi_arready),

        .s_axi_rdata    (axi_rdata),
        .s_axi_rresp    (axi_rresp),
        .s_axi_rvalid   (axi_rvalid),
        .s_axi_rready   (axi_rready)
    );

endmodule