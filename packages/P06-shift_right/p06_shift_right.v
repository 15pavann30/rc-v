// P06 Right barrel shifter
// Keep the module name and the port list exactly as they are.
// You may change 'output wire' to 'output reg' if you assign an output in an always block.
// Delete the placeholder assigns and write your design.
module p06_shift_right (
    input  wire [31:0] a,
    input  wire [4:0] sh,
    input  wire arith,
    output wire [31:0] y
);

    assign y = arith ? ($signed(a) >>> sh) : (a >> sh);

endmodule
