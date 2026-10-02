`timescale 1ns/1ps

module amtgc_task4_tb;

    // ========================================================
    // Test configuration
    // ========================================================

    localparam integer GREEN_TIME     = 5;
    localparam integer MIN_GREEN_TIME = 4;
    localparam integer MAX_GREEN_TIME = 8;
    localparam integer GREEN_EXTENSION = 1;

    localparam integer YELLOW_TIME = 2;
    localparam integer RED_TIME    = 2;
    localparam integer PED_TIME_A  = 2;
    localparam integer PED_TIME_B  = 3;

    localparam integer COUNTER_WIDTH = 8;
    localparam integer WAVE_DELAY    = 1;

    // ========================================================
    // Inputs
    // ========================================================

    reg clk;
    reg reset;
    reg emergency_override;

    reg [2:0] a_traffic_density;
    reg [2:0] b_traffic_density;

    reg a_pedestrian_request;
    reg b_pedestrian_request;

    // ========================================================
    // Outputs
    // ========================================================

    wire a_ns_red;
    wire a_ns_yellow;
    wire a_ns_green;

    wire a_ew_red;
    wire a_ew_yellow;
    wire a_ew_green;

    wire b_ns_red;
    wire b_ns_yellow;
    wire b_ns_green;

    wire b_ew_red;
    wire b_ew_yellow;
    wire b_ew_green;

    wire a_pedestrian_active;
    wire b_pedestrian_active;

    wire [2:0] a_state;
    wire [2:0] b_state;

    wire [COUNTER_WIDTH-1:0] a_timer_target;
    wire [COUNTER_WIDTH-1:0] b_timer_target;

    wire a_ped_pending;
    wire b_ped_pending;

    wire ped_grant_a;
    wire ped_grant_b;

    wire green_wave_start_b;

    // ========================================================
    // Test variables
    // ========================================================

    integer errors;
    integer density;
    integer expected_target;

    integer a_green_start;
    integer a_green_end;
    integer a_green_duration;

    integer b_green_start;
    integer b_green_end;
    integer b_green_duration;

    integer wave_offset;

    integer case_number;

    reg a_seen_green;
    reg b_seen_green;

    // ========================================================
    // State codes
    // ========================================================

    localparam [2:0] S_NS_GREEN      = 3'b000;
    localparam [2:0] S_NS_YELLOW     = 3'b001;
    localparam [2:0] S_ALL_RED_TO_EW = 3'b010;
    localparam [2:0] S_EW_GREEN      = 3'b011;
    localparam [2:0] S_EW_YELLOW     = 3'b100;
    localparam [2:0] S_ALL_RED_TO_NS = 3'b101;
    localparam [2:0] S_PEDESTRIAN    = 3'b110;

    // ========================================================
    // DUT
    // ========================================================

    amtgc_top #(
        .A_GREEN_TIME(
            GREEN_TIME
        ),

        .A_MIN_GREEN_TIME(
            MIN_GREEN_TIME
        ),

        .A_MAX_GREEN_TIME(
            MAX_GREEN_TIME
        ),

        .A_GREEN_EXTENSION_PER_LEVEL(
            GREEN_EXTENSION
        ),

        .A_YELLOW_TIME(
            YELLOW_TIME
        ),

        .A_RED_TIME(
            RED_TIME
        ),

        .A_PED_TIME(
            PED_TIME_A
        ),

        .B_GREEN_TIME(
            GREEN_TIME
        ),

        .B_MIN_GREEN_TIME(
            MIN_GREEN_TIME
        ),

        .B_MAX_GREEN_TIME(
            MAX_GREEN_TIME
        ),

        .B_GREEN_EXTENSION_PER_LEVEL(
            GREEN_EXTENSION
        ),

        .B_YELLOW_TIME(
            YELLOW_TIME
        ),

        .B_RED_TIME(
            RED_TIME
        ),

        .B_PED_TIME(
            PED_TIME_B
        ),

        .COUNTER_WIDTH(
            COUNTER_WIDTH
        ),

        .GREEN_WAVE_DELAY(
            WAVE_DELAY
        )
    ) dut (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

        .a_traffic_density(a_traffic_density),
        .b_traffic_density(b_traffic_density),

        .a_pedestrian_request(a_pedestrian_request),
        .b_pedestrian_request(b_pedestrian_request),

        .a_ns_red(a_ns_red),
        .a_ns_yellow(a_ns_yellow),
        .a_ns_green(a_ns_green),

        .a_ew_red(a_ew_red),
        .a_ew_yellow(a_ew_yellow),
        .a_ew_green(a_ew_green),

        .b_ns_red(b_ns_red),
        .b_ns_yellow(b_ns_yellow),
        .b_ns_green(b_ns_green),

        .b_ew_red(b_ew_red),
        .b_ew_yellow(b_ew_yellow),
        .b_ew_green(b_ew_green),

        .a_pedestrian_active(
            a_pedestrian_active
        ),

        .b_pedestrian_active(
            b_pedestrian_active
        ),

        .a_state(a_state),
        .b_state(b_state),

        .a_timer_target(
            a_timer_target
        ),

        .b_timer_target(
            b_timer_target
        ),

        .a_ped_pending(
            a_ped_pending
        ),

        .b_ped_pending(
            b_ped_pending
        ),

        .ped_grant_a(
            ped_grant_a
        ),

        .ped_grant_b(
            ped_grant_b
        ),

        .green_wave_start_b(
            green_wave_start_b
        )
    );

    // ========================================================
    // Clock
    // ========================================================

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end

    // ========================================================
    // Basic safety checker
    // ========================================================

    always @(posedge clk) begin

        #1;

        if (!reset) begin

            // No conflicting greens.
            if (a_ns_green &&
                a_ew_green) begin

                $display(
                    "ERROR: A NS and EW green together"
                );

                errors = errors + 1;

            end

            if (b_ns_green &&
                b_ew_green) begin

                $display(
                    "ERROR: B NS and EW green together"
                );

                errors = errors + 1;

            end

            // Pedestrian means vehicle all-red.
            if (a_pedestrian_active &&
                (!a_ns_red || !a_ew_red)) begin

                $display(
                    "ERROR: A pedestrian phase not all-red"
                );

                errors = errors + 1;

            end

            if (b_pedestrian_active &&
                (!b_ns_red || !b_ew_red)) begin

                $display(
                    "ERROR: B pedestrian phase not all-red"
                );

                errors = errors + 1;

            end

            // Timer target must remain within safety limits
            // during green.
            if (a_ns_green &&
                ((a_timer_target < MIN_GREEN_TIME) ||
                 (a_timer_target > MAX_GREEN_TIME))) begin

                $display(
                    "ERROR: A NS target outside limits"
                );

                errors = errors + 1;

            end

            if (a_ew_green &&
                ((a_timer_target < MIN_GREEN_TIME) ||
                 (a_timer_target > MAX_GREEN_TIME))) begin

                $display(
                    "ERROR: A EW target outside limits"
                );

                errors = errors + 1;

            end

            if (b_ns_green &&
                ((b_timer_target < MIN_GREEN_TIME) ||
                 (b_timer_target > MAX_GREEN_TIME))) begin

                $display(
                    "ERROR: B NS target outside limits"
                );

                errors = errors + 1;

            end

            if (b_ew_green &&
                ((b_timer_target < MIN_GREEN_TIME) ||
                 (b_timer_target > MAX_GREEN_TIME))) begin

                $display(
                    "ERROR: B EW target outside limits"
                );

                errors = errors + 1;

            end

        end

    end

    // ========================================================
    // Main test
    // ========================================================

    initial begin

        errors = 0;

        emergency_override = 1'b0;

        a_pedestrian_request = 1'b0;
        b_pedestrian_request = 1'b0;

        a_traffic_density = 3'b000;
        b_traffic_density = 3'b000;

        a_seen_green = 1'b0;
        b_seen_green = 1'b0;

        a_green_start = -1;
        a_green_end = -1;

        b_green_start = -1;
        b_green_end = -1;

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        reset = 1'b1;

        repeat (3)
            @(posedge clk);

        reset = 1'b0;

        $display("");
        $display("================================================");
        $display("AMTGC TASK 4 ADAPTIVE TIMING TEST");
        $display("================================================");
        $display("");

        // ====================================================
        // DENSITY SWEEP
        // Each possible 3-bit value is tested.
        // ====================================================

        for (density = 0;
             density <= 7;
             density = density + 1) begin

            // Reset before every density case so the
            // first NS green uses the selected density.
            reset = 1'b1;

            a_traffic_density = density;
            b_traffic_density = density;

            repeat (2)
                @(posedge clk);

            reset = 1'b0;

            // Expected target.
            expected_target =
                GREEN_TIME +
                (density * GREEN_EXTENSION);

            if (expected_target < MIN_GREEN_TIME)
                expected_target = MIN_GREEN_TIME;

            if (expected_target > MAX_GREEN_TIME)
                expected_target = MAX_GREEN_TIME;

            // Wait for A NS green.
            wait (a_state == S_NS_GREEN);
            #1;

            // ------------------------------------------------
            // Target check
            // ------------------------------------------------

            if (a_timer_target !== expected_target) begin

                $display(
                    "ERROR: Density=%0d A target=%0d expected=%0d",
                    density,
                    a_timer_target,
                    expected_target
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS: Density=%0d A NS target=%0d",
                    density,
                    a_timer_target
                );

            end

            // B target is also checked when it enters NS green.
            wait (b_state == S_NS_GREEN);
            #1;

            if (b_timer_target !== expected_target) begin

                $display(
                    "ERROR: Density=%0d B target=%0d expected=%0d",
                    density,
                    b_timer_target,
                    expected_target
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS: Density=%0d B NS target=%0d",
                    density,
                    b_timer_target
                );

            end

            // ------------------------------------------------
            // Check the actual A green duration.
            //
            // The generic_timer generates a registered count
            // progression, so the observed FSM interval is
            // expected to be target + one clock period.
            // ------------------------------------------------

            a_green_start = $time;

            while (a_state == S_NS_GREEN) begin

                @(posedge clk);
                #1;

            end

            a_green_end = $time;

            a_green_duration =
                (a_green_end -
                 a_green_start) / 10;

            if (a_green_duration !=
                (expected_target + 1)) begin

                $display(
                    "ERROR: Density=%0d A green duration=%0d expected=%0d",
                    density,
                    a_green_duration,
                    expected_target + 1
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS: Density=%0d A green duration=%0d cycles",
                    density,
                    a_green_duration
                );

            end

        end

        // ====================================================
        // Mid-phase density-change test
        // ====================================================

        $display("");
        $display("Testing density change during active green...");

        reset = 1'b1;

        a_traffic_density = 3'd1;
        b_traffic_density = 3'd1;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;

        wait (a_state == S_NS_GREEN);
        #1;

        // Density 1 should initially produce target 6.
        if (a_timer_target !== 6) begin

            $display(
                "ERROR: Initial adaptive target is incorrect"
            );

            errors = errors + 1;

        end

        // Change density to maximum while green is active.
        a_traffic_density = 3'd7;

        // Give enough time for the controller to continue.
        repeat (2)
            @(posedge clk);

        #1;

        // Target should still be the original sampled value.
        if (a_timer_target !== 6) begin

            $display(
                "ERROR: Active green target changed mid-phase"
            );

            errors = errors + 1;

        end
        else begin

            $display(
                "PASS: Density change during green does not alter active target"
            );

        end

        // ====================================================
        // Maximum density test
        // ====================================================

        $display("");
        $display("Testing maximum density safety cap...");

        reset = 1'b1;

        a_traffic_density = 3'd7;
        b_traffic_density = 3'd7;

        repeat (2)
            @(posedge clk);

        reset = 1'b0;

        wait (a_state == S_NS_GREEN);
        #1;

        if (a_timer_target !== MAX_GREEN_TIME) begin

            $display(
                "ERROR: Maximum density did not reach safety cap"
            );

            errors = errors + 1;

        end
        else begin

            $display(
                "PASS: Maximum density is capped at %0d",
                MAX_GREEN_TIME
            );

        end

        // ====================================================
        // Green-wave density combinations
        //
        // Each case starts from reset, so the first A and B
        // NS-green events are measured under the selected
        // traffic-density combination.
        // ====================================================

        $display("");
        $display("Testing green-wave under multiple density combinations...");

        for (case_number = 0;
             case_number < 5;
             case_number = case_number + 1) begin

            reset = 1'b1;

            case (case_number)

                0: begin
                    a_traffic_density = 3'd0;
                    b_traffic_density = 3'd7;
                end

                1: begin
                    a_traffic_density = 3'd1;
                    b_traffic_density = 3'd6;
                end

                2: begin
                    a_traffic_density = 3'd2;
                    b_traffic_density = 3'd5;
                end

                3: begin
                    a_traffic_density = 3'd4;
                    b_traffic_density = 3'd3;
                end

                4: begin
                    a_traffic_density = 3'd7;
                    b_traffic_density = 3'd0;
                end

                default: begin
                    a_traffic_density = 3'd0;
                    b_traffic_density = 3'd0;
                end

            endcase

            repeat (2)
                @(posedge clk);

            reset = 1'b0;

            wait (a_state == S_NS_GREEN);

            a_green_start = $time;

            wait (b_state == S_NS_GREEN);

            b_green_start = $time;

            wave_offset =
                (b_green_start -
                 a_green_start) / 10;

            $display(
                "Wave test %0d: A density=%0d, B density=%0d, offset=%0d cycles",
                case_number + 1,
                a_traffic_density,
                b_traffic_density,
                wave_offset
            );

            // The exact registered implementation introduces
            // clock quantization. The result is therefore
            // checked against a bounded 1-to-3-cycle response
            // for the configured one-cycle wave request.
            if ((wave_offset < 1) ||
                (wave_offset > 3)) begin

                $display(
                    "ERROR: Green-wave offset outside documented tolerance"
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS: Green-wave offset within documented tolerance"
                );

            end

        end

        // ====================================================
        // Final result
        // ====================================================

        $display("");
        $display("================================================");

        if (errors == 0) begin

            $display(
                "PASS: amtgc_task4_tb completed with 0 errors"
            );

        end
        else begin

            $display(
                "FAIL: amtgc_task4_tb found %0d errors",
                errors
            );

        end

        $display("================================================");
        $display("");

        $finish;

    end

endmodule