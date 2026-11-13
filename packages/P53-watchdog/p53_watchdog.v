// P53 Watchdog timer
// Slot 11 registers (ridx): 0 LOAD, 1 CTRL (bit0 enable), 2 STATUS (bit0 = bite),
//                           3 COUNT, 4 KICK, 15 = 53 (package number)
// Counts down while enabled. At 0 it sets the sticky bite flag and reloads from LOAD.
// A write to KICK reloads the counter (and wins over a bite on the same cycle).
// A write to STATUS clears the bite flag. rst clears everything.
module p53_watchdog (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    reg [31:0] load, count;
    reg        en, bite;

    wire wr   = sel & we;
    wire kick = wr & (ridx == 4'd4);

    always @(posedge clk) begin
        if (rst) begin
            load  <= 32'd0;
            count <= 32'd0;
            en    <= 1'b0;
            bite  <= 1'b0;
        end else begin
            // counting
            if (kick)
                count <= load;
            else if (en) begin
                if (count == 32'd0) begin
                    bite  <= 1'b1;
                    count <= load;
                end else
                    count <= count - 32'd1;
            end
            // register writes
            if (wr) begin
                case (ridx)
                    4'd0: begin load <= wdata; count <= wdata; end
                    4'd1: en   <= wdata[0];
                    4'd2: bite <= 1'b0;
                    default: ;
                endcase
            end
        end
    end

    // reads
    always @(*) begin
        rdata = 32'd0;
        if (sel && re) begin
            case (ridx)
                4'd0:  rdata = load;
                4'd1:  rdata = {31'd0, en};
                4'd2:  rdata = {31'd0, bite};
                4'd3:  rdata = count;
                4'd15: rdata = 32'd53;
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule
