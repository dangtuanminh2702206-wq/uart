create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty
# UART and the push button are asynchronous to CLOCK_50. Only their entry
# paths are exempted; the synchronizer stages and all core/APB paths are timed.
set_false_path -from [get_ports {UART_RXD}]
set_false_path -from [get_ports {KEY0 SW0}]
# RS-232 output and LEDs are not sampled by a synchronous external device.
set_false_path -to [get_ports {UART_TXD LEDG[*] LCD_DATA[*] LCD_EN LCD_RS LCD_RW LCD_ON}]
