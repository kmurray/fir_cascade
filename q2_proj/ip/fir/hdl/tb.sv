`timescale 1ps/1ps

module tb();

localparam MAKE_GOLDEN = 0;
localparam POWER_EST = 0; //Toggle correctness test and power test

logic signed [15:0] i_in;
logic signed [15:0] o_out;
logic i_valid;
logic o_valid;
logic clk;
logic clk_ena;
logic reset;
logic signed [15:0] o_golden_out;   // Golden output you are trying to match.

fir dut ( .* );

initial clk = '1;
//always #1960 clk = ~clk;  // 510.2 MHz clock
//always #2500 clk = ~clk; //400 MHz clock
always #5000 clk = ~clk; //200 MHz clock
//always #10000 clk = ~clk; //100 MHz clock

initial clk_ena = '1;

logic signed [15:0] inwave[199:0];
logic signed [15:0] outwave[199:0];


// Producer
initial begin
	integer f;
	
	if (POWER_EST == 0) begin
		// Create known good input: a delta function, then a step function
		for (int i = 0; i < 200; i++) begin
			if (i == 60 || i >= 120) 
				inwave[i] = 16'd20000;
			else
			inwave[i] = 16'd0;
		end
	end
	else begin
		//Random input vector for power estimation
		for (int i = 0; i < 200; i++) begin
			inwave[i] = $urandom_range(20000,0);
		end
	end
	
	// Load known good output
	f = $fopen("outdata.txt", "r");
	for (int i = 0; i < 200; i++) begin
		integer d;
		d = $fscanf(f, "%d", outwave[i]);
	end
	$fclose(f);

	i_valid = 1'b0;
	i_in = 'd0;
	
	reset = 1'b1;
	@(negedge clk);
	reset = 1'b0;	
	
	for (int i = 0; i < 200; i++) begin
		@(negedge clk);
		i_in = inwave[i];
		i_valid = 1'b1;
	end
	
	@(negedge clk);
	i_valid = 1'b0;
end

// Consumer
initial begin
	static real rms = 0.0;
	integer f;
	
	if (MAKE_GOLDEN) begin
		f = $fopen("outdata.txt", "w");
	end
	
        o_golden_out = 16'b0;
	for (int i = 0; i < 200; i++) begin
		real v1;
		real v2;
		real diff;
		
		// Wait for a valid output
		@(posedge clk);
		while (!o_valid) begin
			@(posedge clk);
		end
		
		if (MAKE_GOLDEN) begin
			$fdisplay(f, "%d", o_out);
		end
		
		@(negedge clk);  // Give time for o_out to be updated.
		v1 = real'(o_out);
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
	
	rms /= 200;
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
