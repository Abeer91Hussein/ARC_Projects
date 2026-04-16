module State_Unit_Module (
    input  logic        clk,
    input  logic        reset,
    output logic [2:0]  S
);

    logic [2:0] S_next;

    // -------------------------
    // State register
    // -------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            S <= 3'd0;
        else
            S <= S_next;
    end

    // -------------------------
    // Next-state logic
    // -------------------------
    always_comb begin
        case (S)
            3'd0: S_next = 3'd1;
            3'd1: S_next = 3'd2;
            3'd2: S_next = 3'd3;
            3'd3: S_next = 3'd4;
            3'd4: S_next = 3'd0;
            default: S_next = 3'd0;
        endcase
    end

endmodule


