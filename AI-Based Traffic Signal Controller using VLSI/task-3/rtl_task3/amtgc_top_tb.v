`timescale 1ns/1ps

module amtgc_top_tb;

    // --------------------------------------------------------
    // Inputs
    // --------------------------------------------------------

    reg clk;
    reg reset;
    reg emergency_override;

    reg a_pedestrian_request;
    reg b_pedestrian_request;

    // --------------------------------------------------------
    // Outputs
    // --------------------------------------------------------

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

    wire [7:0] a_timer_target;
    wire [7:0] b_timer_target;

    wire a_ped_pending;
    wire b_ped_pending;

    wire ped_grant_a;
    wire ped_grant_b;

    wire green_wave_start_b;

    // --------------------------------------------------------
    // Test variables
    // --------------------------------------------------------

    integer errors;

    integer a_green_start_time;
    integer b_green_start_time;

    integer wave_offset;

    integer first_ped_junction;
    integer second_ped_junction;

    integer a_ped_count;
    integer b_ped_count;

    reg previous_a_ns_green;
    reg previous_b_ns_green;

    reg previous_a_ped;
    reg previous_b_ped;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    amtgc_top #(
        .A_GREEN_TIME(6),
        .A_YELLOW_TIME(2),
        .A_RED_TIME(2),
        .A_PED_TIME(2),

        .B_GREEN_TIME(6),
        .B_YELLOW_TIME(2),
        .B_RED_TIME(2),
        .B_PED_TIME(3),

        .COUNTER_WIDTH(8),
        .GREEN_WAVE_DELAY(1)
    ) dut (
        .clk(clk),
        .reset(reset),
        .emergency_override(emergency_override),

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

        .a_pedestrian_active(a_pedestrian_active),
        .b_pedestrian_active(b_pedestrian_active),

        .a_state(a_state),
        .b_state(b_state),

        .a_timer_target(a_timer_target),
        .b_timer_target(b_timer_target),

        .a_ped_pending(a_ped_pending),
        .b_ped_pending(b_ped_pending),

        .ped_grant_a(ped_grant_a),
        .ped_grant_b(ped_grant_b),

        .green_wave_start_b(green_wave_start_b)
    );

    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end

    // --------------------------------------------------------
    // Rising-edge event monitor
    // --------------------------------------------------------

    always @(posedge clk) begin

        #1;

        // --------------------------------------------
        // Green-wave measurement
        // --------------------------------------------

        if (!previous_a_ns_green &&
            a_ns_green) begin

            a_green_start_time = $time;

            $display("A NS GREEN started at %0t ns",
                     $time);

        end

        if (!previous_b_ns_green &&
            b_ns_green) begin

            b_green_start_time = $time;

            $display("B NS GREEN started at %0t ns",
                     $time);

            if (a_green_start_time >= 0) begin

                wave_offset =
                    (b_green_start_time -
                     a_green_start_time) / 10;

                $display("Measured A->B NS green offset = %0d clock cycles",
                         wave_offset);

            end

        end

        // --------------------------------------------
        // Pedestrian service count
        // --------------------------------------------

        if (!previous_a_ped &&
            a_pedestrian_active) begin

            a_ped_count = a_ped_count + 1;

            $display("Pedestrian service at Junction A");

        end

        if (!previous_b_ped &&
            b_pedestrian_active) begin

            b_ped_count = b_ped_count + 1;

            $display("Pedestrian service at Junction B");

        end

        previous_a_ns_green = a_ns_green;
        previous_b_ns_green = b_ns_green;

        previous_a_ped = a_pedestrian_active;
        previous_b_ped = b_pedestrian_active;

    end

    // --------------------------------------------------------
    // Safety checks
    // --------------------------------------------------------

    always @(posedge clk) begin

        #1;

        if (!reset) begin

            // Conflicting greens
            if (a_ns_green &&
                a_ew_green) begin

                $display("ERROR: A conflicting greens");
                errors = errors + 1;

            end

            if (b_ns_green &&
                b_ew_green) begin

                $display("ERROR: B conflicting greens");
                errors = errors + 1;

            end

            // Pedestrian phase requires all-red vehicles
            if (a_pedestrian_active &&
                (!a_ns_red || !a_ew_red)) begin

                $display("ERROR: A pedestrian phase is not all-red");
                errors = errors + 1;

            end

            if (b_pedestrian_active &&
                (!b_ns_red || !b_ew_red)) begin

                $display("ERROR: B pedestrian phase is not all-red");
                errors = errors + 1;

            end

            // Emergency
            if (emergency_override) begin

                if (!a_ns_red ||
                    !a_ew_red ||
                    !b_ns_red ||
                    !b_ew_red) begin

                    $display("ERROR: Emergency all-red condition failed");
                    errors = errors + 1;

                end

            end

        end

    end

    // --------------------------------------------------------
    // Main test
    // --------------------------------------------------------

    initial begin

        errors = 0;

        a_green_start_time = -1;
        b_green_start_time = -1;

        wave_offset = -1;

        a_ped_count = 0;
        b_ped_count = 0;

        first_ped_junction = 0;
        second_ped_junction = 0;

        previous_a_ns_green = 1'b0;
        previous_b_ns_green = 1'b0;

        previous_a_ped = 1'b0;
        previous_b_ped = 1'b0;

        reset = 1'b1;
        emergency_override = 1'b0;

        a_pedestrian_request = 1'b0;
        b_pedestrian_request = 1'b0;

        $display("");
        $display("==============================================");
        $display("AMTGC TASK 3 INTEGRATION TEST");
        $display("==============================================");

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (3)
            @(posedge clk);

        reset = 1'b0;

        // ----------------------------------------------------
        // Normal operation
        // ----------------------------------------------------

        $display("");
        $display("Checking normal two-junction operation...");

        repeat (70)
            @(posedge clk);

        // ----------------------------------------------------
        // Green-wave check
        // ----------------------------------------------------

        $display("");
        $display("Checking green-wave coordination...");

        // Wait for the next complete A green event.
        // More cycles are allowed because both controllers
        // continue operating.
        repeat (50)
            @(posedge clk);

        if (wave_offset < 0) begin

            $display("ERROR: No green-wave offset was measured");
            errors = errors + 1;

        end
        else begin

            $display("Green-wave offset measured = %0d cycles",
                     wave_offset);

            // With the synchronous architecture and the
            // configured one-stage coordination, an observed
            // 1-2 cycle offset is acceptable.
            if (wave_offset < 1 ||
                wave_offset > 2) begin

                $display("ERROR: Green-wave offset outside expected window");
                errors = errors + 1;

            end
            else begin

                $display("PASS: Green-wave coordination within expected window");

            end

        end

        // ----------------------------------------------------
        // Simultaneous pedestrian request #1
        // ----------------------------------------------------

        $display("");
        $display("Sending simultaneous pedestrian request #1");

        a_pedestrian_request = 1'b1;
        b_pedestrian_request = 1'b1;

        @(posedge clk);
        #1;

        a_pedestrian_request = 1'b0;
        b_pedestrian_request = 1'b0;

        // Allow both requests to be serviced.
        repeat (60)
            @(posedge clk);

        // ----------------------------------------------------
        // Simultaneous pedestrian request #2
        // ----------------------------------------------------

        $display("");
        $display("Sending simultaneous pedestrian request #2");

        a_pedestrian_request = 1'b1;
        b_pedestrian_request = 1'b1;

        @(posedge clk);
        #1;

        a_pedestrian_request = 1'b0;
        b_pedestrian_request = 1'b0;

        repeat (60)
            @(posedge clk);

        // ----------------------------------------------------
        // Fairness check
        // ----------------------------------------------------

        $display("");
        $display("Pedestrian service count:");
        $display("A = %0d", a_ped_count);
        $display("B = %0d", b_ped_count);

        if (a_ped_count == 0 ||
            b_ped_count == 0) begin

            $display("ERROR: One junction was starved");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Both pedestrian requests were serviced");

        end

        // ----------------------------------------------------
        // Emergency during pedestrian operation
        // ----------------------------------------------------

        $display("");
        $display("Testing emergency override...");

        // Create another A request.
        a_pedestrian_request = 1'b1;

        @(posedge clk);
        #1;

        a_pedestrian_request = 1'b0;

        // Wait until A pedestrian phase is active.
        wait (a_pedestrian_active);

        $display("Emergency asserted during A pedestrian phase");

        emergency_override = 1'b1;

        @(posedge clk);
        #1;

        if (!a_ns_red ||
            !a_ew_red ||
            !b_ns_red ||
            !b_ew_red) begin

            $display("ERROR: Emergency did not force both junctions all-red");
            errors = errors + 1;

        end
        else begin

            $display("PASS: Emergency forced both junctions all-red");

        end

        // Keep emergency active.
        repeat (5)
            @(posedge clk);

        if (!a_ns_red ||
            !a_ew_red ||
            !b_ns_red ||
            !b_ew_red) begin

            $display("ERROR: Junction left all-red during emergency");
            errors = errors + 1;

        end
        else begin

            $display("PASS: All-red maintained during emergency");

        end

        // ----------------------------------------------------
        // Emergency release
        // ----------------------------------------------------

        emergency_override = 1'b0;

        $display("Emergency released");

        repeat (15)
            @(posedge clk);

        // Check that both states are valid FSM states.
        if (a_state > 3'b110) begin

            $display("ERROR: A recovered to invalid state");
            errors = errors + 1;

        end

        if (b_state > 3'b110) begin

            $display("ERROR: B recovered to invalid state");
            errors = errors + 1;

        end

        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display("PASS: amtgc_top_tb completed with 0 errors");

        end
        else begin

            $display("FAIL: amtgc_top_tb found %0d errors",
                     errors);

        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule