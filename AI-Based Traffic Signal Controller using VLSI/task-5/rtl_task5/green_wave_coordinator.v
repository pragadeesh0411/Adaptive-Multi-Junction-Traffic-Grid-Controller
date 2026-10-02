
// ============================================================
// AMTGC - Green Wave Coordinator
//
// Junction B NS green starts after a parameterized delay from
// Junction A NS green.
// ============================================================

module green_wave_coordinator #(
    parameter integer GREEN_WAVE_DELAY = 2,
    parameter integer COUNTER_WIDTH     = 16
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    source_ns_green,

    output wire                    wave_start
);

reg source_ns_green_prev;
reg wave_pending;
reg [COUNTER_WIDTH-1:0] delay_count;

wire green_start_event;

// ------------------------------------------------------------
// Detect rising edge of Junction A NS green
// ------------------------------------------------------------

assign green_start_event =
        source_ns_green & ~source_ns_green_prev;

// ------------------------------------------------------------
// Wave pulse
// ------------------------------------------------------------

assign wave_start =
        wave_pending &&
        (
            (GREEN_WAVE_DELAY == 0) ||
            (delay_count == GREEN_WAVE_DELAY - 1)
        );

// ------------------------------------------------------------
// Coordinator sequential logic
// ------------------------------------------------------------

always @(posedge clk) begin

    if (reset) begin

        source_ns_green_prev <= 1'b0;
        wave_pending         <= 1'b0;
        delay_count          <= {COUNTER_WIDTH{1'b0}};

    end
    else begin

        source_ns_green_prev <= source_ns_green;

        if (green_start_event) begin

            wave_pending <= 1'b1;
            delay_count  <= {COUNTER_WIDTH{1'b0}};

        end
        else if (wave_pending) begin

            if (wave_start) begin

                wave_pending <= 1'b0;
                delay_count  <= {COUNTER_WIDTH{1'b0}};

            end
            else begin

                delay_count <= delay_count + 1'b1;

            end

        end

    end

end

endmodule