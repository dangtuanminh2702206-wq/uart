// Avalon-MM CPU accesses -> APB3 SETUP/ACCESS -> unchanged local UART.
module nios_uart_peripheral (
 input wire clk,rst_n,
 input wire [7:0] address,
 input wire read,write,
 input wire [31:0] writedata,
 input wire [3:0] byteenable,
 output reg [31:0] readdata,
 output wire waitrequest,
 input wire rxd,jtag_mode,
 output wire txd,
 output wire [3:0] leds,
 output wire [7:0] LCD_DATA,
 output wire LCD_EN,LCD_RW,LCD_RS,LCD_ON
);
 localparam IDLE=0,SETUP=1,ACCESS=2,RESPONSE=3;
 reg [1:0] state;
 reg [7:0] held_addr;
 reg held_write;
 reg [31:0] held_data;
 reg [15:0] timeout_count;
 reg bridge_error,display_valid;
 reg [7:0] display_data;
 reg [1:0] sw_led;
 wire [31:0] prdata;
 wire pready,pslverr,tx_busy,tx_done,irq;
 wire psel=(state==SETUP || state==ACCESS);
 wire penable=(state==ACCESS);
 assign waitrequest=(state!=RESPONSE);
 assign leds={tx_busy,jtag_mode,sw_led[1]|bridge_error,sw_led[0]};
 uart_apb_legacy_top u_uart(.PCLK(clk),.PRESETn(rst_n),.PSEL(psel),.PENABLE(penable),
  .PWRITE(held_write),.PADDR(held_addr),.PWDATA(held_data),.PRDATA(prdata),
  .PREADY(pready),.PSLVERR(pslverr),.rxd(jtag_mode?txd:rxd),.cts_n(1'b0),
  .txd(txd),.tx_busy(tx_busy),.tx_done(tx_done),.irq(irq));
 lcd_rx_display u_lcd(.clk(clk),.rst_n(rst_n),.byte_valid(display_valid),.byte_data(display_data),
  .LCD_DATA(LCD_DATA),.LCD_EN(LCD_EN),.LCD_RW(LCD_RW),.LCD_RS(LCD_RS),.LCD_ON(LCD_ON));
 always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
   state<=IDLE;readdata<=0;held_addr<=0;held_data<=0;held_write<=0;
   timeout_count<=0;bridge_error<=0;display_valid<=0;display_data<=0;sw_led<=0;
  end else begin
   display_valid<=0;
   case(state)
    IDLE: if(read || write) begin
     held_addr<=address;held_write<=write;held_data<=writedata;timeout_count<=0;
     if(address[1:0]!=0 || byteenable!=4'b1111 || (read && write)) begin
      bridge_error<=1;readdata<=0;state<=RESPONSE;
     end else if(address<=8'h18) state<=SETUP;
     else begin
      state<=RESPONSE;readdata<=0;
      case(address)
       8'h20: if(write) begin display_data<=writedata[7:0];display_valid<=1;end
              else readdata<={24'd0,display_data};
       8'h24: if(write) sw_led<=writedata[1:0];
              else readdata<={23'd0,jtag_mode,6'd0,sw_led};
       8'h28: if(write) begin if(writedata[0]) bridge_error<=0;end
              else readdata<={31'd0,bridge_error};
       default: bridge_error<=1;
      endcase
     end
    end
    SETUP: state<=ACCESS;
    ACCESS: if(pready) begin
     readdata<=prdata;if(pslverr) bridge_error<=1;state<=RESPONSE;
    end else if(&timeout_count) begin bridge_error<=1;readdata<=0;state<=RESPONSE;end
    else timeout_count<=timeout_count+1'b1;
    RESPONSE: state<=IDLE;
    default: state<=IDLE;
   endcase
  end
 end
endmodule
