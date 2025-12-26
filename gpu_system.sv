module gpu_system (
    input  logic        clk,
    input  logic        reset,

    // Vertex input
    input  logic        in_valid,
    output logic        in_ready,
    input  logic signed [31:0] vx_q16,
    input  logic signed [31:0] vy_q16,
    input  logic signed [31:0] vz_q16,

    // Config
    input  logic signed [31:0] matrix [0:3][0:3],
    input  logic signed [31:0] hex_size_q16,
    input  logic signed [31:0] cam_x_q16,
    input  logic signed [31:0] cam_y_q16,
    input  logic signed [31:0] zoom_q16,

    // Simulation dirty mask
    input  logic [9:0] changed_mask,

    // Frame
    input  logic        frame_start,

    // Host memory
    output logic [31:0] mem_addr,
    output logic [639:0] mem_data,
    output logic        mem_we,
    input  logic        mem_ready,
    input  logic [31:0] buffer_base
);

    // interconnect
    logic vs_valid, hs_valid, rast_valid;
    logic vs_ready, hs_ready, rast_ready;

    logic signed [31:0] q_f, r_f, s_f;

    logic signed [15:0] q [0:9];
    logic signed [15:0] r [0:9];
    logic [7:0]         depth [0:9];
    logic               dirty [0:9];

    // Vertex shader
    vertex_shader_hex_q16 vs (
        .clk(clk),
        .reset(reset),
        .valid_in(in_valid),
        .ready_in(vs_ready),
        .ready_out(in_ready),
        .x_q16(vx_q16),
        .y_q16(vy_q16),
        .z_q16(vz_q16),
        .matrix(matrix),
        .hex_size_q16(hex_size_q16),
        .q_f(q_f),
        .r_f(r_f),
        .s_f(s_f),
        .valid_out(vs_valid)
    );

    // Rasterizer (sparse)
    hexagonal_rasterizer_sparse_10 rast (
        .clk(clk),
        .reset(reset),
        .valid_in(vs_valid),
        .ready_in(rast_ready),
        .q_f(q_f),
        .r_f(r_f),
        .s_f(s_f),
        .changed_mask(changed_mask),
        .q(q),
        .r(r),
        .depth(depth),
        .dirty(dirty),
        .valid_out(rast_valid),
        .ready_out(vs_ready)
    );

    // Writer (sparse)
    hex_event_writer_sparse_10 writer (
        .clk(clk),
        .reset(reset),
        .frame_start(frame_start),
        .valid_in(rast_valid),
        .q(q),
        .r(r),
        .depth(depth),
        .dirty(dirty),
        .material(8'd0),
        .mem_addr(mem_addr),
        .mem_data(mem_data),
        .mem_we(mem_we),
        .mem_ready(mem_ready),
        .buffer_base(buffer_base),
        .ready_out(rast_ready)
    );

endmodule
