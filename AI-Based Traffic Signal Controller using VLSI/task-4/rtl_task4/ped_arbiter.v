`timescale 1ns/1ps

// ============================================================
// Shared Pedestrian Arbiter
// Round-robin arbitration
// ============================================================

module ped_arbiter (
    input wire clk,
    input wire reset,

    input wire req_a,
    input wire req_b,

    input wire service_done_a,
    input wire service_done_b,

    output reg grant_a,
    output reg grant_b,

    output reg priority_a_next
);

    // 0 = Junction A has current priority
    // 1 = Junction B has current priority
    reg priority_q;

    // --------------------------------------------------------
    // Grant logic
    // --------------------------------------------------------

    always @(*) begin

        grant_a = 1'b0;
        grant_b = 1'b0;

        if (req_a && req_b) begin

            if (priority_q == 1'b0) begin

                grant_a = 1'b1;

            end
            else begin

                grant_b = 1'b1;

            end

        end
        else if (req_a) begin

            grant_a = 1'b1;

        end
        else if (req_b) begin

            grant_b = 1'b1;

        end

    end

    // --------------------------------------------------------
    // Rotate priority after completed service
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            priority_q <= 1'b0;

        end
        else begin

            if (service_done_a) begin

                priority_q <= 1'b1;

            end
            else if (service_done_b) begin

                priority_q <= 1'b0;

            end

        end

    end

    // --------------------------------------------------------
    // Status output
    // --------------------------------------------------------

    always @(*) begin

        priority_a_next = ~priority_q;

    end

endmodule