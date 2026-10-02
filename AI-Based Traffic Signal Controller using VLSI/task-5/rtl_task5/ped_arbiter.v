
// ============================================================
// AMTGC - Shared Round-Robin Pedestrian Arbiter
// ============================================================

module ped_arbiter (
    input  wire clk,
    input  wire reset,

    input  wire req_a,
    input  wire req_b,

    input  wire service_done_a,
    input  wire service_done_b,

    output reg grant_a,
    output reg grant_b,

    output reg priority_a_next
);

reg priority_q;

// ------------------------------------------------------------
// Grant logic
// priority_q = 0 -> A gets priority
// priority_q = 1 -> B gets priority
// ------------------------------------------------------------

always @(*) begin

    grant_a = 1'b0;
    grant_b = 1'b0;

    if (req_a && req_b) begin

        if (priority_q == 1'b0)
            grant_a = 1'b1;
        else
            grant_b = 1'b1;

    end
    else if (req_a) begin

        grant_a = 1'b1;

    end
    else if (req_b) begin

        grant_b = 1'b1;

    end

end

// ------------------------------------------------------------
// Round-robin pointer
// ------------------------------------------------------------

always @(posedge clk) begin

    if (reset) begin

        priority_q <= 1'b0;

    end
    else begin

        if (service_done_a)
            priority_q <= 1'b1;

        else if (service_done_b)
            priority_q <= 1'b0;

    end

end

always @(*) begin

    priority_a_next = ~priority_q;

end

endmodule