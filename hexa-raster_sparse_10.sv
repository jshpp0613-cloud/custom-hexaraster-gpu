module hexagonal_rasterizer_q16 #(
    parameter BATCH = 10
)(
    input  logic         clk,
    input  logic         reset,
    input  logic         valid_in,

    input  logic [31:0]  q_f [0:BATCH-1],  // Q16.16
    input  logic [31:0]  r_f [0:BATCH-1],  // Q16.16
    input  logic [31:0]  s_f [0:BATCH-1],  // Q16.16

    output logic signed [15:0] q [0:BATCH-1],
    output logic signed [15:0] r [0:BATCH-1],
    output logic [7:0]         depth [0:BATCH-1],
    output logic               valid_out
);

    integer i;
    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 0;
        end else if (valid_in) begin
            for (i=0; i<BATCH; i=i+1) begin
                // Q16.16 → integer rounding
                q[i] <= $signed(q_f[i][31:16]);
                r[i] <= $signed(r_f[i][31:16]);
                depth[i] <= 8'd0;  // placeholder depth
            end
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end

endmodule
