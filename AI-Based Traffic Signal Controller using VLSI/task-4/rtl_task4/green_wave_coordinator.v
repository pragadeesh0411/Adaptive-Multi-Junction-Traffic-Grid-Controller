`timescale 1ns/1ps

// ============================================================
// Green-Wave Coordinator
//
// Detects the start of Junction A NS green and generates a
// delayed coordination level for Junction B.
// ============================================================

module green_wave_coordinator #(
    parameter integer GREEN_WAVE_DELAY = 1,
    parameter integer COUNTER_WIDTH     = 8
)(
    input wire clk,
    input wire reset,

    input wire source_ns_green,

    output reg wave_start
);

    reg source_ns_green_previous;

    reg delay_active;

    reg [COUNTER_WIDTH-1:0] delay_count;

    wire source_rising;

    assign source_rising =
        source_ns_green &
        ~source_ns_green_previous;

    // --------------------------------------------------------
    // Coordinator operation
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            source_ns_green_previous <= 1'b0;

            delay_active <= 1'b0;
            delay_count  <= {COUNTER_WIDTH{1'b0}};

            wave_start   <= 1'b0;

        end
        else begin

            source_ns_green_previous <= source_ns_green;

            // When A leaves NS green, clear the coordination
            // request so the next A green creates a new event.
            if (!source_ns_green) begin

                wave_start   <= 1'b0;
                delay_active <= 1'b0;
                delay_count  <= {COUNTER_WIDTH{1'b0}};

            end

            // Detect a new A NS-green phase.
            else if (source_rising) begin

                if (GREEN_WAVE_DELAY == 0) begin

                    wave_start <= 1'b1;

                end
                else begin

                    delay_active <= 1'b1;
                    delay_count  <= {COUNTER_WIDTH{1'b0}};

                end

            end

            // Count the requested coordination delay.
            else if (delay_active) begin

                if (delay_count >=
                    (GREEN_WAVE_DELAY - 1)) begin

                    wave_start   <= 1'b1;
                    delay_active <= 1'b0;
                    delay_count  <= {COUNTER_WIDTH{1'b0}};

                end
                else begin

                    delay_count <= delay_count + 1'b1;

                end

            end

        end

    end

endmodule