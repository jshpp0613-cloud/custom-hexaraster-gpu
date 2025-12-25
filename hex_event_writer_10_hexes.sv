module hex_event_writer_10 (
    input  logic        clk,
    input  logic        reset,
    input  logic        frame_start,

    input  logic        valid_in,
    input  logic signed [15:0] q[0:9],
    input  logic signed [15:0] r[0:9],
    input  logic [7:0]  depth[0:9],
    input  logic [7:0]  material,

    output logic [31:0] mem_addr,
    output logic [639:0] mem_data, // 10 hexes
    output logic        mem_we,
    input  logic        mem_ready,
    input  logic [31:0] buffer_base,
    output logic        ready_out
);

    logic [31:0] write_ptr;

    always_ff @(posedge clk) begin
        if (reset) begin
            write_ptr <= buffer_base;
            mem_we    <= 1'b0;
            ready_out <= 1'b1;
        end else begin
            if (frame_start)
                write_ptr <= buffer_base;

            if (valid_in && mem_ready) begin
                mem_addr <= write_ptr;
                for (int i = 0; i < 10; i++) begin
                    mem_data[64*i +: 64] <= {q[i], r[i], depth[i], material, 16'd0};
                end
                mem_we   <= 1'b1;
                write_ptr <= write_ptr + 10;
                ready_out <= 1'b1;
            end else begin
                mem_we <= 1'b0;
                ready_out <= mem_ready; // stall if memory not ready
            end
        end
    end
endmodule
