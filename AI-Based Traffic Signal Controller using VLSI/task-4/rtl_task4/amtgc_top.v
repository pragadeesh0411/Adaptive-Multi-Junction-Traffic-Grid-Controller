`timescale 1ns/1ps

// ============================================================
// Adaptive Multi-Junction Traffic Grid Controller
// Task 4 - System Integration with Adaptive Timing
// ============================================================

module amtgc_top #(
    // --------------------------------------------------------
    // Junction A parameters
    // --------------------------------------------------------

    parameter integer A_GREEN_TIME                = 5,
    parameter integer A_MIN_GREEN_TIME            = 4,
    parameter integer A_MAX_GREEN_TIME            = 8,
    parameter integer A_GREEN_EXTENSION_PER_LEVEL = 1,

    parameter integer A_YELLOW_TIME               = 2,
    parameter integer A_RED_TIME                  = 2,
    parameter integer A_PED_TIME                  = 2,

    // --------------------------------------------------------
    // Junction B parameters
    // --------------------------------------------------------

    parameter integer B_GREEN_TIME                = 5,
    parameter integer B_MIN_GREEN_TIME            = 4,
    parameter integer B_MAX_GREEN_TIME            = 8,
    parameter integer B_GREEN_EXTENSION_PER_LEVEL = 1,

    parameter integer B_YELLOW_TIME               = 2,
    parameter integer B_RED_TIME                  = 2,
    parameter integer B_PED_TIME                  = 3,

    // --------------------------------------------------------
    // Common parameters
    // --------------------------------------------------------

    parameter integer COUNTER_WIDTH               = 8,
    parameter integer GREEN_WAVE_DELAY            = 1
)(
    // --------------------------------------------------------
    // System inputs
    // --------------------------------------------------------

    input wire clk,
    input wire reset,

    input wire emergency_override,

    input wire [2:0] a_traffic_density,
    input wire [2:0] b_traffic_density,

    input wire a_pedestrian_request,
    input wire b_pedestrian_request,

    // --------------------------------------------------------
    // Junction A outputs
    // --------------------------------------------------------

    output wire a_ns_red,
    output wire a_ns_yellow,
    output wire a_ns_green,

    output wire a_ew_red,
    output wire a_ew_yellow,
    output wire a_ew_green,

    // --------------------------------------------------------
    // Junction B outputs
    // --------------------------------------------------------

    output wire b_ns_red,
    output wire b_ns_yellow,
    output wire b_ns_green,

    output wire b_ew_red,
    output wire b_ew_yellow,
    output wire b_ew_green,

    // --------------------------------------------------------
    // Pedestrian outputs
    // --------------------------------------------------------

    output wire a_pedestrian_active,
    output wire b_pedestrian_active,

    // --------------------------------------------------------
    // FSM state outputs
    // --------------------------------------------------------

    output wire [2:0] a_state,
    output wire [2:0] b_state,

    // --------------------------------------------------------
    // Dynamic timer targets
    // --------------------------------------------------------

    output wire [COUNTER_WIDTH-1:0] a_timer_target,
    output wire [COUNTER_WIDTH-1:0] b_timer_target,

    // --------------------------------------------------------
    // Pending requests
    // --------------------------------------------------------

    output wire a_ped_pending,
    output wire b_ped_pending,

    // --------------------------------------------------------
    // Arbiter grants
    // --------------------------------------------------------

    output wire ped_grant_a,
    output wire ped_grant_b,

    // --------------------------------------------------------
    // Green-wave status
    // --------------------------------------------------------

    output wire green_wave_start_b
);

    // ========================================================
    // Internal signals
    // ========================================================

    wire ped_service_done_a;
    wire ped_service_done_b;

    wire priority_a_next;

    // ========================================================
    // Shared pedestrian arbiter
    // ========================================================

    ped_arbiter shared_ped_arbiter (
        .clk(clk),
        .reset(reset),

        .req_a(a_ped_pending),
        .req_b(b_ped_pending),

        .service_done_a(ped_service_done_a),
        .service_done_b(ped_service_done_b),

        .grant_a(ped_grant_a),
        .grant_b(ped_grant_b),

        .priority_a_next(priority_a_next)
    );

    // ========================================================
    // Green-wave coordinator
    // ========================================================

    green_wave_coordinator #(
        .GREEN_WAVE_DELAY(GREEN_WAVE_DELAY),
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) wave_coordinator (
        .clk(clk),
        .reset(reset),

        .source_ns_green(a_ns_green),

        .wave_start(green_wave_start_b)
    );

    // ========================================================
    // Junction A
    // ========================================================

    junction_controller #(
        .GREEN_TIME(A_GREEN_TIME),
        .MIN_GREEN_TIME(A_MIN_GREEN_TIME),
        .MAX_GREEN_TIME(A_MAX_GREEN_TIME),
        .GREEN_EXTENSION_PER_LEVEL(
            A_GREEN_EXTENSION_PER_LEVEL
        ),

        .YELLOW_TIME(A_YELLOW_TIME),
        .RED_TIME(A_RED_TIME),
        .PED_TIME(A_PED_TIME),

        .COUNTER_WIDTH(COUNTER_WIDTH),
        .USE_GREEN_WAVE(0)
    ) junction_a (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

        .traffic_density(a_traffic_density),

        .pedestrian_request(a_pedestrian_request),
        .pedestrian_grant(ped_grant_a),

        .green_wave_start(1'b0),

        .ns_red(a_ns_red),
        .ns_yellow(a_ns_yellow),
        .ns_green(a_ns_green),

        .ew_red(a_ew_red),
        .ew_yellow(a_ew_yellow),
        .ew_green(a_ew_green),

        .pedestrian_active(a_pedestrian_active),

        .state_code(a_state),
        .timer_target(a_timer_target),

        .ped_pending(a_ped_pending),
        .ped_service_done(ped_service_done_a)
    );

    // ========================================================
    // Junction B
    // ========================================================

    junction_controller #(
        .GREEN_TIME(B_GREEN_TIME),
        .MIN_GREEN_TIME(B_MIN_GREEN_TIME),
        .MAX_GREEN_TIME(B_MAX_GREEN_TIME),
        .GREEN_EXTENSION_PER_LEVEL(
            B_GREEN_EXTENSION_PER_LEVEL
        ),

        .YELLOW_TIME(B_YELLOW_TIME),
        .RED_TIME(B_RED_TIME),
        .PED_TIME(B_PED_TIME),

        .COUNTER_WIDTH(COUNTER_WIDTH),
        .USE_GREEN_WAVE(1)
    ) junction_b (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

        .traffic_density(b_traffic_density),

        .pedestrian_request(b_pedestrian_request),
        .pedestrian_grant(ped_grant_b),

        .green_wave_start(green_wave_start_b),

        .ns_red(b_ns_red),
        .ns_yellow(b_ns_yellow),
        .ns_green(b_ns_green),

        .ew_red(b_ew_red),
        .ew_yellow(b_ew_yellow),
        .ew_green(b_ew_green),

        .pedestrian_active(b_pedestrian_active),

        .state_code(b_state),
        .timer_target(b_timer_target),

        .ped_pending(b_ped_pending),
        .ped_service_done(ped_service_done_b)
    );

endmodule