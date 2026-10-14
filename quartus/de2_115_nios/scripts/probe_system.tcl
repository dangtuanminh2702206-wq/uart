package require -exact qsys 16.1
create_system nios_system
set_project_property DEVICE_FAMILY "Cyclone IV E"
set_project_property DEVICE EP4CE115F29C7
add_instance cpu intel_niosv_c
set_instance_parameter_value cpu enableAvalonInterface true
set_instance_parameter_value cpu resetSlave Absolute
set_instance_parameter_value cpu resetOffset 0
add_instance mem altera_avalon_onchip_memory2
add_instance juart altera_avalon_jtag_uart
foreach inst {cpu mem juart} {
 puts "PARAMETERS $inst: [get_instance_parameters $inst]"
 foreach name [get_instance_parameters $inst] { puts "$inst.$name=[get_instance_parameter_value $inst $name]" }
 puts "INTERFACES $inst: [get_instance_interfaces $inst]"
}
save_system nios_system.qsys
