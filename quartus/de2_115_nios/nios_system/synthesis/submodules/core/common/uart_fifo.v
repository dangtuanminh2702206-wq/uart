// Fixed 16-entry, 9-bit synchronous FIFO with an asynchronous head read.
module uart_fifo (
    input wire clk, rst_n,
    input wire push, pop,
    input wire [8:0] write_data,
    output wire [8:0] read_data,
    output wire full, empty,
    output reg [4:0] count
);
    localparam [4:0] DEPTH=5'd16;
    reg [8:0] memory [0:15];
    reg [3:0] write_ptr, read_ptr;
    wire do_pop = pop && !empty;
    wire do_push = push && (!full || do_pop);
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    assign read_data = empty ? 9'd0 : memory[read_ptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 4'd0;
            read_ptr <= 4'd0;
            count <= 5'd0;
        end else begin
            if (do_push) begin
                memory[write_ptr] <= write_data;
                write_ptr <= write_ptr + 4'd1;
            end
            if (do_pop)
                read_ptr <= read_ptr + 4'd1;
            case ({do_push,do_pop})
                2'b10: count <= count + 5'd1;
                2'b01: count <= count - 5'd1;
                default: count <= count;
            endcase
        end
    end
endmodule
