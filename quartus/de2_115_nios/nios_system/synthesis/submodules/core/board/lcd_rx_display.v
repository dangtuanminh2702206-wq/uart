// Write-only HD44780 16x2 display. UART events update a separate text buffer;
// LCD refresh never stalls the APB master or UART.
module lcd_rx_display #(
    parameter integer FCLK=50000000
) (
    input wire clk, rst_n, byte_valid,
    input wire [7:0] byte_data,
    output reg [7:0] LCD_DATA,
    output reg LCD_EN, LCD_RS,
    output wire LCD_RW, LCD_ON
);
    localparam integer US=FCLK/1000000;
    localparam [2:0] WAIT_POWER=0, LOAD=1, SETUP=2, HIGH=3, HOLD=4, WAIT_EXEC=5;
    reg [7:0] text [0:31];
    reg [5:0] cursor;
    reg [2:0] state;
    reg [3:0] init_step;
    reg [5:0] refresh_step;
    reg [31:0] timer, delay_cycles;
    integer i;
    assign LCD_RW=1'b0;
    assign LCD_ON=1'b1;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cursor<=0;
            for(i=0;i<32;i=i+1) text[i]<=8'h20;
        end else if(byte_valid) begin
            if(byte_data==8'h0d) cursor<=(cursor<16)?6'd0:6'd16;
            else if(byte_data==8'h0a) begin
                if(cursor<16) cursor<=16;
                else begin
                    for(i=0;i<16;i=i+1) begin text[i]<=text[i+16];text[i+16]<=8'h20;end
                    cursor<=16;
                end
            end else if(byte_data>=8'h20 && byte_data<=8'h7e) begin
                if(cursor==32) begin
                    for(i=0;i<16;i=i+1) text[i]<=text[i+16];
                    text[16]<=byte_data;
                    for(i=17;i<32;i=i+1) text[i]<=8'h20;
                    cursor<=17;
                end else begin text[cursor]<=byte_data;cursor<=cursor+1'b1;end
            end
            // Other control/binary bytes are echoed but not printed.
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state<=WAIT_POWER;timer<=50*1000*US-1;
            init_step<=0;refresh_step<=0;delay_cycles<=0;
            LCD_EN<=0;LCD_RS<=0;LCD_DATA<=0;
        end else case(state)
            WAIT_POWER: if(timer!=0) timer<=timer-1'b1;else state<=LOAD;
            LOAD: begin
                LCD_EN<=0;LCD_RS<=0;delay_cycles<=50*US;
                if(init_step<8) begin
                    case(init_step)
                        0: begin LCD_DATA<=8'h30;delay_cycles<=5000*US;end
                        1,2: begin LCD_DATA<=8'h30;delay_cycles<=200*US;end
                        3: LCD_DATA<=8'h38;
                        4: LCD_DATA<=8'h08;
                        5: begin LCD_DATA<=8'h01;delay_cycles<=2000*US;end
                        6: LCD_DATA<=8'h06;
                        7: LCD_DATA<=8'h0c;
                        default: LCD_DATA<=8'h38;
                    endcase
                end else if(refresh_step==0) LCD_DATA<=8'h80;
                else if(refresh_step==17) LCD_DATA<=8'hc0;
                else begin
                    LCD_RS<=1;
                    if(refresh_step<17) LCD_DATA<=text[refresh_step-1];
                    else LCD_DATA<=text[refresh_step-2];
                end
                timer<=US-1;state<=SETUP;
            end
            SETUP: if(timer!=0) timer<=timer-1'b1;
                   else begin LCD_EN<=1;timer<=US-1;state<=HIGH;end
            HIGH: if(timer!=0) timer<=timer-1'b1;
                  else begin LCD_EN<=0;timer<=US-1;state<=HOLD;end
            HOLD: if(timer!=0) timer<=timer-1'b1;
                  else begin timer<=delay_cycles-1;state<=WAIT_EXEC;end
            WAIT_EXEC: if(timer!=0) timer<=timer-1'b1;
                       else begin
                           if(init_step<8) init_step<=init_step+1'b1;
                           else if(refresh_step==33) refresh_step<=0;
                           else refresh_step<=refresh_step+1'b1;
                           state<=LOAD;
                       end
            default: begin state<=WAIT_POWER;timer<=50*1000*US-1;LCD_EN<=0;end
        endcase
    end
endmodule
