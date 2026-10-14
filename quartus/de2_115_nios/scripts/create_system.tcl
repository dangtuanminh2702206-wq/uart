package require -exact qsys 16.1
create_system nios_system
set_project_property DEVICE_FAMILY "Cyclone IV E"
set_project_property DEVICE EP4CE115F29C7
add_instance clk altera_clock_bridge
set_instance_parameter_value clk EXPLICIT_CLOCK_RATE 50000000
add_instance reset altera_reset_bridge
set_instance_parameter_value reset ACTIVE_LOW_RESET 1
set_instance_parameter_value reset SYNCHRONOUS_EDGES deassert
add_instance cpu intel_niosv_c
set_instance_parameter_value cpu enableAvalonInterface true
set_instance_parameter_value cpu resetSlave Absolute
set_instance_parameter_value cpu resetOffset 0
add_instance mem altera_avalon_onchip_memory2
set_instance_parameter_value mem memorySize 65536
set_instance_parameter_value mem dataWidth 32
set_instance_parameter_value mem initMemContent true
set_instance_parameter_value mem initializationFileName firmware.mif
add_instance juart altera_avalon_jtag_uart
set_instance_parameter_value juart readBufferDepth 512
set_instance_parameter_value juart writeBufferDepth 512
add_instance uart nios_uart_peripheral 1.0
foreach item {reset.clk cpu.clk mem.clk1 juart.clk uart.clock} {add_connection clk.out_clk $item}
foreach item {cpu.reset mem.reset1 juart.reset uart.reset} {add_connection reset.out_reset $item}
add_connection cpu.instruction_manager mem.s1
add_connection cpu.data_manager mem.s1
add_connection cpu.data_manager juart.avalon_jtag_slave
add_connection cpu.data_manager uart.s0
set_connection_parameter_value cpu.instruction_manager/mem.s1 baseAddress 0
set_connection_parameter_value cpu.data_manager/mem.s1 baseAddress 0
set_connection_parameter_value cpu.data_manager/uart.s0 baseAddress 0x10000
set_connection_parameter_value cpu.data_manager/juart.avalon_jtag_slave baseAddress 0x11000
set_interface_property clock EXPORT_OF clk.in_clk
set_interface_property reset EXPORT_OF reset.in_reset
set_interface_property board EXPORT_OF uart.board
save_system nios_system.qsys
