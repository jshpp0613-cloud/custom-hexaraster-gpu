module hex_event_writer_sparse_10 (
    input  logic        clk,
    input  logic        reset,
    input  logic        frame_start,

    input  logic        valid_in,
    input  logic signed [15:0] q [0:9],
    input  logic signed [15:0] r [0:9],
    input  logic [7:0]         depth [0:9],
    input  logic               dirty [0:9],
    input  logic [7:0]         material,

    output logic [31:0]        mem_addr,
    output logic [639:0]       mem_data,
    output logic               mem_we,
    input  logic               mem_ready,

    input  logic [31:0]        buffer_base,
    output logic               ready_out
);

    logic [31:0] write_ptr;
    integer i;
    integer w;

    always_ff @(posedge clk) begin
        if (reset) begin
            write_ptr <= buffer_base;
            mem_we    <= 1'b0;
            ready_out <= 1'b1;
        end
        else begin
            if (frame_start)
                write_ptr <= buffer_base;

            mem_we <= 1'b0;
            w = 0;

            if (valid_in && mem_ready) begin
                mem_addr <= write_ptr;

                // Pack ONLY dirty hexes
                for (i = 0; i < 10; i++) begin
                    if (dirty[i]) begin
                        mem_data[64*w +: 64] <= { q[i], r[i], depth[i], material, 16'd0 };
                        w = w + 1;
                    end
                end

                if (w != 0) begin
                    mem_we    <= 1'b1;
                    write_ptr <= write_ptr + w;
                end

                ready_out <= 1'b1;
            end
            else begin
                ready_out <= mem_ready;
            end
        end
    end
endmodule
