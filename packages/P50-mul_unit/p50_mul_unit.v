// P50 - 32-bit signed multiplier using shift and add
module p50_mul_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire        re,
    input  wire [3:0]  ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    reg [31:0] reg_a;
    reg [31:0] reg_b;
    reg [31:0] result_reg;

    reg        busy;
    reg [5:0]  count;
    reg        negative;

    reg [63:0] accumulator;
    reg [63:0] multiplicand;
    reg [31:0] multiplier;

    reg [63:0] next_accumulator;
    reg [31:0] read_data;

    // Read port is combinational.
    always @(*) begin
        case (ridx)
            4'd0:    read_data = reg_a;
            4'd1:    read_data = reg_b;
            4'd2:    read_data = 32'd0;
            4'd3:    read_data = {31'd0, busy};
            4'd4:    read_data = result_reg;
            4'd15:   read_data = 32'd50;
            default: read_data = 32'd0;
        endcase
    end

    assign rdata = read_data;

    // Multiplier state and register writes.
    always @(posedge clk) begin
        if (rst) begin
            reg_a        <= 32'd0;
            reg_b        <= 32'd0;
            result_reg   <= 32'd0;
            busy         <= 1'b0;
            count        <= 6'd0;
            negative     <= 1'b0;
            accumulator  <= 64'd0;
            multiplicand <= 64'd0;
            multiplier   <= 32'd0;
        end
        else begin

            // Memory-mapped register writes.
            if (sel && we) begin
                case (ridx)
                    4'd0: reg_a <= wdata;
                    4'd1: reg_b <= wdata;

                    // Writing bit 0 starts a new multiplication.
                    4'd2: begin
                        if (wdata[0] && !busy) begin
                            busy        <= 1'b1;
                            count       <= 6'd0;
                            accumulator <= 64'd0;

                            negative <= reg_a[31] ^ reg_b[31];

                            multiplicand <= reg_a[31]
                                ? {32'd0, (~reg_a + 32'd1)}
                                : {32'd0, reg_a};

                            multiplier <= reg_b[31]
                                ? (~reg_b + 32'd1)
                                : reg_b;
                        end
                    end

                    default: begin
                        // Other registers are read-only or unused.
                    end
                endcase
            end

            // One shift-and-add iteration per clock cycle.
            if (busy) begin
                next_accumulator = accumulator;

                if (multiplier[0])
                    next_accumulator = accumulator + multiplicand;

                accumulator  <= next_accumulator;
                multiplicand <= multiplicand << 1;
                multiplier   <= multiplier >> 1;

                if (count == 6'd31) begin
                    if (negative)
                        result_reg <= (~next_accumulator[31:0]) + 32'd1;
                    else
                        result_reg <= next_accumulator[31:0];

                    busy  <= 1'b0;
                    count <= 6'd0;
                end
                else begin
                    count <= count + 6'd1;
                end
            end
        end
    end

endmodule
