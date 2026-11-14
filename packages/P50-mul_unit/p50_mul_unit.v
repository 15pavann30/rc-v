// P50 Multiplier (shift and add)
// Keep the module name and the port list exactly as they are.
module p50_mul_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire        re,
    input  wire [3:0]  ridx,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    reg [31:0] reg_a;
    reg [31:0] reg_b;
    reg [31:0] reg_result;
    reg        busy;
    reg [5:0]  count;
    reg [63:0] prod_acc;
    reg [31:0] multiplicand;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_a        <= 32'd0;
            reg_b        <= 32'd0;
            reg_result   <= 32'd0;
            busy         <= 1'b0;
            count        <= 6'd0;
            prod_acc     <= 64'd0;
            multiplicand <= 32'd0;
        end else begin
            if (busy) begin
                if (prod_acc[0]) begin
                    prod_acc[63:32] <= prod_acc[63:32] + multiplicand;
                end
                prod_acc <= {1'b0, prod_acc[63:1]};
                count <= count + 1'b1;
                if (count == 6'd31) begin
                    busy <= 1'b0;
                    reg_result <= prod_acc[31:0];
                end
            end else if (sel && we) begin
                case (ridx)
                    4'h0: reg_a <= wdata;
                    4'h1: reg_b <= wdata;
                    4'h2: begin
                        if (wdata[0]) begin
                            busy <= 1'b1;
                            count <= 6'd0;
                            multiplicand <= reg_a;
                            prod_acc <= {32'd0, reg_b};
                        end
                    end
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        if (sel) begin
            if (ridx == 4'hf) begin
                rdata = 32'h32; // Package number 50 (0x32 in hex is 50)
            end else if (re) begin
                case (ridx)
                    4'h0: rdata = reg_a;
                    4'h1: rdata = reg_b;
                    4'h2: rdata = 32'd0;
                    4'h3: rdata = {31'd0, busy};
                    4'h4: rdata = reg_result;
                    default: rdata = 32'd0;
                endcase
            end else begin
                rdata = 32'd0;
            end
        end else begin
            rdata = 32'd0;
        end
    end

endmodule
