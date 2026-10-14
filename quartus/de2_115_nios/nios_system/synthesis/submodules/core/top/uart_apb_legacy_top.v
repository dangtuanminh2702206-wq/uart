// Pin-level integration with the real RX files under "RTL Uart_RX".
module uart_apb_legacy_top #(
    parameter integer FCLK=50000000,
    parameter integer BAUDRATE=115200
) (
    input wire PCLK,PRESETn,PSEL,PENABLE,PWRITE,
    input wire [7:0] PADDR,
    input wire [31:0] PWDATA,
    output wire [31:0] PRDATA,
    output wire PREADY,PSLVERR,
    input wire rxd,cts_n,
    output wire txd,tx_busy,tx_done,irq
);
    localparam integer FIXED_DIV=(BAUDRATE>0) ? FCLK/BAUDRATE : 0;
    wire [8:0] rx_data;
    wire rx_valid,frame_err,parity_err,rx_en;
    wire [1:0] data_bit_num;
    wire stop_bit_num,parity_en,parity_type;
    wire [15:0] baud_div;
    uart_apb_top #(.RX_FIXED_BAUD_DIV(FIXED_DIV)) u_core (
        .PCLK(PCLK),.PRESETn(PRESETn),.PSEL(PSEL),.PENABLE(PENABLE),.PWRITE(PWRITE),
        .PADDR(PADDR),.PWDATA(PWDATA),.PRDATA(PRDATA),.PREADY(PREADY),.PSLVERR(PSLVERR),
        .cts_n(cts_n),.txd(txd),.tx_busy(tx_busy),.tx_done(tx_done),.irq(irq),
        .rx_data(rx_data),.rx_valid(rx_valid),.frame_err(frame_err),.parity_err(parity_err),
        .rx_en(rx_en),.data_bit_num(data_bit_num),.stop_bit_num(stop_bit_num),
        .parity_en(parity_en),.parity_type(parity_type),.baud_div(baud_div));
    uart_rx_legacy_adapter #(.FCLK(FCLK),.BAUDRATE(BAUDRATE)) u_rx_adapter (
        .clk(PCLK),.rst_n(PRESETn),.rx(rxd),.rx_en(rx_en),.data_bit_num(data_bit_num),
        .stop_bit_num(stop_bit_num),.parity_en(parity_en),.parity_type(parity_type),
        .rx_data(rx_data),.rx_valid(rx_valid),.frame_err(frame_err),.parity_err(parity_err));
    // synthesis translate_off
    initial begin
        if(FIXED_DIV<16 || FIXED_DIV>65535)
            $fatal(1,"Legacy top requires a baud divider in 16..65535");
    end
    // synthesis translate_on
endmodule
