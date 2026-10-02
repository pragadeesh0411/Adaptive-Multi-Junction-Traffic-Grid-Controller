`timescale 1ns/1ps

// ============================================================
// AMTGC TASK 5
// Unified Self-Checking Verification Testbench
// ============================================================

module amtgc_task5_tb;


// ============================================================
// PARAMETERS
// ============================================================

localparam integer A_GREEN_TIME_P =
    5;

localparam integer A_MIN_P =
    4;

localparam integer A_MAX_P =
    7;

localparam integer A_EXT_P =
    1;


localparam integer B_GREEN_TIME_P =
    4;

localparam integer B_MIN_P =
    3;

localparam integer B_MAX_P =
    6;

localparam integer B_EXT_P =
    1;


localparam integer YELLOW_P =
    2;

localparam integer RED_P =
    2;

localparam integer PED_P =
    3;

localparam integer WAVE_DELAY_P =
    2;


// Random verification
localparam integer RANDOM_CYCLES =
    1000;

// 60 pairs × 2 junction requests = 120 requests
localparam integer PED_ROUNDS =
    60;


// ============================================================
// INPUTS
// ============================================================

reg clk;
reg reset;
reg emergency_override;

reg [2:0] a_density;
reg [2:0] b_density;

reg ped_a;
reg ped_b;


// ============================================================
// OUTPUTS
// ============================================================

wire a_ns_red;
wire a_ns_yellow;
wire a_ns_green;

wire a_ew_red;
wire a_ew_yellow;
wire a_ew_green;

wire a_ped_active;


wire b_ns_red;
wire b_ns_yellow;
wire b_ns_green;

wire b_ew_red;
wire b_ew_yellow;
wire b_ew_green;

wire b_ped_active;


wire [2:0] a_state;
wire [2:0] b_state;


wire [15:0] a_timer_target;
wire [15:0] b_timer_target;


wire a_pending;
wire b_pending;


wire grant_a;
wire grant_b;


wire wave_start_b;


// ============================================================
// TEST COUNTERS
// ============================================================

integer errors;
integer simulation_cycles;

integer safety_checks;

integer density_tests;

integer pedestrian_requests;

integer pedestrian_services_a;
integer pedestrian_services_b;

integer emergency_tests;

integer repeated_emergency_tests;

integer active_reset_tests;

integer wave_tests;

integer random_cycles_done;


// ============================================================
// PREVIOUS SIGNALS
// ============================================================

reg previous_a_ns_green;
reg previous_b_ns_green;

reg previous_a_ped;
reg previous_b_ped;

reg [2:0] previous_a_state;
reg [2:0] previous_b_state;


// ============================================================
// PHASE COVERAGE
//
// Bit:
// 0 NS Green
// 1 NS Yellow
// 2 All Red to EW
// 3 EW Green
// 4 EW Yellow
// 5 All Red to NS
// 6 Pedestrian
// ============================================================

reg [6:0] phase_seen_a;
reg [6:0] phase_seen_b;


// ============================================================
// DUT
// ============================================================

amtgc_top #(

    .A_GREEN_TIME(
        A_GREEN_TIME_P
    ),

    .A_GREEN_MIN_TIME(
        A_MIN_P
    ),

    .A_GREEN_MAX_TIME(
        A_MAX_P
    ),

    .A_GREEN_EXTENSION_PER_LEVEL(
        A_EXT_P
    ),


    .B_GREEN_TIME(
        B_GREEN_TIME_P
    ),

    .B_GREEN_MIN_TIME(
        B_MIN_P
    ),

    .B_GREEN_MAX_TIME(
        B_MAX_P
    ),

    .B_GREEN_EXTENSION_PER_LEVEL(
        B_EXT_P
    ),


    .YELLOW_TIME(
        YELLOW_P
    ),

    .A_RED_TIME(
        RED_P
    ),

    .B_RED_TIME(
        RED_P
    ),

    .PED_TIME(
        PED_P
    ),

    .GREEN_WAVE_DELAY(
        WAVE_DELAY_P
    ),

    .COUNTER_WIDTH(
        16
    )

) dut (

    .clk(clk),
    .reset(reset),

    .emergency_override(
        emergency_override
    ),

    .a_traffic_density(
        a_density
    ),

    .b_traffic_density(
        b_density
    ),

    .a_pedestrian_request(
        ped_a
    ),

    .b_pedestrian_request(
        ped_b
    ),


    .a_ns_red(a_ns_red),
    .a_ns_yellow(a_ns_yellow),
    .a_ns_green(a_ns_green),

    .a_ew_red(a_ew_red),
    .a_ew_yellow(a_ew_yellow),
    .a_ew_green(a_ew_green),

    .a_pedestrian_active(
        a_ped_active
    ),

    .a_state(a_state),

    .a_timer_target(
        a_timer_target
    ),

    .a_ped_pending(
        a_pending
    ),


    .b_ns_red(b_ns_red),
    .b_ns_yellow(b_ns_yellow),
    .b_ns_green(b_ns_green),

    .b_ew_red(b_ew_red),
    .b_ew_yellow(b_ew_yellow),
    .b_ew_green(b_ew_green),

    .b_pedestrian_active(
        b_ped_active
    ),

    .b_state(b_state),

    .b_timer_target(
        b_timer_target
    ),

    .b_ped_pending(
        b_pending
    ),


    .ped_grant_a(
        grant_a
    ),

    .ped_grant_b(
        grant_b
    ),

    .green_wave_start_b(
        wave_start_b
    )

);


// ============================================================
// CLOCK
// ============================================================

initial begin
    clk = 1'b0;
end

always #5 clk = ~clk;


// ============================================================
// SIMULATION CYCLE COUNTER
// ============================================================

always @(posedge clk) begin
    simulation_cycles =
        simulation_cycles + 1;
end


// ============================================================
// CONTINUOUS SELF-CHECKING
// ============================================================

always @(negedge clk) begin


    // --------------------------------------------------------
    // Valid A state
    // --------------------------------------------------------

    if ((^a_state) === 1'bx) begin

        $display(
            "[FAIL] A state contains X/Z"
        );

        errors =
            errors + 1;

    end
    else if (a_state <= 3'd6) begin

        phase_seen_a[a_state] =
            1'b1;

    end
    else begin

        $display(
            "[FAIL] Invalid A state = %0d",
            a_state
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // Valid B state
    // --------------------------------------------------------

    if ((^b_state) === 1'bx) begin

        $display(
            "[FAIL] B state contains X/Z"
        );

        errors =
            errors + 1;

    end
    else if (b_state <= 3'd6) begin

        phase_seen_b[b_state] =
            1'b1;

    end
    else begin

        $display(
            "[FAIL] Invalid B state = %0d",
            b_state
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // No conflicting greens
    // --------------------------------------------------------

    safety_checks =
        safety_checks + 1;


    if (a_ns_green && a_ew_green) begin

        $display(
            "[FAIL] A NS and EW both GREEN"
        );

        errors =
            errors + 1;

    end


    if (b_ns_green && b_ew_green) begin

        $display(
            "[FAIL] B NS and EW both GREEN"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // Opposite direction must be RED
    // --------------------------------------------------------

    if (a_ns_green && !a_ew_red) begin

        $display(
            "[FAIL] A NS green without EW red"
        );

        errors =
            errors + 1;

    end


    if (a_ew_green && !a_ns_red) begin

        $display(
            "[FAIL] A EW green without NS red"
        );

        errors =
            errors + 1;

    end


    if (b_ns_green && !b_ew_red) begin

        $display(
            "[FAIL] B NS green without EW red"
        );

        errors =
            errors + 1;

    end


    if (b_ew_green && !b_ns_red) begin

        $display(
            "[FAIL] B EW green without NS red"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // Pedestrian safety
    // --------------------------------------------------------

    if (a_ped_active &&
        !(a_ns_red && a_ew_red)) begin

        $display(
            "[FAIL] A pedestrian phase without all-red"
        );

        errors =
            errors + 1;

    end


    if (b_ped_active &&
        !(b_ns_red && b_ew_red)) begin

        $display(
            "[FAIL] B pedestrian phase without all-red"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // Arbiter cannot grant both
    // --------------------------------------------------------

    if (grant_a && grant_b) begin

        $display(
            "[FAIL] Both pedestrian grants active"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // No direct green-to-green reversal
    // --------------------------------------------------------

    if ((previous_a_state == 3'd1) &&
        (a_state == 3'd3)) begin

        $display(
            "[FAIL] A NS Yellow directly to EW Green"
        );

        errors =
            errors + 1;

    end


    if ((previous_a_state == 3'd4) &&
        (a_state == 3'd0)) begin

        $display(
            "[FAIL] A EW Yellow directly to NS Green"
        );

        errors =
            errors + 1;

    end


    if ((previous_b_state == 3'd1) &&
        (b_state == 3'd3)) begin

        $display(
            "[FAIL] B NS Yellow directly to EW Green"
        );

        errors =
            errors + 1;

    end


    if ((previous_b_state == 3'd4) &&
        (b_state == 3'd0)) begin

        $display(
            "[FAIL] B EW Yellow directly to NS Green"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // Emergency safety
    // --------------------------------------------------------

    if (emergency_override) begin

        if (!(a_ns_red &&
              a_ew_red &&
              b_ns_red &&
              b_ew_red)) begin

            $display(
                "[FAIL] Emergency active but not all-red"
            );

            errors =
                errors + 1;

        end

    end


    // --------------------------------------------------------
    // Count pedestrian service
    // --------------------------------------------------------

    if (a_ped_active &&
        !previous_a_ped) begin

        pedestrian_services_a =
            pedestrian_services_a + 1;

    end


    if (b_ped_active &&
        !previous_b_ped) begin

        pedestrian_services_b =
            pedestrian_services_b + 1;

    end


    // --------------------------------------------------------
    // Save previous values
    // --------------------------------------------------------

    previous_a_ns_green =
        a_ns_green;

    previous_b_ns_green =
        b_ns_green;

    previous_a_ped =
        a_ped_active;

    previous_b_ped =
        b_ped_active;

    previous_a_state =
        a_state;

    previous_b_state =
        b_state;

end


// ============================================================
// WAIT FOR A STATE
// ============================================================

task wait_for_a_state;

input [2:0] required_state;
input integer maximum_cycles;

integer c;

begin

    c = 0;

    while ((a_state != required_state) &&
           (c < maximum_cycles)) begin

        @(posedge clk);
        #1;

        c = c + 1;

    end


    if (a_state != required_state) begin

        $display(
            "[FAIL] Timeout waiting for A state %0d",
            required_state
        );

        errors =
            errors + 1;

    end

end

endtask


// ============================================================
// WAIT FOR A PEDESTRIAN
// ============================================================

task wait_for_a_pedestrian;

input integer maximum_cycles;

integer c;

begin

    c = 0;

    while ((!a_ped_active) &&
           (c < maximum_cycles)) begin

        @(posedge clk);
        #1;

        c = c + 1;

    end


    if (!a_ped_active) begin

        $display(
            "[FAIL] Timeout waiting for A pedestrian"
        );

        errors =
            errors + 1;

    end

end

endtask


// ============================================================
// WAIT UNTIL PED SUBSYSTEM IS IDLE
// ============================================================

task wait_for_ped_idle;

input integer maximum_cycles;

integer c;

begin

    c = 0;

    while ((a_pending ||
            b_pending ||
            a_ped_active ||
            b_ped_active) &&
           (c < maximum_cycles)) begin

        @(posedge clk);
        #1;

        c = c + 1;

    end


    if (a_pending ||
        b_pending ||
        a_ped_active ||
        b_ped_active) begin

        $display(
            "[FAIL] Pedestrian subsystem timeout"
        );

        errors =
            errors + 1;

    end

end

endtask


// ============================================================
// SEND SIMULTANEOUS PEDESTRIAN REQUESTS
// ============================================================

task send_pedestrian_pair;

integer old_total;
integer c;

begin

    wait_for_ped_idle(200);


    old_total =
        pedestrian_services_a +
        pedestrian_services_b;


    // Pulse both requests for one clock.
    @(negedge clk);

    ped_a = 1'b1;
    ped_b = 1'b1;

    @(negedge clk);

    ped_a = 1'b0;
    ped_b = 1'b0;


    pedestrian_requests =
        pedestrian_requests + 2;


    // Wait until two new pedestrian services occur.
    c = 0;

    while (((pedestrian_services_a +
             pedestrian_services_b) <
             (old_total + 2)) &&
           (c < 200)) begin

        @(negedge clk);

        c = c + 1;

    end


    if ((pedestrian_services_a +
         pedestrian_services_b) <
        (old_total + 2)) begin

        $display(
            "[FAIL] Pedestrian requests were not both serviced"
        );

        errors =
            errors + 1;

    end


    wait_for_ped_idle(200);

end

endtask


// ============================================================
// DENSITY SWEEP
// ============================================================

task density_sweep;

integer d;
integer expected_a;
integer expected_b;

begin

    $display("");
    $display(
        "========== DENSITY SWEEP =========="
    );


    for (d = 0; d < 8; d = d + 1) begin


        reset = 1'b1;

        a_density = d[2:0];
        b_density = d[2:0];

        ped_a = 1'b0;
        ped_b = 1'b0;

        emergency_override = 1'b0;

        @(posedge clk);

        reset = 1'b0;


        // Calculate expected A value.
        expected_a =
            A_GREEN_TIME_P +
            d * A_EXT_P;


        if (expected_a < A_MIN_P)
            expected_a =
                A_MIN_P;

        else if (expected_a > A_MAX_P)
            expected_a =
                A_MAX_P;


        // Calculate expected B value.
        expected_b =
            B_GREEN_TIME_P +
            d * B_EXT_P;


        if (expected_b < B_MIN_P)
            expected_b =
                B_MIN_P;

        else if (expected_b > B_MAX_P)
            expected_b =
                B_MAX_P;


        wait_for_a_state(
            3'd0,
            150
        );

        #1;


        if (a_timer_target ==
            expected_a) begin

            $display(
                "[PASS] Density %0d A target=%0d",
                d,
                a_timer_target
            );

        end
        else begin

            $display(
                "[FAIL] Density %0d A target=%0d expected=%0d",
                d,
                a_timer_target,
                expected_a
            );

            errors =
                errors + 1;

        end


        wait_for_a_state(
            3'd3,
            150
        );

        #1;


        if (a_timer_target ==
            expected_a) begin

            $display(
                "[PASS] Density %0d A EW target=%0d",
                d,
                a_timer_target
            );

        end
        else begin

            $display(
                "[FAIL] Density %0d A EW target=%0d expected=%0d",
                d,
                a_timer_target,
                expected_a
            );

            errors =
                errors + 1;

        end


        density_tests =
            density_tests + 1;

    end

end

endtask


// ============================================================
// MID-GREEN DENSITY TEST
// ============================================================

task mid_green_density_test;

integer original_target;

begin

    $display("");
    $display(
        "========== MID-GREEN DENSITY =========="
    );


    reset = 1'b1;

    a_density = 3'd1;
    b_density = 3'd1;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    wait_for_a_state(
        3'd0,
        150
    );

    #1;


    original_target =
        a_timer_target;


    $display(
        "Initial A green target = %0d",
        original_target
    );


    // Change density while green is active.
    @(negedge clk);

    a_density = 3'd7;
    b_density = 3'd7;


    repeat (2)
        @(posedge clk);

    #1;


    if (!a_ns_green) begin

        $display(
            "[FAIL] A left green unexpectedly during mid-green test"
        );

        errors =
            errors + 1;

    end
    else if (a_timer_target !=
             original_target) begin

        $display(
            "[FAIL] Active green target changed during green"
        );

        errors =
            errors + 1;

    end
    else begin

        $display(
            "[PASS] Density held constant during active green"
        );

    end


    // Wait for next NS green.
    wait (a_ns_green == 1'b0);

    wait (a_ns_green == 1'b1);

    #1;


    if (a_timer_target ==
        A_MAX_P) begin

        $display(
            "[PASS] New density applied at next green"
        );

    end
    else begin

        $display(
            "[FAIL] New density not applied at next green"
        );

        errors =
            errors + 1;

    end

end

endtask


// ============================================================
// MAXIMUM DENSITY TEST
// ============================================================

task maximum_density_test;

begin

    $display("");
    $display(
        "========== MAXIMUM DENSITY =========="
    );


    reset = 1'b1;

    a_density = 3'd7;
    b_density = 3'd7;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    wait_for_a_state(
        3'd0,
        150
    );

    #1;


    if (a_timer_target ==
        A_MAX_P) begin

        $display(
            "[PASS] Density 7 clamped to A MAX=%0d",
            a_timer_target
        );

    end
    else begin

        $display(
            "[FAIL] Density 7 A target=%0d expected=%0d",
            a_timer_target,
            A_MAX_P
        );

        errors =
            errors + 1;

    end

end

endtask


// ============================================================
// GREEN WAVE TEST
// ============================================================

task green_wave_test;

input [2:0] da;
input [2:0] db;
input integer test_number;

integer a_start_cycle;
integer b_start_cycle;
integer offset;
integer c;

begin

    $display("");
    $display(
        "========== GREEN WAVE TEST %0d ==========",
        test_number
    );

    $display(
        "A density=%0d B density=%0d",
        da,
        db
    );


    reset = 1'b1;

    a_density = da;
    b_density = db;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    wait_for_a_state(
        3'd0,
        150
    );

    #1;


    a_start_cycle =
        simulation_cycles;


    c = 0;


    while ((!b_ns_green) &&
           (c < 100)) begin

        @(posedge clk);
        #1;

        c = c + 1;

    end


    if (!b_ns_green) begin

        $display(
            "[FAIL] B did not reach NS green"
        );

        errors =
            errors + 1;

    end
    else begin

        b_start_cycle =
            simulation_cycles;


        offset =
            b_start_cycle -
            a_start_cycle;


        $display(
            "A NS green cycle = %0d",
            a_start_cycle
        );

        $display(
            "B NS green cycle = %0d",
            b_start_cycle
        );

        $display(
            "Measured wave offset = %0d cycles",
            offset
        );


        wave_tests =
            wave_tests + 1;


        // Documented tolerance: 2 to 3 cycles.
        if ((offset >= WAVE_DELAY_P) &&
            (offset <= WAVE_DELAY_P + 1)) begin

            $display(
                "[PASS] Green-wave test %0d",
                test_number
            );

        end
        else begin

            $display(
                "[FAIL] Green-wave offset outside tolerance"
            );

            errors =
                errors + 1;

        end

    end

end

endtask


// ============================================================
// EMERGENCY TEST
//
// State mapping:
// 0 = NS GREEN
// 1 = NS YELLOW
// 2 = ALL RED TO EW
// 3 = EW GREEN
// 4 = EW YELLOW
// 5 = ALL RED TO NS
// 6 = PEDESTRIAN
// ============================================================

task emergency_test;

input [2:0] state_to_test;

integer c;

begin

    $display("");
    $display(
        "========== EMERGENCY STATE %0d ==========",
        state_to_test
    );


    reset = 1'b1;

    a_density = 3'd2;
    b_density = 3'd2;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    if (state_to_test == 3'd6) begin

        // Request pedestrian.
        @(negedge clk);

        ped_a = 1'b1;

        @(negedge clk);

        ped_a = 1'b0;


        wait_for_a_pedestrian(200);

    end
    else begin

        wait_for_a_state(
            state_to_test,
            150
        );

    end


    // Assert emergency.
    @(negedge clk);

    emergency_override = 1'b1;


    // One full cycle allowed for response.
    @(negedge clk);


    if (a_ns_red &&
        a_ew_red &&
        b_ns_red &&
        b_ew_red) begin

        $display(
            "[PASS] Emergency state %0d -> all-red",
            state_to_test
        );

    end
    else begin

        $display(
            "[FAIL] Emergency state %0d did not force all-red",
            state_to_test
        );

        errors =
            errors + 1;

    end


    emergency_tests =
        emergency_tests + 1;


    // Emergency must remain all-red.
    repeat (2) begin

        @(negedge clk);

        if (!(a_ns_red &&
              a_ew_red &&
              b_ns_red &&
              b_ew_red)) begin

            $display(
                "[FAIL] Emergency all-red hold failed"
            );

            errors =
                errors + 1;

        end

    end


    emergency_override = 1'b0;


    // Allow safe recovery.
    c = 0;

    while ((a_state != 3'd0) &&
           (c < 150)) begin

        @(posedge clk);
        #1;

        c = c + 1;

    end


    if (a_state == 3'd0)

        $display(
            "[PASS] Emergency safe recovery"
        );
    else begin

        $display(
            "[FAIL] Emergency recovery timeout"
        );

        errors =
            errors + 1;

    end

end

endtask


// ============================================================
// REPEATED EMERGENCY
// ============================================================

task repeated_emergency_test;

integer n;

begin

    $display("");
    $display(
        "========== REPEATED EMERGENCY =========="
    );


    reset = 1'b1;

    a_density = 3'd1;
    b_density = 3'd1;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    wait_for_a_state(
        3'd0,
        150
    );


    for (n = 0; n < 5; n = n + 1) begin

        @(negedge clk);

        emergency_override = 1'b1;


        @(negedge clk);

        if (!(a_ns_red &&
              a_ew_red &&
              b_ns_red &&
              b_ew_red)) begin

            $display(
                "[FAIL] Repeated emergency %0d failed",
                n + 1
            );

            errors =
                errors + 1;

        end
        else begin

            $display(
                "[PASS] Repeated emergency %0d",
                n + 1
            );

        end


        // Immediately deassert.
        emergency_override = 1'b0;


        repeated_emergency_tests =
            repeated_emergency_tests + 1;


        // Allow normal state movement.
        repeat (2)
            @(posedge clk);

    end

end

endtask


// ============================================================
// ACTIVE RESET
// ============================================================

task active_reset_test;

begin

    $display("");
    $display(
        "========== ACTIVE RESET TEST =========="
    );


    reset = 1'b1;

    a_density = 3'd3;
    b_density = 3'd4;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    // Wait until traffic is active.
    wait_for_a_state(
        3'd3,
        150
    );


    // Reset while EW green is active.
    @(negedge clk);

    reset = 1'b1;


    @(posedge clk);

    #1;


    if (a_ns_red &&
        a_ew_red &&
        b_ns_red &&
        b_ew_red) begin

        $display(
            "[PASS] Active reset forced safe all-red"
        );

    end
    else begin

        $display(
            "[FAIL] Active reset did not force safe state"
        );

        errors =
            errors + 1;

    end


    active_reset_tests =
        active_reset_tests + 1;


    reset = 1'b0;


    // Recovery.
    wait_for_a_state(
        3'd0,
        150
    );

    $display(
        "[PASS] Recovery after active reset"
    );

end

endtask


// ============================================================
// RANDOMIZED TEST
// ============================================================

task randomized_test;

integer n;
integer r1;
integer r2;
integer r3;

begin

    $display("");
    $display(
        "========== RANDOMIZED TEST =========="
    );

    $display(
        "Randomized cycles = %0d",
        RANDOM_CYCLES
    );


    reset = 1'b1;

    a_density = 3'd0;
    b_density = 3'd0;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    for (n = 0;
         n < RANDOM_CYCLES;
         n = n + 1) begin


        @(negedge clk);


        r1 = $random;
        r2 = $random;
        r3 = $random;


        // Random density.
        a_density =
            r1 & 3'b111;

        b_density =
            r2 & 3'b111;


        // Random pedestrian request.
        if ((r1 & 8'h0F) == 0)

            ped_a = 1'b1;

        else

            ped_a = 1'b0;


        if ((r2 & 8'h0F) == 0)

            ped_b = 1'b1;

        else

            ped_b = 1'b0;


        // Random emergency.
        if ((r3 & 8'h1F) == 0)

            emergency_override =
                1'b1;

        else

            emergency_override =
                1'b0;


        @(posedge clk);

        #1;


        random_cycles_done =
            random_cycles_done + 1;

    end


    @(negedge clk);

    ped_a = 1'b0;
    ped_b = 1'b0;
    emergency_override = 1'b0;


    $display(
        "[PASS] Randomized stimulus completed"
    );

end

endtask


// ============================================================
// MAIN TEST
// ============================================================

integer i;

initial begin


    // --------------------------------------------------------
    // Initialize
    // --------------------------------------------------------

    errors = 0;

    simulation_cycles = 0;

    safety_checks = 0;

    density_tests = 0;

    pedestrian_requests = 0;

    pedestrian_services_a = 0;
    pedestrian_services_b = 0;

    emergency_tests = 0;

    repeated_emergency_tests = 0;

    active_reset_tests = 0;

    wave_tests = 0;

    random_cycles_done = 0;


    previous_a_ns_green = 1'b0;
    previous_b_ns_green = 1'b0;

    previous_a_ped = 1'b0;
    previous_b_ped = 1'b0;

    previous_a_state = 3'd5;
    previous_b_state = 3'd5;


    phase_seen_a = 7'b0000000;
    phase_seen_b = 7'b0000000;


    reset = 1'b1;
    emergency_override = 1'b0;

    a_density = 3'd0;
    b_density = 3'd0;

    ped_a = 1'b0;
    ped_b = 1'b0;


    // Initial reset.
    repeat (2)
        @(posedge clk);

    reset = 1'b0;


    $display("");
    $display(
        "================================================"
    );

    $display(
        "AMTGC TASK 5"
    );

    $display(
        "UNIFIED SELF-CHECKING VERIFICATION"
    );

    $display(
        "================================================"
    );


    // --------------------------------------------------------
    // 1. NORMAL TRAFFIC SEQUENCE
    // --------------------------------------------------------

    $display("");
    $display(
        "========== NORMAL TRAFFIC =========="
    );


    wait_for_a_state(
        3'd0,
        150
    );

    wait_for_a_state(
        3'd1,
        150
    );

    wait_for_a_state(
        3'd2,
        150
    );

    wait_for_a_state(
        3'd3,
        150
    );

    wait_for_a_state(
        3'd4,
        150
    );

    wait_for_a_state(
        3'd5,
        150
    );


    $display(
        "[PASS] Normal traffic sequence observed"
    );


    // --------------------------------------------------------
    // 2. PEDESTRIAN TEST
    // --------------------------------------------------------

    @(negedge clk);

    ped_a = 1'b1;

    @(negedge clk);

    ped_a = 1'b0;


    wait_for_a_pedestrian(200);


    if (a_ns_red &&
        a_ew_red) begin

        $display(
            "[PASS] Pedestrian phase has all vehicle RED"
        );

    end
    else begin

        $display(
            "[FAIL] Pedestrian phase safety failure"
        );

        errors =
            errors + 1;

    end


    wait_for_ped_idle(200);


    // --------------------------------------------------------
    // 3. DENSITY SWEEP
    // --------------------------------------------------------

    density_sweep;


    // --------------------------------------------------------
    // 4. MID-GREEN DENSITY
    // --------------------------------------------------------

    mid_green_density_test;


    // --------------------------------------------------------
    // 5. MAXIMUM DENSITY
    // --------------------------------------------------------

    maximum_density_test;


    // --------------------------------------------------------
    // 6. PEDESTRIAN FAIRNESS
    // --------------------------------------------------------

    $display("");
    $display(
        "========== PEDESTRIAN FAIRNESS =========="
    );

    $display(
        "Sending %0d simultaneous rounds = 120 requests",
        PED_ROUNDS
    );


    reset = 1'b1;

    a_density = 3'd2;
    b_density = 3'd2;

    ped_a = 1'b0;
    ped_b = 1'b0;

    emergency_override = 1'b0;


    @(posedge clk);

    reset = 1'b0;


    for (i = 0;
         i < PED_ROUNDS;
         i = i + 1) begin

        send_pedestrian_pair;

    end


    $display(
        "Requests issued = %0d",
        pedestrian_requests
    );

    $display(
        "Services A = %0d",
        pedestrian_services_a
    );

    $display(
        "Services B = %0d",
        pedestrian_services_b
    );


    if (pedestrian_requests > 100)

        $display(
            "[PASS] More than 100 pedestrian requests tested"
        );

    else begin

        $display(
            "[FAIL] Request count is not greater than 100"
        );

        errors =
            errors + 1;

    end


    if ((pedestrian_services_a +
         pedestrian_services_b) >=
        pedestrian_requests)

        $display(
            "[PASS] All pedestrian requests serviced"
        );

    else begin

        $display(
            "[FAIL] Some pedestrian requests were not serviced"
        );

        errors =
            errors + 1;

    end


    if (((pedestrian_services_a -
          pedestrian_services_b) <= 1) &&
        ((pedestrian_services_b -
          pedestrian_services_a) <= 1))

        $display(
            "[PASS] Pedestrian arbitration is fair"
        );

    else begin

        $display(
            "[FAIL] Pedestrian arbitration imbalance"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // 7. GREEN WAVE
    // --------------------------------------------------------

    green_wave_test(
        3'd0,
        3'd7,
        1
    );

    green_wave_test(
        3'd1,
        3'd6,
        2
    );

    green_wave_test(
        3'd2,
        3'd5,
        3
    );

    green_wave_test(
        3'd4,
        3'd3,
        4
    );

    green_wave_test(
        3'd7,
        3'd0,
        5
    );


    if (wave_tests >= 5)

        $display(
            "[PASS] Five green-wave combinations tested"
        );

    else begin

        $display(
            "[FAIL] Less than five green-wave tests"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // 8. EMERGENCY IN ALL SEVEN STATES
    // --------------------------------------------------------

    emergency_test(3'd0);

    emergency_test(3'd1);

    emergency_test(3'd2);

    emergency_test(3'd3);

    emergency_test(3'd4);

    emergency_test(3'd5);

    emergency_test(3'd6);


    if (emergency_tests == 7)

        $display(
            "[PASS] Emergency tested in all 7 states"
        );

    else begin

        $display(
            "[FAIL] Emergency state coverage incomplete"
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // 9. REPEATED EMERGENCY
    // --------------------------------------------------------

    repeated_emergency_test;


    // --------------------------------------------------------
    // 10. ACTIVE RESET
    // --------------------------------------------------------

    active_reset_test;


    // --------------------------------------------------------
    // 11. RANDOMIZED TEST
    // --------------------------------------------------------

    randomized_test;


    // --------------------------------------------------------
    // 12. PHASE COVERAGE
    // --------------------------------------------------------

    if (phase_seen_a ==
        7'b1111111)

        $display(
            "[PASS] Junction A all 7 states covered"
        );

    else begin

        $display(
            "[FAIL] Junction A phase coverage = %b",
            phase_seen_a
        );

        errors =
            errors + 1;

    end


    if (phase_seen_b ==
        7'b1111111)

        $display(
            "[PASS] Junction B all 7 states covered"
        );

    else begin

        $display(
            "[FAIL] Junction B phase coverage = %b",
            phase_seen_b
        );

        errors =
            errors + 1;

    end


    // --------------------------------------------------------
    // FINAL SUMMARY
    // --------------------------------------------------------

    $display("");
    $display(
        "================================================"
    );

    $display(
        "AMTGC TASK 5 FINAL VERIFICATION SUMMARY"
    );

    $display(
        "================================================"
    );


    $display(
        "Simulation cycles       = %0d",
        simulation_cycles
    );

    $display(
        "Safety checks           = %0d",
        safety_checks
    );

    $display(
        "Density tests           = %0d / 8",
        density_tests
    );

    $display(
        "Pedestrian requests     = %0d",
        pedestrian_requests
    );

    $display(
        "Pedestrian services A   = %0d",
        pedestrian_services_a
    );

    $display(
        "Pedestrian services B   = %0d",
        pedestrian_services_b
    );

    $display(
        "Green-wave tests        = %0d / 5",
        wave_tests
    );

    $display(
        "Emergency tests         = %0d / 7",
        emergency_tests
    );

    $display(
        "Repeated emergency     = %0d",
        repeated_emergency_tests
    );

    $display(
        "Active reset tests      = %0d",
        active_reset_tests
    );

    $display(
        "Randomized cycles       = %0d / %0d",
        random_cycles_done,
        RANDOM_CYCLES
    );

    $display(
        "Total errors            = %0d",
        errors
    );


    $display(
        "================================================"
    );


    if (errors == 0) begin

        $display(
            "PASS: AMTGC TASK 5 SELF-CHECKING VERIFICATION"
        );

    end
    else begin

        $display(
            "FAIL: AMTGC TASK 5 SELF-CHECKING VERIFICATION"
        );

    end


    $display(
        "================================================"
    );


    #20;

    $finish;

end

endmodule
