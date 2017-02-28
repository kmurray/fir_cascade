/* A two cycle ternary ripple carry adder.
 *
 *  LSB_WIDTH bits are added in the first cycle
 *  MSB_WIDTH bits are added in the second cycle
 * 
 *  Inputs and outpus are combinational (ie not registered by the module)
 *
 *  The input MSB bits, and LSB carry are registered for use in the second 
 *  stage allowing two seperate additions to be pipelined in the adder.
 *
 *     i_a[WIDTH-1:LSB_WIDTH]  i_b[WIDTH-1:LSB_WIDTH]  i_c[WIDTH-1:LSB_WIDTH]  i_a[LSB_WIDTH-1:0]  i_b[LSB_WIDTH-1:0]  i_c[LSB_WIDTH-1:0]
 *
 *		 																							          \--------------------+--------------------/
 *     ______________________  ______________________  ______________________				______    ______________________
 *               \------------------------+------------------------/---------------------|							
 *					o_carry			o_sum[WIDTH-1:LSB_WIDTH]						           r_LSB_carry    o_sum[LSB_WIDTH-1:0]
 *
 */
module pipelined_ternary_add #(
	parameter LSB_WIDTH = 5,
	parameter ISB_WIDTH = 6,
	parameter MSB_WIDTH = 6,
	parameter WIDTH = 16
) (
	input clk,
	input reset,
	input signed [WIDTH-1:0] i_a,
	input signed [WIDTH-1:0] i_b,
	input signed [WIDTH-1:0] i_c,
	output signed [WIDTH-1:0] o_sum,
	output o_carry
);
	initial begin
		assert (WIDTH == LSB_WIDTH + ISB_WIDTH + MSB_WIDTH) else $error("Error LSB_WIDTH + ISB_WIDTH + MSB_WIDTH != WIDTH (%d + %d + %d != %d)", LSB_WIDTH, ISB_WIDTH, MSB_WIDTH, WIDTH);

//		$display("LSB_WIDTH: %d", LSB_WIDTH);
//		$display("ISB_WIDTH: %d", ISB_WIDTH);
//		$display("MSB_WIDTH: %d", MSB_WIDTH);
//		$display("WIDTH    : %d", WIDTH);
	end
	
	wire [LSB_WIDTH-1:0] w_LSB_sum;
	wire [ISB_WIDTH-1:0] w_ISB_sum;
	wire [MSB_WIDTH-1:0] w_MSB_sum;
	wire w_LSB_carry; //The carry out from the LSB
	wire w_ISB_carry; //The carry out from the ISB
	wire w_MSB_carry; //The carry out from the MSB
	
	reg [LSB_WIDTH-1:0] r_LSB_sum1;
	reg [LSB_WIDTH-1:0] r_LSB_sum2;
	reg r_LSB_carry; //Pipeline Register in carry chain
	
	reg [ISB_WIDTH-1:0] r_ISB_sum;
	reg r_ISB_carry;

	reg [(ISB_WIDTH+LSB_WIDTH)-1:LSB_WIDTH] r_a_ISB;
	reg [(ISB_WIDTH+LSB_WIDTH)-1:LSB_WIDTH] r_b_ISB;
	reg [(ISB_WIDTH+LSB_WIDTH)-1:LSB_WIDTH] r_c_ISB;
	
	reg [WIDTH-1:(ISB_WIDTH+LSB_WIDTH)] r_a_MSB1;
	reg [WIDTH-1:(ISB_WIDTH+LSB_WIDTH)] r_b_MSB1;
	reg [WIDTH-1:(ISB_WIDTH+LSB_WIDTH)] r_c_MSB1;

	reg [WIDTH-1:(ISB_WIDTH+LSB_WIDTH)] r_a_MSB2;
	reg [WIDTH-1:(ISB_WIDTH+LSB_WIDTH)] r_b_MSB2;
	reg [WIDTH-1:(ISB_WIDTH+LSB_WIDTH)] r_c_MSB2;
	
	//1st cycle: Add the LSB bits, generating a seperate carry signal
	assign {w_LSB_carry,w_LSB_sum} = {1'b0,i_a[LSB_WIDTH-1:0]} + {1'b0,i_b[LSB_WIDTH-1:0]} + {1'b0,i_c[LSB_WIDTH-1:0]};
	
	//Register the LSB carry signal and LSB sum
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_LSB_carry <= 0;
			r_LSB_sum1 <= 0;
			r_LSB_sum2 <= 0;
		end
		else begin
			r_LSB_carry <= w_LSB_carry;
			r_LSB_sum1 <= w_LSB_sum;
			r_LSB_sum2 <= r_LSB_sum1;
		end
	end
	
	//Register the ISB bits of the inputs
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_a_ISB <= 0;
			r_b_ISB <= 0;
			r_c_ISB <= 0;

		end
		else begin
			r_a_ISB <= i_a[(ISB_WIDTH+LSB_WIDTH)-1:LSB_WIDTH];
			r_b_ISB <= i_b[(ISB_WIDTH+LSB_WIDTH)-1:LSB_WIDTH];
			r_c_ISB <= i_c[(ISB_WIDTH+LSB_WIDTH)-1:LSB_WIDTH];
		end
	end
	
	//2nd cycle: Add the ISB bits, generating seperate carry signal
	assign {w_ISB_carry,w_ISB_sum} = r_a_ISB + r_b_ISB + r_c_ISB + r_LSB_carry;

	//Register the ISB carry signal and ISB sum
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_ISB_carry <= 0;
			r_ISB_sum <= 0;
		end
		else begin
			r_ISB_carry <= w_ISB_carry;
			r_ISB_sum <= w_ISB_sum;
		end
	end
	
	//Register the MSB bits of the inputs
	always@(posedge clk or posedge reset) begin
		if(reset) begin
			r_a_MSB1 <= 0;
			r_b_MSB1 <= 0;
			r_c_MSB1 <= 0;
			r_a_MSB2 <= 0;
			r_b_MSB2 <= 0;
			r_c_MSB2 <= 0;
		end
		else begin
			r_a_MSB1 <= i_a[WIDTH-1:(ISB_WIDTH+LSB_WIDTH)];
			r_b_MSB1 <= i_b[WIDTH-1:(ISB_WIDTH+LSB_WIDTH)];
			r_c_MSB1 <= i_c[WIDTH-1:(ISB_WIDTH+LSB_WIDTH)];
			r_a_MSB2 <= r_a_MSB1;
			r_b_MSB2 <= r_b_MSB1;
			r_c_MSB2 <= r_c_MSB1;
		end
	end
	
	//3rd cycle: Add the MSB bits
	assign {w_MSB_carry,w_MSB_sum} = r_a_MSB2 + r_b_MSB2 + r_c_MSB2 + r_ISB_carry;
	
	//Outputs
	assign o_sum = {w_MSB_sum,r_ISB_sum,r_LSB_sum2};
	assign o_carry = w_MSB_carry;
endmodule
