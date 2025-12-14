// File: hexagonal_rasterizer.v
module hexagonal_rasterizer (
    input clk,
    input reset,
    input [31:0] v0_x, v0_y,   // Vertex 0
    input [31:0] v1_x, v1_y,   // Vertex 1
    input [31:0] v2_x, v2_y,   // Vertex 2
    input [31:0] hex_size,     // Size of each hexagon
    output reg [31:0] hex_q, hex_r, // Hexagonal grid coordinates
    output reg valid           // Validity flag for rasterized hex
);
    reg [31:0] hex_center_x, hex_center_y;

    wire signed [31:0] edge1, edge2, edge3;

    // Edge function calculation
    assign edge1 = (v1_x - v0_x) * (hex_center_y - v0_y) - (v1_y - v0_y) * (hex_center_x - v0_x);
    assign edge2 = (v2_x - v1_x) * (hex_center_y - v1_y) - (v2_y - v1_y) * (hex_center_x - v1_x);
    assign edge3 = (v0_x - v2_x) * (hex_center_y - v2_y) - (v0_y - v2_y) * (hex_center_x - v2_x);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid <= 0;
            hex_q <= 0;
            hex_r <= 0;
        end else begin
            // Iterate over the grid (hex centers)
            hex_center_x <= hex_center_x + (3 * hex_size / 2);
            hex_center_y <= hex_center_y + (hex_size * 86 / 100); // Approx. sqrt(3)

            if (edge1 >= 0 && edge2 >= 0 && edge3 >= 0) begin
                valid <= 1;
                // Calculate axial hexagonal coordinates
                hex_q <= (57735 * hex_center_x) / 100000 - (hex_center_y / 3); // Approx sqrt(3)/3
                hex_r <= (2 * hex_center_y) / 3;
            end else begin
                valid <= 0;
            end
        end
    end
endmodule