// P58 Branch predictor (2-bit saturating counters).
// Register 0: committed branch count. Register 1: correctly predicted count.
// Register 2: write one to clear the two counts. Register 15: package ID (58).
module p58_bpred (
    input  wire clk,
    input  wire rst,
    input  wire sel,
    input  wire we,
    input  wire re,
    input  wire [3:0] ridx,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire commit,
    input  wire is_branch,
    input  wire taken,
    input  wire [31:0] pc
);

    reg [1:0] counters [0:15];
    reg [31:0] branches;
    reg [31:0] correct_count;
    reg [31:0] read_value;

    wire [3:0] index = pc[5:2];
    wire [1:0] current_counter = counters[index];
    wire prediction = current_counter[1];
    wire branch_update = commit && is_branch;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                counters[i] <= 2'b01; // weakly not taken
            branches <= 32'd0;
            correct_count <= 32'd0;
        end else begin
            if (sel && we && ridx == 4'd2 && wdata[0]) begin
                branches <= 32'd0;
                correct_count <= 32'd0;
            end else if (branch_update) begin
                branches <= branches + 32'd1;
                if (prediction == taken)
                    correct_count <= correct_count + 32'd1;
            end

            if (branch_update) begin
                if (taken) begin
                    if (current_counter != 2'b11)
                        counters[index] <= current_counter + 2'b01;
                end else begin
                    if (current_counter != 2'b00)
                        counters[index] <= current_counter - 2'b01;
                end
            end
        end
    end

    always @* begin
        case (ridx)
            4'd0: read_value = branches;
            4'd1: read_value = correct_count;
            4'd15: read_value = 32'd58;
            default: read_value = 32'd0;
        endcase
    end

    assign rdata = sel ? read_value : 32'd0;

endmodule
