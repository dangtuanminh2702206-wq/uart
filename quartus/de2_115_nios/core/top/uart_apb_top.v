// TX/APB subsystem with a full 9-bit RX event integration interface.
module uart_apb_top #(
    parameter integer RX_FIXED_BAUD_DIV=0
) (
    input wire PCLK, PRESETn, PSEL, PENABLE, PWRITE,
    input wire [7:0] PADDR,
    input wire [31:0] PWDATA,
    output wire [31:0] PRDATA,
    output wire PREADY, PSLVERR,
    input wire cts_n,
    output wire txd, tx_busy, tx_done, irq,
    // Connect these events and configuration ports to the group's RX core.
    input wire [8:0] rx_data,
    input wire rx_valid, frame_err, parity_err,
    output wire rx_en,
    output wire [1:0] data_bit_num,
    output wire stop_bit_num, parity_en, parity_type,
    output wire [15:0] baud_div
);
    wire tx_en,tx_full,tx_empty,rx_full,rx_empty;
    wire tx_push,tx_pop,rx_push,rx_pop;
    wire [8:0] tx_write_data,tx_read_data,rx_write_data,rx_read_data;
    wire [4:0] tx_count,rx_count;
    reg cts_ff1,cts_sync;
    // CTS is an asynchronous physical input. Tie cts_n low when flow control is unused.
    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin cts_ff1<=1'b1;cts_sync<=1'b1;end
        else begin cts_ff1<=cts_n;cts_sync<=cts_ff1;end
    end
    // FIFO head is consumed on the same edge that TX latches the frame.
    wire tx_start=tx_en && !tx_busy && !tx_empty && !cts_sync;
    assign tx_pop=tx_start;
    uart_tx u_tx(.clk(PCLK),.rst_n(PRESETn),.tx_data(tx_read_data),
        .data_bit_num(data_bit_num),.stop_bit_num(stop_bit_num),.parity_en(parity_en),
        .parity_type(parity_type),.baud_div(baud_div),.tx_start(tx_start),.cts_n(cts_sync),
        .tx(txd),.tx_busy(tx_busy),.tx_done(tx_done));
    uart_fifo u_tx_fifo(.clk(PCLK),.rst_n(PRESETn),.push(tx_push),.pop(tx_pop),
        .write_data(tx_write_data),.read_data(tx_read_data),.full(tx_full),.empty(tx_empty),.count(tx_count));
    uart_fifo u_rx_fifo(.clk(PCLK),.rst_n(PRESETn),.push(rx_push),.pop(rx_pop),
        .write_data(rx_write_data),.read_data(rx_read_data),.full(rx_full),.empty(rx_empty),.count(rx_count));
    uart_apb_regs #(.RX_FIXED_BAUD_DIV(RX_FIXED_BAUD_DIV)) u_regs (
        .PCLK(PCLK),.PRESETn(PRESETn),.PSEL(PSEL),.PENABLE(PENABLE),.PWRITE(PWRITE),
        .PADDR(PADDR),.PWDATA(PWDATA),.PRDATA(PRDATA),.PREADY(PREADY),.PSLVERR(PSLVERR),
        .tx_en(tx_en),.rx_en(rx_en),.data_bit_num(data_bit_num),.stop_bit_num(stop_bit_num),
        .parity_en(parity_en),.parity_type(parity_type),.baud_div(baud_div),
        .tx_busy(tx_busy),.tx_done(tx_done),.tx_empty(tx_empty),.tx_full(tx_full),.tx_pop(tx_pop),
        .tx_push(tx_push),.tx_write_data(tx_write_data),.rx_empty(rx_empty),.rx_full(rx_full),
        .rx_read_data(rx_read_data),.rx_data(rx_data),.rx_valid(rx_valid),.frame_err(frame_err),
        .parity_err(parity_err),.rx_push(rx_push),.rx_pop(rx_pop),.rx_write_data(rx_write_data),.irq(irq));
endmodule
