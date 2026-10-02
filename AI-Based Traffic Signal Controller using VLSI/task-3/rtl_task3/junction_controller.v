`timescale 1ns/1ps

// ============================================================
// Parameterized Junction Controller
// Moore FSM
// ============================================================

module junction_controller #(
    parameter integer GREEN_TIME      = 6,
    parameter integer YELLOW_TIME     = 2,
    parameter integer RED_TIME        = 2,
    parameter integer PED_TIME        = 3,
    parameter integer COUNTER_WIDTH   = 8,
    parameter integer USE_GREEN_WAVE  = 0
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    emergency_override,

    input  wire                    pedestrian_request,
    input  wire                    pedestrian_grant,

    input  wire                    green_wave_start,

    output reg                     ns_red,
    output reg                     ns_yellow,
    output reg                     ns_green,

    output reg                     ew_red,
    output reg                     ew_yellow,
    output reg                     ew_green,

    output reg                     pedestrian_active,

    output reg [2:0]               state_code,
    output reg [COUNTER_WIDTH-1:0] timer_target,

    output wire                    ped_pending,
    output wire                    ped_service_done
);

    // --------------------------------------------------------
    // FSM states
    // --------------------------------------------------------

    localparam [2:0] S_NS_GREEN      = 3'b000;
    localparam [2:0] S_NS_YELLOW     = 3'b001;
    localparam [2:0] S_ALL_RED_TO_EW = 3'b010;
    localparam [2:0] S_EW_GREEN      = 3'b011;
    localparam [2:0] S_EW_YELLOW     = 3'b100;
    localparam [2:0] S_ALL_RED_TO_NS = 3'b101;
    localparam [2:0] S_PEDESTRIAN    = 3'b110;

    // --------------------------------------------------------
    // FSM registers
    // --------------------------------------------------------

    reg [2:0] state;
    reg [2:0] next_state;

    // --------------------------------------------------------
    // Pedestrian registers
    // --------------------------------------------------------

    reg ped_request_latched;
    reg ped_request_previous;
    reg ped_return_to_ns;

    wire ped_request_rising;
    wire enter_pedestrian;

    // --------------------------------------------------------
    // Timer interface
    // --------------------------------------------------------

    wire timer_done;
    wire [COUNTER_WIDTH-1:0] timer_count;

    reg [COUNTER_WIDTH-1:0] timer_target_internal;

    wire timer_start;

    // --------------------------------------------------------
    // Start the timer only when the FSM remains in the
    // current state.
    //
    // When a state transition occurs, timer_start becomes 0,
    // causing the reusable timer to clear its count.
    // --------------------------------------------------------

    assign timer_start =
        (state == next_state) &&
        !emergency_override;

    // --------------------------------------------------------
    // Pedestrian request detection
    // --------------------------------------------------------

    assign ped_request_rising =
        pedestrian_request &
        ~ped_request_previous;

    assign ped_pending =
        ped_request_latched;

    assign ped_service_done =
        (state == S_PEDESTRIAN) &&
        timer_done;

    assign enter_pedestrian =
        ((state == S_ALL_RED_TO_EW) ||
         (state == S_ALL_RED_TO_NS)) &&
        (next_state == S_PEDESTRIAN);

    // --------------------------------------------------------
    // Reusable timer
    // --------------------------------------------------------

    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) phase_timer (
        .clk(clk),
        .reset(reset),
        .start(timer_start),
        .count_target(timer_target_internal),
        .done(timer_done),
        .count(timer_count)
    );

    // --------------------------------------------------------
    // Timer target selection
    // --------------------------------------------------------

    always @(*) begin

        case (state)

            S_NS_GREEN: begin
                timer_target_internal = GREEN_TIME;
            end

            S_NS_YELLOW: begin
                timer_target_internal = YELLOW_TIME;
            end

            S_ALL_RED_TO_EW: begin
                timer_target_internal = RED_TIME;
            end

            S_EW_GREEN: begin
                timer_target_internal = GREEN_TIME;
            end

            S_EW_YELLOW: begin
                timer_target_internal = YELLOW_TIME;
            end

            S_ALL_RED_TO_NS: begin
                timer_target_internal = RED_TIME;
            end

            S_PEDESTRIAN: begin
                timer_target_internal = PED_TIME;
            end

            default: begin
                timer_target_internal = RED_TIME;
            end

        endcase

    end

    // --------------------------------------------------------
    // Next-state logic
    // --------------------------------------------------------

    always @(*) begin

        // Default: hold current state.
        next_state = state;

        // Emergency has highest priority.
        if (emergency_override) begin

            next_state = S_ALL_RED_TO_NS;

        end
        else begin

            case (state)

                // --------------------------------------------
                // North-South Green
                // --------------------------------------------

                S_NS_GREEN: begin

                    if (timer_done) begin
                        next_state = S_NS_YELLOW;
                    end

                end

                // --------------------------------------------
                // North-South Yellow
                // --------------------------------------------

                S_NS_YELLOW: begin

                    if (timer_done) begin
                        next_state = S_ALL_RED_TO_EW;
                    end

                end

                // --------------------------------------------
                // All Red before East-West
                // --------------------------------------------

                S_ALL_RED_TO_EW: begin

                    if (timer_done) begin

                        if (ped_request_latched &&
                            pedestrian_grant) begin

                            next_state = S_PEDESTRIAN;

                        end
                        else begin

                            next_state = S_EW_GREEN;

                        end

                    end

                end

                // --------------------------------------------
                // East-West Green
                // --------------------------------------------

                S_EW_GREEN: begin

                    if (timer_done) begin
                        next_state = S_EW_YELLOW;
                    end

                end

                // --------------------------------------------
                // East-West Yellow
                // --------------------------------------------

                S_EW_YELLOW: begin

                    if (timer_done) begin
                        next_state = S_ALL_RED_TO_NS;
                    end

                end

                // --------------------------------------------
                // All Red before North-South
                // --------------------------------------------

                S_ALL_RED_TO_NS: begin

                    if (timer_done) begin

                        // Pedestrian service has priority
                        // at a safe all-red boundary.
                        if (ped_request_latched &&
                            pedestrian_grant) begin

                            next_state = S_PEDESTRIAN;

                        end

                        // Normal junction operation.
                        else if (USE_GREEN_WAVE == 0) begin

                            next_state = S_NS_GREEN;

                        end

                        // Junction B waits for its
                        // green-wave coordination signal.
                        else if (green_wave_start) begin

                            next_state = S_NS_GREEN;

                        end

                    end

                end

                // --------------------------------------------
                // Pedestrian phase
                // --------------------------------------------

                S_PEDESTRIAN: begin

                    if (timer_done) begin

                        if (ped_return_to_ns) begin

                            next_state = S_NS_GREEN;

                        end
                        else begin

                            next_state = S_EW_GREEN;

                        end

                    end

                end

                // --------------------------------------------
                // Safety recovery
                // --------------------------------------------

                default: begin

                    next_state = S_ALL_RED_TO_NS;

                end

            endcase

        end

    end

    // --------------------------------------------------------
    // Sequential logic
    // Synchronous active-high reset
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            state                 <= S_ALL_RED_TO_NS;

            ped_request_latched   <= 1'b0;
            ped_request_previous  <= 1'b0;

            ped_return_to_ns      <= 1'b1;

        end
        else begin

            state <= next_state;

            // Store previous request for edge detection.
            ped_request_previous <= pedestrian_request;

            // Emergency clears pending pedestrian operation.
            if (emergency_override) begin

                ped_request_latched <= 1'b0;

            end
            else if (ped_request_rising) begin

                // New request takes priority over service completion.
                ped_request_latched <= 1'b1;

            end
            else if (ped_service_done) begin

                ped_request_latched <= 1'b0;

            end

            // Remember where pedestrian operation should return.
            if (enter_pedestrian) begin

                if (state == S_ALL_RED_TO_NS) begin

                    ped_return_to_ns <= 1'b1;

                end
                else if (state == S_ALL_RED_TO_EW) begin

                    ped_return_to_ns <= 1'b0;

                end

            end

        end

    end

    // --------------------------------------------------------
    // Moore output logic
    // --------------------------------------------------------

    always @(*) begin

        // Safe defaults.
        ns_red            = 1'b0;
        ns_yellow         = 1'b0;
        ns_green          = 1'b0;

        ew_red            = 1'b0;
        ew_yellow         = 1'b0;
        ew_green          = 1'b0;

        pedestrian_active = 1'b0;

        state_code        = state;
        timer_target      = timer_target_internal;

        case (state)

            // --------------------------------------------
            // NS Green
            // --------------------------------------------

            S_NS_GREEN: begin

                ns_green = 1'b1;
                ew_red   = 1'b1;

            end

            // --------------------------------------------
            // NS Yellow
            // --------------------------------------------

            S_NS_YELLOW: begin

                ns_yellow = 1'b1;
                ew_red    = 1'b1;

            end

            // --------------------------------------------
            // All Red
            // --------------------------------------------

            S_ALL_RED_TO_EW: begin

                ns_red = 1'b1;
                ew_red = 1'b1;

            end

            // --------------------------------------------
            // EW Green
            // --------------------------------------------

            S_EW_GREEN: begin

                ns_red   = 1'b1;
                ew_green = 1'b1;

            end

            // --------------------------------------------
            // EW Yellow
            // --------------------------------------------

            S_EW_YELLOW: begin

                ns_red    = 1'b1;
                ew_yellow = 1'b1;

            end

            // --------------------------------------------
            // All Red
            // --------------------------------------------

            S_ALL_RED_TO_NS: begin

                ns_red = 1'b1;
                ew_red = 1'b1;

            end

            // --------------------------------------------
            // Pedestrian
            // --------------------------------------------

            S_PEDESTRIAN: begin

                ns_red            = 1'b1;
                ew_red            = 1'b1;
                pedestrian_active = 1'b1;

            end

            // --------------------------------------------
            // Safety default
            // --------------------------------------------

            default: begin

                ns_red = 1'b1;
                ew_red = 1'b1;

            end

        endcase

    end

endmodule