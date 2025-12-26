module vertex_shader_hex_q16 #(
    parameter BATCH = 10
)(
    input  logic         clk,
    input  logic         reset,
    input  logic         valid_in,

    input  logic [31:0]  x [0:BATCH-1],   // Q16.16
    input  logic [31:0]  y [0:BATCH-1],   // Q16.16
    input  logic [31:0]  z [0:BATCH-1],   // Q16.16
    input  logic [31:0]  matrix [0:3][0:3], // Q16.16
    input  logic [31:0]  hex_size_q16,    // Q16.16

    output logic [31:0]  screen_x [0:BATCH-1],  // Q16.16
    output logic [31:0]  screen_y [0:BATCH-1],  // Q16.16
    output logic [31:0]  hex_q_f [0:BATCH-1],   // Q16.16
    output logic [31:0]  hex_r_f [0:BATCH-1],   // Q16.16
    output logic [31:0]  hex_s_f [0:BATCH-1],   // Q16.16
    output logic [7:0]   hex_lod [0:BATCH-1],
    output logic         valid_out
);

    localparam logic [31:0] SQRT3_DIV_3_Q16 = 32'd74565;   // ~sqrt(3)/3 in Q16.16
    localparam logic [31:0] ONE_DIV_3_Q16   = 32'd21845;   // 1/3 in Q16.16
    localparam logic [31:0] TWO_DIV_3_Q16   = 32'd43690;   // 2/3 in Q16.16

    integer i;
    logic signed [63:0] wx_tmp, wy_tmp;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_out <= 0;
        end else if (valid_in) begin
            for (i=0; i<BATCH; i=i+1) begin
                // Vertex transform in Q16.16
                wx_tmp = (x[i]*matrix[0][0] + y[i]*matrix[0][1] + z[i]*matrix[0][2] + matrix[0][3]);
                wy_tmp = (x[i]*matrix[1][0] + y[i]*matrix[1][1] + z[i]*matrix[1][2] + matrix[1][3]);

                screen_x[i] = wx_tmp[47:16]; // truncate back to Q16.16
                screen_y[i] = wy_tmp[47:16];

                // Hex coordinates in Q16.16
                hex_q_f[i] = ((SQRT3_DIV_3_Q16 * screen_x[i] - ONE_DIV_3_Q16 * screen_y[i]) <<< 0) / hex_size_q16;
                hex_r_f[i] = ((TWO_DIV_3_Q16 * screen_y[i]) <<< 0) / hex_size_q16;
                hex_s_f[i] = -(hex_q_f[i] + hex_r_f[i]);

                // Simple LOD
                hex_lod[i] = ((screen_x[i]*screen_x[i] + screen_y[i]*screen_y[i]) > 32'h4F000000) ? 8'd3 : 8'd1;
            end
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end

endmodule
