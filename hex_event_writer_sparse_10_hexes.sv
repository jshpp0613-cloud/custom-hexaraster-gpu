module hex_event_writer #(
    parameter BATCH = 10,
    parameter WIDTH = 64,     // memory word width
    parameter DEPTH = 256     // memory depth
)(
    input  logic                 clk,
    input  logic                 reset,
    input  logic                 frame_start,
    input  logic                 valid_in,

    input  logic signed [15:0]   q [0:BATCH-1],
    input  logic signed [15:0]   r [0:BATCH-1],
    input  logic [7:0]           depth_val [0:BATCH-1],
    input  logic [7:0]           material [0:BATCH-1],

    output logic [WIDTH-1:0]     mem [0:DEPTH-1],
    output logic [31:0]           write_count
);

    logic [31:0] write_ptr;

    integer i;

    always_ff @(posedge clk) begin
        if (reset) begin
            write_ptr <= 0;
        end else begin
            if (frame_start) begin
                write_ptr <= 0;
            end

            if (valid_in) begin
                for (i=0; i<BATCH; i=i+1) begin
                    if (write_ptr < DEPTH) begin
                        // pack q,r,depth,material into 64-bit word
                        mem[write_ptr] <= {q[i], r[i], depth_val[i], material[i], 16'd0};
                        write_ptr <= write_ptr + 1;
                    end
                end
            end
        end
    end

    assign write_count = write_ptr;

endmodule
