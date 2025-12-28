module hex_event_writer_fsm #(
    parameter WIDTH = 64,
    parameter DEPTH = 256
)(
    input  logic                 clk,
    input  logic                 reset,
    input  logic                 frame_start,

    input  logic                 valid_in,
    input  logic signed [15:0]   q,
    input  logic signed [15:0]   r,
    input  logic [7:0]           depth_val,
    input  logic [7:0]           material,

    output logic [WIDTH-1:0]     mem [0:DEPTH-1],
    output logic [31:0]          write_count,
    output logic                 drop_event
);

    logic [$clog2(DEPTH):0] write_ptr;

    always_ff @(posedge clk) begin
        if (reset) begin
            write_ptr  <= 0;
            drop_event <= 0;
        end else begin
            drop_event <= 0;

            if (frame_start) begin
                write_ptr <= 0;
            end

            if (valid_in) begin
                if (write_ptr < DEPTH) begin
                    mem[write_ptr] <= {
                        q,
                        r,
                        depth_val,
                        material,
                        16'd0
                    };
                    write_ptr <= write_ptr + 1;
                end else begin
                    // Deterministic drop — NEVER stall
                    drop_event <= 1;
                end
            end
        end
    end

    assign write_count = write_ptr;

endmodule
