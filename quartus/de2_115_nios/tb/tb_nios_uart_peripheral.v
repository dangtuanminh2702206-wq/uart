`timescale 1ns/1ps
module tb_nios_uart_peripheral;
 reg clk=0;always #10 clk=~clk;
 reg rst_n=0,read=0,write=0,rxd=1,jtag_mode=1;
 reg [7:0] address=0;reg [31:0] writedata=0;reg [3:0] byteenable=15;
 wire [31:0] readdata;wire waitrequest,txd;wire [3:0] leds;
 wire [7:0] LCD_DATA;wire LCD_EN,LCD_RS,LCD_RW,LCD_ON;
 integer i,pushes=0,pops=0,displays=0,cycles;
 reg [31:0] d;
 nios_uart_peripheral dut(.clk(clk),.rst_n(rst_n),.address(address),.read(read),.write(write),
 .writedata(writedata),.byteenable(byteenable),.readdata(readdata),.waitrequest(waitrequest),
 .rxd(rxd),.jtag_mode(jtag_mode),.txd(txd),.leds(leds),.LCD_DATA(LCD_DATA),
 .LCD_EN(LCD_EN),.LCD_RS(LCD_RS),.LCD_RW(LCD_RW),.LCD_ON(LCD_ON));
 always @(posedge clk) if(rst_n) begin
  if(dut.u_uart.u_core.tx_push)pushes=pushes+1;
  if(dut.u_uart.u_core.rx_pop)pops=pops+1;
  if(dut.display_valid)displays=displays+1;
 end
 task transfer;
 input wr;input [7:0] a;input [31:0] value;output [31:0] result;
 begin
  @(negedge clk);address=a;writedata=value;write=wr;read=!wr;cycles=0;
  while(waitrequest)begin @(negedge clk);cycles=cycles+1;if(cycles>100)$fatal(1,"Avalon timeout");end
  result=readdata;@(negedge clk);write=0;read=0;
 end endtask
 initial begin
  repeat(4)@(negedge clk);rst_n=1;
  transfer(1,0,0,d);transfer(1,4,434,d);transfer(1,24,31,d);transfer(1,0,35,d);
  transfer(0,36,0,d);if(d!==256)$fatal(1,"Mode readback");
  byteenable=1;transfer(1,0,0,d);byteenable=15;
  transfer(0,0,0,d);if(d!==35)$fatal(1,"Partial write side effect");
  transfer(0,40,0,d);if(d!==1)$fatal(1,"Bridge error flag");transfer(1,40,1,d);
  for(i=0;i<256;i=i+1)begin
   transfer(1,12,i,d);
   d=0;while(!(d&4))transfer(0,8,0,d);
   transfer(0,16,0,d);if(d[7:0]!==i[7:0])$fatal(1,"Serial loopback mismatch %d",i);
   transfer(1,32,d,d);
  end
  transfer(0,40,0,d);if(d!==0)$fatal(1,"Unexpected bridge error");
  if(pushes!=256 || pops!=256 || displays!=256)$fatal(1,"Duplicate/lost bus side effects");
  transfer(0,12,0,d);transfer(0,40,0,d);if(d!==1)$fatal(1,"APB PSLVERR propagation");
  transfer(1,40,1,d);transfer(1,36,1,d);
  if(leds[0]!==1 || leds[1]!==0)$fatal(1,"Ready/error LED");
  @(negedge clk);rst_n=0;repeat(2)@(negedge clk);
  if(txd!==1 || leds[0]!==0)$fatal(1,"Reset");
  $display("PASS Nios peripheral: 256 serial loopback bytes through Avalon/APB, exact FIFO/LCD side effects, partial-write rejection, bus errors, mode, LED, reset");$finish;
 end
 initial begin #30000000;$fatal(1,"Global timeout");end
endmodule
