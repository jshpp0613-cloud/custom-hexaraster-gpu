module hex_event_writer #(
    parameter WIDTH = 64,      // each hex entry is 64 bits
    parameter DEPTH = 256      // max number of hexes in frame buffer
)(
    input  logic         clk,
    input  logic         reset,
    input  logic         frame_start,
    
    input  logic         valid_in,
    input  logic [15:0]  q [0:9],
    input  logic [15:0]  r [0:9],
    input  logic [7:0]   depth_val [0:9],
    input  logic [7:0]   material [0:9],
    
    output logic [WIDTH-1:0] mem [0:DEPTH-1],
    output logic [31:0]      write_count
);

    logic [31:0] write_ptr;
    logic [WIDTH-1:0] shadow [0:DEPTH-1]; // for sparse updates
    integer i;

    always_ff @(posedge clk) begin
        if (reset) begin
            write_ptr <= 0;
            write_count <= 0;
            for (i=0; i<DEPTH; i=i+1)
                shadow[i] <= 0;
        end else begin
            if (frame_start) begin
                write_ptr <= 0;
                write_count <= 0;
            end

            if (valid_in) begin
                for (i=0; i<10; i=i+1) begin
                    // pack hex data
                    logic [WIDTH-1:0] new_data;
                    new_data = {q[i], r[i], depth_val[i], material[i], 16'd0};

                    // sparse update: only write if different
                    if (write_ptr < DEPTH && new_data != shadow[write_ptr]) begin
                        mem[write_ptr] <= new_data;
                        shadow[write_ptr] <= new_data;
                        write_ptr <= write_ptr + 1;
                        write_count <= write_count + 1;
                    end
                end
            end
        end
    end

endmodule
