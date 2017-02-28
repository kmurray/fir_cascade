/*
 *  A 7 input ternary adder tree (2 levels)
 *
 *  Inputs are not registered (should be fed by
 *  registered outputs of DSP blocks).
 *
 *  Output is registered.
 *  
 *  Each Level is pipelined to improve frequency.
 *
 *  Since the tree isn't perfectly balanced, the 
 *  last input (i_g) gets added at the 2nd level.
 *  To ensure correct data alignment, i_g is
 *  registered for 2 cycles to match 
 *  pipelined_ternary_add latency.
 * 
 *   i_a   i_b   i_c  i_d  i_e  i_f  i_g
 *     \----+----/     \----+----/   ___    Cycle 1
 *         ___             ___       ___    Cycle 2
 *          \---------------+---------/     Cycle 3
 *                         ___              Cycle 4
 *                        o_sum
 */
module ternary_adder_tree
#(
	parameter WIDTH=17
)(
	input clk,
	input reset,
	input signed [WIDTH-1:0] i_a,
	input signed [WIDTH-1:0] i_b,
	input signed [WIDTH-1:0] i_c,
	input signed [WIDTH-1:0] i_d,
	input signed [WIDTH-1:0] i_e,
	input signed [WIDTH-1:0] i_f,
	input signed [WIDTH-1:0] i_g,
	output signed [WIDTH-1:0] o_sum
);
	
	wire signed [WIDTH-1:0] w_add1_sum;
	wire signed [WIDTH-1:0] w_add2_sum;
	wire signed [WIDTH-1:0] w_add3_sum;
	
	//Registered adder outputs
	reg signed [WIDTH-1:0] r_add1_sum; 
	reg signed [WIDTH-1:0] r_add2_sum;
	reg signed [WIDTH-1:0] r_add3_sum;
	
	//Input g skips to level 2, so it must be regiseterd 
	//twice (2-cycle adders) to align with level 1 outputs
	reg signed [WIDTH-1:0] r_g1;
	reg signed [WIDTH-1:0] r_g2;
	reg signed [WIDTH-1:0] r_g3;
	
	//Level 1
	ternary_add  #(
		.WIDTH(WIDTH)
		) add1 (
		.clk(clk),
		.reset(reset),
		.i_a(i_a),
		.i_b(i_b),
		.i_c(i_c),
		.o_sum(w_add1_sum)
	);
	
	ternary_add  #(
		.WIDTH(WIDTH)
		) add2 (
		.clk(clk),
		.reset(reset),
		.i_a(i_d),
		.i_b(i_e),
		.i_c(i_f),
		.o_sum(w_add2_sum)
	);
	
	//Level 1 Output registers
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_add1_sum <= 0;
			r_add2_sum <= 0;
			r_g1 <= 0;
			r_g2 <= 0;
			r_g3 <= 0;
		end
		else begin
			r_add1_sum <= w_add1_sum;
			r_add2_sum <= w_add2_sum;
			r_g1 <= i_g;
			r_g2 <= r_g1;
			r_g3 <= r_g2;		
		end
	end
	
	//Level 2
	ternary_add  #(
		.WIDTH(WIDTH)
		) add3 (
		.clk(clk),
		.reset(reset),
		.i_a(r_add1_sum),
		.i_b(r_add2_sum),
		.i_c(r_g1),
		.o_sum(w_add3_sum)
	);
	
	//Level 2 Output registers
	always@(posedge clk or posedge reset) begin
		if (reset)
			r_add3_sum <= 0;
		else 
			r_add3_sum <= w_add3_sum;
	end
	
	//Final output
	assign o_sum = r_add3_sum;

endmodule
