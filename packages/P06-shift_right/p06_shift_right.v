// P06 Right barrel shifter
// 32-bit combinational logical/arithmetic right barrel shifter.
module p06_shift_right (
    input  wire [31:0] a,
    input  wire [4:0] sh,
    input  wire arith,
    output wire [31:0] y
);

    wire fill;
    wire [31:0] s1, s2, s4, s8;

    // Arithmetic mode replicates the sign bit; logical mode shifts in zero.
    assign fill = arith & a[31];

    // Five 2-to-1 mux stages implement shifts of 1, 2, 4, 8 and 16.
    assign s1 = sh[0] ? {{1{fill}},  a[31:1]}  : a;
    assign s2 = sh[1] ? {{2{fill}},  s1[31:2]} : s1;
    assign s4 = sh[2] ? {{4{fill}},  s2[31:4]} : s2;
    assign s8 = sh[3] ? {{8{fill}},  s4[31:8]} : s4;
    assign y  = sh[4] ? {{16{fill}}, s8[31:16]}: s8;

endmodule
