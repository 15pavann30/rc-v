// P23 Microprogrammed control (control ROM)
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.

module  p23_ctrl_rom (
    input  wire [4:0]  op_hi,
    output reg  [15:0] ctrl
);

    always @* begin
        case (op_hi)
            5'd0:  ctrl = 16'h5480;   // LOAD
            5'd4:  ctrl = 16'h5000;   // OP-IMM
            5'd5:  ctrl = 16'h7030;   // AUIPC
            5'd8:  ctrl = 16'h1210;   // STORE
            5'd12: ctrl = 16'h4000;   // OP
            5'd13: ctrl = 16'h5830;   // LUI
            5'd24: ctrl = 16'h0028;   // BRANCH
            5'd25: ctrl = 16'h5102;   // JALR
            5'd27: ctrl = 16'h4144;   // JAL
            5'd28: ctrl = 16'h4181;   // SYSTEM
            default: ctrl = 16'h0000;
        endcase
    end

endmodule
