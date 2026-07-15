`timescale 1ns / 1ps
module slave_tb #(
parameter int DATA_WIDTH=32,
parameter int ADDR_WIDTH=4
    );
logic clk;
logic rst_n;
logic [ADDR_WIDTH-1:0] s_axi_awaddr;
logic s_axi_awvalid;
logic s_axi_awready;
logic [DATA_WIDTH-1:0] s_axi_wdata;
logic s_axi_wvalid;
logic s_axi_wready;
logic [1:0]            s_axi_bresp;
logic                  s_axi_bvalid;
logic                  s_axi_bready;
logic [ADDR_WIDTH-1:0] s_axi_araddr;
logic s_axi_arvalid;
logic s_axi_arready;
logic [DATA_WIDTH-1:0] s_axi_rdata;
logic [1:0]            s_axi_rresp;
logic                  s_axi_rvalid;
logic                  s_axi_rready;

//if a signal is driven by master, tb will assign value
//if a signal is driven by slave, tb will only observe it
axi_lite_slave #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
dut(
   .clk(clk),
   .rst_n(rst_n),
   .s_axi_awaddr(s_axi_awaddr),
   .s_axi_awvalid(s_axi_awvalid),
   .s_axi_awready(s_axi_awready),
   .s_axi_wdata(s_axi_wdata),
   .s_axi_wvalid(s_axi_wvalid),
   .s_axi_wready(s_axi_wready),
   .s_axi_bresp(s_axi_bresp),
   .s_axi_bvalid(s_axi_bvalid),
   .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
   .s_axi_arvalid(s_axi_arvalid),
   .s_axi_arready(s_axi_arready),
   .s_axi_rdata(s_axi_rdata),
   .s_axi_rvalid(s_axi_rvalid),
   .s_axi_rready(s_axi_rready),
   .s_axi_rresp(s_axi_rresp)
);
initial
    clk = 0;
always
    #5 clk = ~clk;
task axi_write(
input [ADDR_WIDTH-1:0] addr,
input [DATA_WIDTH-1:0] data);
begin
@(posedge clk);
s_axi_awaddr<=addr;
s_axi_awvalid<=1;

s_axi_wdata<=data;
s_axi_wvalid<=1;

wait(s_axi_awready && s_axi_wready);//reseting the singla when both the channels have accepted
  @(posedge clk);
        s_axi_awvalid <= 0;
        s_axi_wvalid  <= 0;
 wait(s_axi_bvalid);
 s_axi_bready <= 1;
        @(posedge clk);
        s_axi_bready <= 0;
        $display("[%0t] WRITE Address=%h Data=%h",
                 $time, addr, data);
        
end
endtask    

task axi_read(
input [ADDR_WIDTH-1:0] addr,
output [DATA_WIDTH-1:0] data);
begin
@(posedge clk);
s_axi_araddr<=addr;
s_axi_arvalid<=1;
 wait(s_axi_arready);
        @(posedge clk);
        s_axi_arvalid <= 0;
wait(s_axi_rvalid);
data = s_axi_rdata;
 s_axi_rready<=1;
  @(posedge clk);
       
        s_axi_rready <= 0;
        $display("[%0t] READ Address = %h DATA = %h",$time, addr, data);
end
endtask
  
     logic [31:0] read_data;

    initial begin

        //-------------------------
        // Initialize Signals
        //-------------------------
        rst_n = 0;

        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;

        s_axi_wdata   = 0;
        s_axi_wvalid  = 0;

        s_axi_bready  = 0;

        s_axi_araddr  = 0;
        s_axi_arvalid = 0;

        s_axi_rready  = 0;

        //-------------------------
        // Reset
        //-------------------------
        repeat(3) @(posedge clk);

        rst_n = 1;

        repeat(2) @(posedge clk);

        //-------------------------
        // Write Register 0
        //-------------------------
        axi_write(4'h0,32'h12345678);

        //-------------------------
        // Read Register 0
        //-------------------------
        axi_read(4'h0,read_data);

        if(read_data==32'h12345678)
            $display("PASS : REG0");
        else
            $display("FAIL : REG0");

        //-------------------------
        // Write Register 1
        //-------------------------
        axi_write(4'h4,32'hAAAAAAAA);

        axi_read(4'h4,read_data);

        if(read_data==32'hAAAAAAAA)
            $display("PASS : REG1");
        else
            $display("FAIL : REG1");

        //-------------------------
        // Write Register 2
        //-------------------------
        axi_write(4'h8,32'h55555555);

        axi_read(4'h8,read_data);

        if(read_data==32'h55555555)
            $display("PASS : REG2");
        else
            $display("FAIL : REG2");

        //-------------------------
        // Write Register 3
        //-------------------------
        axi_write(4'hC,32'hDEADBEEF);

        axi_read(4'hC,read_data);

        if(read_data==32'hDEADBEEF)
            $display("PASS : REG3");
        else
            $display("FAIL : REG3");

        $display("--------------------------------");
        $display("Simulation Finished");
        $display("--------------------------------");

        #20;
        $finish;

    end

endmodule
