module ternary_add #(
	parameter WIDTH = 17
) (
	input clk,
	input reset,
	input signed [WIDTH-1:0] i_a,
	input signed [WIDTH-1:0] i_b,
	input signed [WIDTH-1:0] i_c,
	output signed [WIDTH-1:0] o_sum,
	output o_carry
);

	assign {o_carry,o_sum} = i_a + i_b + i_c;

endmodule
