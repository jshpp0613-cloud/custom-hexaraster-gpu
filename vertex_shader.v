// File: vertex_shader.v
module vertex_shader (
    input clk,
    input reset,
    input [31:0] x, y, z,  // Input 3D vertex coordinates
    input [31:0] matrix[3:0][3:0], // 4x4 transformation matrix
    output reg [31:0] x_out, y_out // Projected 2D screen space coordinates
);
    reg [31:0] x_transformed, y_transformed, z_transformed, w_transformed;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_transformed <= 32'b0;
            y_transformed <= 32'b0;
            z_transformed <= 32'b0;
            w_transformed <= 32'b0;
            x_out <= 32'b0;
            y_out <= 32'b0;
        end else begin
            // Perform matrix transformation
            x_transformed <= (x * matrix[0][0]) + (y * matrix[0][1]) + (z * matrix[0][2]) + matrix[0][3];
            y_transformed <= (x * matrix[1][0]) + (y * matrix[1][1]) + (z * matrix[1][2]) + matrix[1][3];
            z_transformed <= (x * matrix[2][0]) + (y * matrix[2][1]) + (z * matrix[2][2]) + matrix[2][3];
            w_transformed <= (x * matrix[3][0]) + (y * matrix[3][1]) + (z * matrix[3][2]) + matrix[3][3];

            // Perspective divide
            x_out <= x_transformed / w_transformed;
            y_out <= y_transformed / w_transformed;
        end
    end
endmodule