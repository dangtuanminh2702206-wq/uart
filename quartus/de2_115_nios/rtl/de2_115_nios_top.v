module de2_115_nios_top (
 input wire CLOCK_50,KEY0,SW0,UART_RXD,
 output wire UART_TXD,
 output wire [3:0] LEDG,
 output wire [7:0] LCD_DATA,
 output wire LCD_EN,LCD_RW,LCD_RS,LCD_ON
);
 reg [7:0] power_on_count=0;
 reg [1:0] sw_sync=0;
 reg jtag_mode=0;
 (* altera_attribute="-name SYNCHRONIZER_IDENTIFICATION FORCED" *)
 reg [1:0] reset_sync=0;
 wire request_n=KEY0 && (&power_on_count);
 always @(posedge CLOCK_50 or negedge KEY0) begin
  if(!KEY0) begin power_on_count<=0;sw_sync<=0;jtag_mode<=0;end
  else begin
   sw_sync<={sw_sync[0],SW0};
   if(!(&power_on_count)) power_on_count<=power_on_count+1'b1;
   if(power_on_count==8'hfe) jtag_mode<=sw_sync[1];
  end
 end
 always @(posedge CLOCK_50 or negedge request_n) begin
  if(!request_n)reset_sync<=0;else reset_sync<={reset_sync[0],1'b1};
 end
 nios_system u_system(.clock_clk(CLOCK_50),.reset_reset_n(reset_sync[1]),
  .board_rxd(UART_RXD),.board_jtag_mode(jtag_mode),.board_txd(UART_TXD),.board_leds(LEDG),
  .board_LCD_DATA(LCD_DATA),.board_LCD_EN(LCD_EN),.board_LCD_RW(LCD_RW),
  .board_LCD_RS(LCD_RS),.board_LCD_ON(LCD_ON));
endmodule
