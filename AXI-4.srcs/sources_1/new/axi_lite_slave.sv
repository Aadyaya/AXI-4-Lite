`timescale 1ns / 1ps
module axi_lite_slave #(
parameter int DATA_WIDTH=32,
parameter int ADDR_WIDTH=4)(
input logic clk,
input logic rst_n,
input logic [ADDR_WIDTH-1:0] s_axi_awaddr,
input logic s_axi_awvalid,
output logic s_axi_awready,
input logic [DATA_WIDTH-1:0] s_axi_wdata,
input logic s_axi_wvalid,
output logic s_axi_wready,
output logic [1:0]            s_axi_bresp,
  output logic                  s_axi_bvalid,
    input  logic                  s_axi_bready,
input logic [ADDR_WIDTH-1:0] s_axi_araddr,
input logic s_axi_arvalid,
output logic s_axi_arready,
output logic [DATA_WIDTH-1:0] s_axi_rdata,
    output logic [1:0]            s_axi_rresp,
    output logic                  s_axi_rvalid,
    input  logic                  s_axi_rready
    );
logic aw_done;
logic w_done;
logic [31:0] reg0, reg1, reg2, reg3;
logic [ADDR_WIDTH-1:0] waddr_reg;
logic [ADDR_WIDTH-1:0] araddr_reg;
logic [DATA_WIDTH-1:0] wdata_reg;
assign s_axi_awready = !s_axi_bvalid;
assign s_axi_wready  = !s_axi_bvalid;
assign s_axi_arready = !s_axi_rvalid;//check their values for initialization

always_ff @(posedge clk or negedge rst_n) begin
if(!rst_n)begin
aw_done<=0;
w_done<=0;
s_axi_bvalid<=0;
s_axi_bresp <= 2'b00;
waddr_reg<=0;
wdata_reg<=0;
araddr_reg<=0;
s_axi_rdata<=0;
reg0<=0;
reg1<=0;
reg2<=0;
reg3<=0;
s_axi_rvalid <= 0;
s_axi_rresp  <= 2'b00;
end
else begin
if(s_axi_awvalid && s_axi_awready) begin
waddr_reg<=s_axi_awaddr;
aw_done<=1;
end
if(s_axi_wvalid && s_axi_wready) begin
wdata_reg<= s_axi_wdata;
w_done<=1;
end
if(w_done && aw_done)begin
case(waddr_reg) 
4'h0:reg0<=wdata_reg;
4'h4:reg1<=wdata_reg;
4'h8:reg2<=wdata_reg;
4'hC:reg3<=wdata_reg;
default : ;
endcase
s_axi_bvalid<=1;
s_axi_bresp<=2'b00;//okay to send state
end
if (s_axi_bvalid && s_axi_bready) begin
    s_axi_bvalid <= 0;
    aw_done      <= 0;
    w_done       <= 0;

    waddr_reg    <= 0;
    wdata_reg    <= 0;
end
if(s_axi_arready && s_axi_arvalid) begin
araddr_reg<=s_axi_araddr;
case(s_axi_araddr) 
4'h0: s_axi_rdata<=reg0;
4'h4: s_axi_rdata<=reg1;
4'h8: s_axi_rdata<=reg2;
4'hc: s_axi_rdata<=reg3;
default:s_axi_rdata <= 32'h0;
endcase
s_axi_rresp  <= 2'b00;
s_axi_rvalid<=1;//where to place this thing
end
if(s_axi_rvalid && s_axi_rready)
begin//some more content here
    s_axi_rvalid <= 0;
end
end
end
endmodule
