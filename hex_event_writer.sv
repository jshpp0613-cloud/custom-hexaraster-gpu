module hex_event_writer (
    input  logic        clk,
    input  logic        reset,
    input  logic        frame_start,

    input  logic        valid_in,
    input  logic signed [15:0] q,
    input  logic signed [15:0] r,
    input  logic [7:0]  depth,
    input  logic [7:0]  material,

    output logic [31:0] mem_addr,
    output logic [63:0] mem_data,
    output logic        mem_we,
    input  logic        mem_ready,

    input  logic [31:0] buffer_base
);

    logic [31:0] write_ptr;

    always_ff @(posedge clk) begin
        if (reset) begin
            write_ptr <= 32'd0;
            mem_we    <= 1'b0;
        end else begin
            if (frame_start)
                write_ptr <= buffer_base;

            if (valid_in && mem_ready) begin
                mem_addr <= write_ptr;
                mem_data <= {q, r, depth, material, 16'd0};
                mem_we   <= 1'b1;
                write_ptr <= write_ptr + 1;
            end else begin
                mem_we <= 1'b0;
            end
        end
    end
endmodule
