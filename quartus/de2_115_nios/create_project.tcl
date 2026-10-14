load_package project
project_new de2_115_nios -overwrite
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY de2_115_nios_top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS 2
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
set_global_assignment -name VERILOG_FILE rtl/de2_115_nios_top.v
set_global_assignment -name QIP_FILE nios_system/synthesis/nios_system.qip
set_global_assignment -name SDC_FILE de2_115_nios.sdc
foreach {node pin standard} {CLOCK_50 Y2 {3.3-V LVTTL} SW0 AB28 {2.5 V} KEY0 M23 {2.5 V} UART_RXD G12 {3.3-V LVTTL} UART_TXD G9 {3.3-V LVTTL} {LEDG[0]} E21 {2.5 V} {LEDG[1]} E22 {2.5 V} {LEDG[2]} E25 {2.5 V} {LEDG[3]} E24 {2.5 V} LCD_EN L4 {3.3-V LVTTL} LCD_RW M1 {3.3-V LVTTL} LCD_RS M2 {3.3-V LVTTL} LCD_ON L5 {3.3-V LVTTL} {LCD_DATA[0]} L3 {3.3-V LVTTL} {LCD_DATA[1]} L1 {3.3-V LVTTL} {LCD_DATA[2]} L2 {3.3-V LVTTL} {LCD_DATA[3]} K7 {3.3-V LVTTL} {LCD_DATA[4]} K1 {3.3-V LVTTL} {LCD_DATA[5]} K2 {3.3-V LVTTL} {LCD_DATA[6]} M3 {3.3-V LVTTL} {LCD_DATA[7]} M5 {3.3-V LVTTL}} {
 set_location_assignment PIN_$pin -to $node
 set_instance_assignment -name IO_STANDARD $standard -to $node
 puts "$node=$pin,$standard"
}
foreach node {UART_TXD {LEDG[0]} {LEDG[1]} {LEDG[2]} {LEDG[3]}} {
 set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to $node
 # Device defaults for slew rate; unsupported on 3.3-V LVTTL.
}
export_assignments
project_close
