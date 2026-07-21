`timescale 1ns / 1ps
module axi_lite_master #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,
    //write address pins
    output logic [ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic                  m_axi_awvalid,
    input  logic                  m_axi_awready,
    //write data pins
    output logic [DATA_WIDTH-1:0] m_axi_wdata,
    output logic                  m_axi_wvalid,
    input  logic                  m_axi_wready,
    // response pins
    input  logic [1:0]            m_axi_bresp,
    input  logic                  m_axi_bvalid,
    output logic                  m_axi_bready,
    //read address pins
    output logic [ADDR_WIDTH-1:0] m_axi_araddr,
    output logic                  m_axi_arvalid,
    input  logic                  m_axi_arready,
    //read pins
    input  logic [DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [1:0]            m_axi_rresp,
    input  logic                  m_axi_rvalid,
    output logic                  m_axi_rready,
    
    input  logic [DATA_WIDTH-1:0] data,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic                  start,
    output logic                  done,
    output logic                  error,
    input logic write_en,
input logic read_en,
output logic [DATA_WIDTH-1:0] rdata_out
);
// fsm states
    typedef enum logic [2:0] {
        IDLE,
        SEND_ADDR,
        SEND_DATA,
        WAIT_RESP,
        SEND_RADDR,
        WAIT_RDATA
    } state_t;

    state_t state, next_state;

    // Latched address/data - captured once, held stable for the whole txn
    //started defining the initial parameters, reset condition etc
    logic [ADDR_WIDTH-1:0] addr_reg;
    logic [DATA_WIDTH-1:0] data_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= '0;
            data_reg <= '0;
        end else if (state == IDLE && start && write_en) begin
            addr_reg <= addr;
            data_reg <= data;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else         state <= next_state;
    end
//above were the initial conditions
//started defining the machine mechanism 
     logic [ADDR_WIDTH-1:0] raddr_reg;
       //read logic initial parameters
   always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        raddr_reg <= '0;
        rdata_out <= '0;
    end else if (state == IDLE && start && read_en) begin
        raddr_reg <= addr;
    end else if (state == WAIT_RDATA && m_axi_rvalid) begin
        rdata_out <= m_axi_rdata;
    end
end

   

    always_comb 
    begin
        next_state = state;
        case (state)
            IDLE:
    if (start && write_en)
        next_state = SEND_ADDR;
    else if (start && read_en)
        next_state = SEND_RADDR;
            SEND_ADDR: if (m_axi_awready)    next_state = SEND_DATA;
            SEND_DATA: if (m_axi_wready)     next_state = WAIT_RESP;
            WAIT_RESP: if (m_axi_bvalid)     next_state = IDLE;
            SEND_RADDR: if(m_axi_arready) next_state=WAIT_RDATA;
             WAIT_RDATA: if(m_axi_rvalid) next_state=IDLE;
            default:   next_state = IDLE;
        endcase
    end
//above was the basic functioning of an fsm. defininf next state etc etc
//next we define what to do when we in a current state
    always_comb begin
        m_axi_awvalid = 1'b0;
        m_axi_wvalid  = 1'b0;
        m_axi_bready  = 1'b0;
        m_axi_awaddr  = addr_reg;
        m_axi_wdata   = data_reg;
        done          = 1'b0;
        error         = 1'b0;
        m_axi_arvalid=1'b0;
m_axi_rready=1'b0;
m_axi_araddr = raddr_reg;

//we make this logic combinational to save a clock delay, and there is no need to 'store prev value'
        case (state)
            SEND_ADDR: m_axi_awvalid = 1'b1;
            SEND_DATA: m_axi_wvalid  = 1'b1;
            WAIT_RESP: begin
                m_axi_bready = 1'b1;
                if (m_axi_bvalid) begin
                    done  = 1'b1;
                    error = (m_axi_bresp != 2'b00); // non-OKAY response
                end
            end
            SEND_RADDR: m_axi_arvalid = 1'b1;
            WAIT_RDATA: begin
                m_axi_rready = 1'b1;
                if (m_axi_rvalid) begin
                    done  = 1'b1;
                    error = (m_axi_rresp != 2'b00);
                end
            end
            default: ; // IDLE
        endcase
    end
    //above we define the next state logic
endmodule