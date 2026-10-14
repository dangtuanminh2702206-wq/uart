// Five-state FSMD. Every sequential block uses the system clock.
module uart_tx (
    input wire clk, rst_n,
    input wire [8:0] tx_data,
    input wire [1:0] data_bit_num,
    input wire stop_bit_num, parity_en, parity_type,
    input wire [15:0] baud_div,
    input wire tx_start, cts_n,
    output reg tx,
    output reg tx_done,
    output wire tx_busy
);
    localparam [2:0] IDLE=3'd0, START=3'd1, DATA=3'd2,
                     PARITY=3'd3, STOP=3'd4;
    reg [2:0] state, next_state;
    reg [15:0] baud_latched, baud_count;
    reg [8:0] shift_reg;
    reg [3:0] bit_count, last_bit;
    reg stop_count, stop_latched, parity_en_latched, parity_bit;
    reg [3:0] config_last_bit;
    reg config_parity;
    wire load_reg = (state == IDLE) && tx_start && !cts_n;
    wire tick_last = (baud_count == baud_latched - 16'd1);
    wire bit_last = (bit_count == last_bit);
    wire stop_last = (stop_count == stop_latched);
    assign tx_busy = (state != IDLE);

    // Compute parity using only the data bits actually transmitted.
    always @(*) begin
        config_last_bit = 4'd7;
        config_parity = (^tx_data[7:0]) ^ parity_type;
        case (data_bit_num)
            2'b00: begin
                config_last_bit = 4'd6;
                config_parity = (^tx_data[6:0]) ^ parity_type;
            end
            2'b10: begin
                config_last_bit = 4'd8;
                config_parity = (^tx_data[8:0]) ^ parity_type;
            end
            default: begin end
        endcase
    end

    // FSM and output mux match IDLE -> START -> DATA -> PARITY/STOP.
    always @(*) begin
        next_state = state;
        tx = 1'b1;
        case (state)
            IDLE: if (load_reg) next_state = START;
            START: begin
                tx = 1'b0;
                if (tick_last) next_state = DATA;
            end
            DATA: begin
                tx = shift_reg[0];
                if (tick_last && bit_last)
                    next_state = parity_en_latched ? PARITY : STOP;
            end
            PARITY: begin
                tx = parity_bit;
                if (tick_last) next_state = STOP;
            end
            STOP: if (tick_last && stop_last) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Baud counter is phase-aligned to acceptance of each new frame.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            baud_latched <= 16'd1;
            baud_count <= 16'd0;
            shift_reg <= 9'd0;
            bit_count <= 4'd0;
            last_bit <= 4'd7;
            stop_count <= 1'b0;
            stop_latched <= 1'b0;
            parity_en_latched <= 1'b0;
            parity_bit <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            state <= next_state;
            tx_done <= (state == STOP) && tick_last && stop_last;
            if (state == IDLE || tick_last)
                baud_count <= 16'd0;
            else
                baud_count <= baud_count + 16'd1;
            if (load_reg) begin
                baud_latched <= (baud_div == 0) ? 16'd1 : baud_div;
                shift_reg <= tx_data;
                last_bit <= config_last_bit;
                bit_count <= 4'd0;
                stop_count <= 1'b0;
                stop_latched <= stop_bit_num;
                parity_en_latched <= parity_en;
                parity_bit <= config_parity;
            end else if (tick_last) begin
                if (state == DATA && !bit_last) begin
                    shift_reg <= {1'b1, shift_reg[8:1]};
                    bit_count <= bit_count + 4'd1;
                end
                if (state == STOP && !stop_last)
                    stop_count <= 1'b1;
            end
        end
    end
endmodule
