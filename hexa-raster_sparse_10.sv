module hexagonal_rasterizer_fill #(
    parameter RADIUS = 2,
    parameter MAX_OUT = 64   // worst-case: 1 + 3R(R+1)
)(
    input  logic               clk,
    input  logic               reset,
    input  logic               valid_in,

    // Rounded center hex
    input  logic signed [15:0] q_center,
    input  logic signed [15:0] r_center,

    output logic signed [15:0] q_out [0:MAX_OUT-1],
    output logic signed [15:0] r_out [0:MAX_OUT-1],
    output logic [7:0]         depth [0:MAX_OUT-1],
    output logic [7:0]         count,
    output logic               valid_out
);

    integer dq, dr;
    integer idx;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 0;
            count <= 0;
        end else if (valid_in) begin
            idx = 0;

            for (dq = -RADIUS; dq <= RADIUS; dq = dq + 1) begin
                for (dr = 
                    (dq < 0 ? -RADIUS - dq : -RADIUS);
                    dr <= (dq > 0 ? RADIUS - dq : RADIUS);
                    dr = dr + 1
                ) begin
                    if (idx < MAX_OUT) begin
                        q_out[idx] <= q_center + dq;
                        r_out[idx] <= r_center + dr;
                        depth[idx] <= 8'd0;
                        idx = idx + 1;
                    end
                end
            end

            count <= idx[7:0];
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end

endmodule
