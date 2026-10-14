// Compatibility wrapper for the existing 9-bit FIFO/event subsystem.
// The submitted uart_rx interface remains 8-bit + sticky done + acknowledge.
module uart_rx_legacy_adapter #(
    parameter integer FCLK=50000000,
    parameter integer BAUDRATE=115200
) (
    input wire clk,rst_n,rx,rx_en,
    input wire [1:0] data_bit_num,
    input wire stop_bit_num,parity_en,parity_type,
    output wire [8:0] rx_data,
    output wire rx_valid,frame_err,parity_err
);
    wire [1:0] legacy_bits=(data_bit_num==2'b00) ? 2'b10 : 2'b11;
    wire receiver_reset_n=rst_n && rx_en;
    wire rx_s,tick16,os_mid,os_last,bit_last;
    wire os_clear,os_inc,bit_clear,bit_inc,frame_clear;
    wire sample_en,parity_check,stop_check,latch_en;
    wire [7:0] payload;
    wire pending,parity_status,stop_error_event;

    uart_rx_controller u_controller (
        .clk(clk),.rst_n(receiver_reset_n),.rx_s(rx_s),.tick16(tick16),
        .os_mid(os_mid),.os_last(os_last),.bit_last(bit_last),
        .parity_en(parity_en),.stop_bit_num(stop_bit_num),
        .os_clear(os_clear),.os_inc(os_inc),.bit_clear(bit_clear),.bit_inc(bit_inc),
        .frame_clear(frame_clear),.sample_en(sample_en),.parity_check(parity_check),
        .stop_check(stop_check),.latch_en(latch_en)
    );
    uart_rx_datapath #(.FCLK(FCLK),.BAUDRATE(BAUDRATE)) u_datapath (
        .clk(clk),.rst_n(receiver_reset_n),.rx(rx),.clear_rx_done(pending),
        .data_bit_num(legacy_bits),.parity_type(!parity_type),
        .os_clear(os_clear),.os_inc(os_inc),.bit_clear(bit_clear),.bit_inc(bit_inc),
        .frame_clear(frame_clear),.sample_en(sample_en),.parity_check(parity_check),
        .stop_check(stop_check),.latch_en(latch_en),
        .rx_s(rx_s),.tick16(tick16),.os_mid(os_mid),.os_last(os_last),.bit_last(bit_last),
        .rx_data(payload),.rx_done(pending),.parity_error(parity_status),
        .frame_error_event(stop_error_event)
    );
    // Automatic acknowledgement makes pending a one-clock integration event.
    assign rx_data={1'b0,payload};
    assign rx_valid=rx_en && pending && !parity_status;
    assign parity_err=rx_en && pending && parity_status;
    assign frame_err=rx_en && stop_error_event;
endmodule