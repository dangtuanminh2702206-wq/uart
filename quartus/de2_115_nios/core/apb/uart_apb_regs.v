module uart_apb_regs #(
    // Zero: external RX with the new interface. Nonzero: legacy RX baud restriction.
    parameter integer RX_FIXED_BAUD_DIV=0
) (
    input wire PCLK, PRESETn, PSEL, PENABLE, PWRITE,
    input wire [7:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADY,
    output wire PSLVERR,
    output wire tx_en, rx_en,
    output wire [1:0] data_bit_num,
    output wire stop_bit_num, parity_en, parity_type,
    output wire [15:0] baud_div,
    input wire tx_busy, tx_done, tx_empty, tx_full, tx_pop,
    output wire tx_push,
    output wire [8:0] tx_write_data,
    input wire rx_empty, rx_full,
    input wire [8:0] rx_read_data, rx_data,
    input wire rx_valid, frame_err, parity_err,
    output wire rx_push, rx_pop,
    output wire [8:0] rx_write_data,
    output wire irq
);
    localparam [7:0] CTRL=8'h00, BAUDDIV=8'h04, STATUS=8'h08,
                     TXDATA=8'h0c, RXDATA=8'h10, IRQEN=8'h14, IRQSTAT=8'h18;
    localparam [31:0] CTRL_MASK=32'h0000007f, IRQ_MASK=32'h0000001f;
    reg [6:0] ctrl_reg;
    reg [15:0] baud_reg;
    reg [4:0] irq_enable, irq_pending;
    reg access_done;
    reg access_error;
    wire access = PSEL && PENABLE;
    wire transfer = access && PREADY && !access_done;
    wire write_ok = transfer && PWRITE && !access_error;
    wire read_ok = transfer && !PWRITE && !access_error;
    wire overrun = rx_en && rx_valid && rx_full && !rx_pop;
    wire [4:0] hardware_set = {overrun, rx_en && parity_err,
        rx_en && frame_err, rx_push, tx_done};
    wire [4:0] software_clear = (write_ok && PADDR==IRQSTAT) ? PWDATA[4:0] : 5'd0;

    assign tx_en=ctrl_reg[0];
    assign rx_en=ctrl_reg[1];
    assign parity_en=ctrl_reg[3];
    assign parity_type=ctrl_reg[2];
    assign stop_bit_num=ctrl_reg[4];
    assign data_bit_num=ctrl_reg[6:5];
    assign baud_div=baud_reg;
    assign PREADY=1'b1;
    assign PSLVERR=access && access_error;
    assign tx_push=write_ok && (PADDR==TXDATA);
    assign tx_write_data=PWDATA[8:0];
    assign rx_pop=read_ok && (PADDR==RXDATA) && !rx_empty;
    assign rx_push=rx_en && rx_valid && (!rx_full || rx_pop);
    assign rx_write_data=rx_data;
    assign irq=|(irq_enable & irq_pending);

    // Decode permissions and reject unsupported encodings without changing registers.
    always @(*) begin
        access_error=1'b0;
        case(PADDR)
            CTRL: if(PWRITE) begin
                if(PWDATA[3:2]==2'b01 || PWDATA[6:5]==2'b11)
                    access_error=1'b1;
                if(RX_FIXED_BAUD_DIV!=0 && PWDATA[1] &&
                    (PWDATA[6:5]==2'b10 || baud_reg!=RX_FIXED_BAUD_DIV))
                    access_error=1'b1;
            end
            BAUDDIV: if(PWRITE) begin
                if(PWDATA[15:0]==0) access_error=1'b1;
                if(RX_FIXED_BAUD_DIV!=0 && rx_en && PWDATA[15:0]!=RX_FIXED_BAUD_DIV)
                    access_error=1'b1;
            end
            STATUS, RXDATA: access_error=PWRITE;
            TXDATA: access_error=!PWRITE || (tx_full && !tx_pop);
            IRQEN, IRQSTAT: begin end
            default: access_error=1'b1;
        endcase
    end

    always @(*) begin
        PRDATA=32'd0;
        if(PSEL && !PWRITE && !access_error) begin
            case(PADDR)
                CTRL: PRDATA={25'd0,ctrl_reg};
                BAUDDIV: PRDATA={16'd0,baud_reg};
                STATUS: PRDATA={25'd0,irq_pending[4:2],rx_full,!rx_empty,tx_empty,tx_busy};
                RXDATA: PRDATA={23'd0,rx_read_data};
                IRQEN: PRDATA={27'd0,irq_enable};
                IRQSTAT: PRDATA={27'd0,irq_pending};
                default: PRDATA=32'd0;
            endcase
        end
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            ctrl_reg<=7'd0;
            baud_reg<=16'h01b2;
            irq_enable<=5'd0;
            irq_pending<=5'd0;
            access_done<=1'b0;
        end else begin
            // A new transfer requires SETUP. Also protects against a held completed ACCESS.
            if(!PSEL || !PENABLE) access_done<=1'b0;
            else if(transfer) access_done<=1'b1;
            irq_pending<=(irq_pending & ~software_clear) | hardware_set;
            if(write_ok) begin
                case(PADDR)
                    CTRL: ctrl_reg<=PWDATA[6:0] & CTRL_MASK[6:0];
                    BAUDDIV: baud_reg<=PWDATA[15:0];
                    IRQEN: irq_enable<=PWDATA[4:0] & IRQ_MASK[4:0];
                    default: begin end
                endcase
            end
        end
    end
endmodule
