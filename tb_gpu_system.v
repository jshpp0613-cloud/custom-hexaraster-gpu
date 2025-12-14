`timescale 1ns / 1ps

module tb_gpu_system;

    // Clock and Reset
    reg clk;
    reg reset;

    // Test inputs for the GPU system
    reg [31:0] vertex_x, vertex_y, vertex_z;  // Input vertex (3D coordinates)
    reg [31:0] matrix [3:0][3:0];            // Transformation matrix
    reg [31:0] hex_size;                     // Size of hexagons

    // Outputs from GPU system
    wire [31:0] hex_q, hex_r;                // Hexagon grid output coordinates
    wire valid;                              // Indicates rasterization validity

    // Instantiate GPU system
    gpu_system gpu_system_inst (
        .clk(clk),
        .reset(reset),
        .vertex_x(vertex_x),
        .vertex_y(vertex_y),
        .vertex_z(vertex_z),
        .matrix(matrix),
        .hex_size(hex_size),
        .hex_q(hex_q),
        .hex_r(hex_r),
        .valid(valid)
    );

    // Clock generation
    always #5 clk = ~clk;  // Clock toggles every 5ns (10ns period)

    // Test sequence
    initial begin
        clk = 0;  // Initialize clock
        reset = 1;  // Assert reset
        #15;  // Wait for reset duration
        reset = 0;  // Deassert reset

        // --------------- TEST 1: Vertex Shader + Hexagonal Rasterizer ---------------
        // Initialize transformation matrix (Identity matrix for simple testing)
        matrix[0][0] = 32'h00010000; // 1.0 in Q16.16 fixed-point format
        matrix[0][1] = 32'h00000000; // 0.0
        matrix[0][2] = 32'h00000000; // 0.0
        matrix[0][3] = 32'h00000000; // 0.0

        matrix[1][0] = 32'h00000000; // 0.0
        matrix[1][1] = 32'h00010000; // 1.0
        matrix[1][2] = 32'h00000000; // 0.0
        matrix[1][3] = 32'h00000000; // 0.0

        matrix[2][0] = 32'h00000000; // 0.0
        matrix[2][1] = 32'h00000000; // 0.0
        matrix[2][2] = 32'h00010000; // 1.0
        matrix[2][3] = 32'h00000000; // 0.0

        matrix[3][0] = 32'h00000000; // 0.0
        matrix[3][1] = 32'h00000000; // 0.0
        matrix[3][2] = 32'h00000000; // 0.0
        matrix[3][3] = 32'h00010000; // 1.0

        // Input vertex coordinates (example: (1.0, 1.0, 1.0) in Q16.16 format)
        vertex_x = 32'h00010000; // 1.0
        vertex_y = 32'h00010000; // 1.0
        vertex_z = 32'h00010000; // 1.0

        // Set the hexagon size
        hex_size = 32'h00001000;  // Small hexagon grid

        // Wait for vertex shader and hexagonal rasterizer to process
        #50;

        // Display results for GPU system test
        if (valid) begin
            $display("System Test Result:");
            $display("Input Vertex: (%d, %d, %d)", vertex_x, vertex_y, vertex_z);
            $display("Hexagon Grid Output: Q = %d, R = %d", hex_q, hex_r);
        end else begin
            $display("No valid rasterized output for the given vertex.");
        end

        // --------------- END OF TEST 1 ------------------

        // More test cases can be added below (e.g., rotating the vertex, new transformation matrices)
        // Sample: Change to a scaling or rotation matrix and verify new results.

        $stop; // End simulation
    end

endmodule