`timescale 1ps/1ps

module fir_cascade_tb();
localparam SIM_LEN = 200;
localparam RAND_INPUT = 1;
localparam MAKE_GOLDEN = 0;
localparam START_VAL = (MAKE_GOLDEN) ? 0 : 1; //Offset by 1 if making golden
localparam POWER_EST = 0; //Toggle correctness test and power test


//logic signed [15:0] i_in;
//logic signed [15:0] o_out;
//logic i_valid;
//logic o_valid;
logic signed [15:0] o_golden_out;   // Golden output you are trying to match.
logic clk;
logic reset;

logic i_valid_valid;
logic i_valid_data;
logic i_valid_stop;

logic signed [15:0] i_data_data;
logic i_data_valid;
logic i_data_stop;

logic o_valid_valid;
logic o_valid_data;
logic o_valid_stop;

logic signed[15:0] o_data_data;
logic o_data_valid;
logic o_data_stop;


fir_cascade dut ( .* );


assign i_valid_valid = 1'b1;
assign i_data_valid = 1'b1;
assign o_data_stop = 1'b0;
assign o_valid_stop = 1'b0;

initial clk = '1;
//always #1960 clk = ~clk;  // 510.2 MHz clock
//always #2500 clk = ~clk; //400 MHz clock
always #5000 clk = ~clk; //200 MHz clock
//always #10000 clk = ~clk; //100 MHz clock

logic signed [15:0] inwave[SIM_LEN-1:0];
logic signed [15:0] outwave[SIM_LEN-1:0];


// Producer
initial begin
	integer f;

	if(RAND_INPUT) begin
		 //Random input vector for power estimation
		 for (int i = 0; i < SIM_LEN; i++) begin
					inwave[i] = $urandom_range(20000,0);
		 end

	end else begin
		// Create known good input: a delta function, then a step function
		for (int i = 0; i < SIM_LEN; i++) begin
			if (i == 60 || i >= 120) 
				inwave[i] = 16'd20000;
			else
			inwave[i] = 16'd0;
		end
	end
	
	// Load known good output
	f = $fopen("outdata.txt", "r");
	for (int i = 0; i < SIM_LEN; i++) begin
		integer d;
		d = $fscanf(f, "%d", outwave[i]);
	end
	$fclose(f);

	i_valid_data = 1'b0;
	i_data_data = 'd0;
	
	reset = 1'b1;
	@(negedge clk);
	reset = 1'b0;	
	
	for (int i = 0; i < SIM_LEN; i++) begin
		@(negedge clk);
		i_data_data = inwave[i];
		i_valid_data = 1'b1;
	end
	
	@(negedge clk);
	i_valid_data = 1'b0;
	
end

// Consumer
initial begin
	static real rms = 0.0;
	integer f;
	
	if (MAKE_GOLDEN) begin
		f = $fopen("outdata.txt", "w");
	end
	
	o_golden_out = 16'b0;
	for (int i = START_VAL; i < SIM_LEN; i++) begin
		real v1;
		real v2;
		real diff;
		
		// Wait for a valid output
		@(posedge clk);
		while (!(o_valid_data && o_valid_valid)) begin
			@(posedge clk);
		end
		
		if (MAKE_GOLDEN) begin
			$fdisplay(f, "%d", o_data_data);
		end
		
		@(negedge clk);  // Give time for o_out to be updated.
		v1 = real'(o_data_data);
		o_golden_out = outwave[i];
		v2 = real'(o_golden_out);
		diff = (v1 - v2);
		
		rms += diff*diff;
		$display("diff: %f, rms: %f, o_out: %f, golden: %f, at time: ", diff, rms, v1, v2, $time);
	end
	
	if (MAKE_GOLDEN) begin
		$fclose(f);
		$stop(0);
	end
	
	rms /= SIM_LEN;
	rms = rms ** (0.5);
	
	$display("RMS Error: %f", rms);
	if (rms > 10) begin
		$display("Average RMS Error is above 10 units (on a scale to 32,000) - something is probably wrong");
	end
	else begin
		$display("Error is within 10 units (on a scale to 32,000) - great success!!");
	end
	
	$stop(0);
end

endmodule
