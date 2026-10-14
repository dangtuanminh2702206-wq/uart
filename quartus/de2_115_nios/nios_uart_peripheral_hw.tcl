package require -exact qsys 16.1
set_module_property NAME nios_uart_peripheral
set_module_property VERSION 1.0
set_module_property GROUP "UART-APB Local"
set_module_property DISPLAY_NAME "Local UART APB + LCD"
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL nios_uart_peripheral
add_fileset_file rtl/nios_uart_peripheral.v VERILOG PATH rtl/nios_uart_peripheral.v
add_fileset_file core/apb/uart_apb_regs.v VERILOG PATH core/apb/uart_apb_regs.v
add_fileset_file core/board/lcd_rx_display.v VERILOG PATH core/board/lcd_rx_display.v
add_fileset_file core/common/uart_fifo.v VERILOG PATH core/common/uart_fifo.v
add_fileset_file core/rx/uart_rx.v VERILOG PATH core/rx/uart_rx.v
add_fileset_file core/rx/uart_rx_controller.v VERILOG PATH core/rx/uart_rx_controller.v
add_fileset_file core/rx/uart_rx_datapath.v VERILOG PATH core/rx/uart_rx_datapath.v
add_fileset_file core/rx/uart_rx_legacy_adapter.v VERILOG PATH core/rx/uart_rx_legacy_adapter.v
add_fileset_file core/top/uart_apb_legacy_top.v VERILOG PATH core/top/uart_apb_legacy_top.v
add_fileset_file core/top/uart_apb_top.v VERILOG PATH core/top/uart_apb_top.v
add_fileset_file core/tx/uart_tx.v VERILOG PATH core/tx/uart_tx.v
add_interface clock clock sink
add_interface_port clock clk clk Input 1
add_interface reset reset sink
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset rst_n reset_n Input 1
add_interface s0 avalon end
set_interface_property s0 associatedClock clock
set_interface_property s0 associatedReset reset
set_interface_property s0 addressUnits SYMBOLS
set_interface_property s0 bitsPerSymbol 8
set_interface_property s0 readLatency 0
set_interface_property s0 maximumPendingReadTransactions 0

add_interface_port s0 address address Input 8
add_interface_port s0 read read Input 1
add_interface_port s0 write write Input 1
add_interface_port s0 writedata writedata Input 32
add_interface_port s0 byteenable byteenable Input 4
add_interface_port s0 readdata readdata Output 32
add_interface_port s0 waitrequest waitrequest Output 1
add_interface board conduit end
add_interface_port board rxd rxd Input 1
add_interface_port board jtag_mode jtag_mode Input 1
add_interface_port board txd txd Output 1
add_interface_port board leds leds Output 4
add_interface_port board LCD_DATA LCD_DATA Output 8
add_interface_port board LCD_EN LCD_EN Output 1
add_interface_port board LCD_RW LCD_RW Output 1
add_interface_port board LCD_RS LCD_RS Output 1
add_interface_port board LCD_ON LCD_ON Output 1
