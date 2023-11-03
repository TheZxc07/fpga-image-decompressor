
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module colourspace_convert (

   input  logic            Clock,
   input  logic            Resetn,

   input  logic   [7:0]    Y,
	input  logic 	[7:0]		U,
	input	 logic 	[7:0]		V,
	input  logic            start,
	//input  logic 	[9:0]	   j;

   output logic   [23:0]   RGB_data,
   output logic   [17:0]   SRAM_address
	
);

colourspace_conversion_state_type state;

logic [2:0] counter;
logic [31:0] R_accumulator;
logic [31:0] G_accumulator;
logic [31:0] B_accumulator;
logic [7:0] op1;
logic [18:0] op2;
logic [23:0] cache;
logic product;

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
		state <= S_IDLE;
		
		R_accumulator <= 32'h0;
		G_accumulator <= 32'h0;
		B_accumulator <= 32'h0;
		
		counter <= 3'd0;
	end else begin
	
		case(state)
			S_IDLE: begin
				if(start) begin
					state <= S_COLOURSPACE_CONVERT;
					counter <= 3'd0;
					
					R_accumulator <= 32'h0;
					G_accumulator <= 32'h0;
					B_accumulator <= 32'h0;					
				end
			end
			S_COLOURSPACE_CONVERT_0: begin
				counter <= counter + 3'd1;
				if (counter == 3'd4) begin
					state <= S_IDLE;
					G_accumulator <= G_accumulator;
				end
				if (counter == 3'd0) begin
					cache <= product;
				end
				if (counter < 3'd2) begin
					R_accumulator <= R_accumulator + product;
				end
				if (counter >= 3'd2 && counter < 3'd4) begin
					if (counter == 2) begin
						G_accumulator <= cache;
					end else begin
						G_accumulator <= G_accumulator + product;
					end
				end
			
			end
		endcase
		
	end


end

always_comb begin
	case(counter)
		3'd0 : op2 = 19'd76284;
		3'd1 : op2 = 19'd104595;
		3'd2 : op2 = -19'd25624;
		3'd3 : op2 = -19'd53281;
		3'd4 : op2 = 19'd132251;
		default : op2 = 0;
	endcase
end

always_comb begin
	case(counter)
		3'd0 : op1 = Y-8'd16;
		3'd1 : op1 = V-8'd128;
		3'd2 : op1 = U-8'd128;
		3'd3 : op1 = V-8'd128;
		3'd4 : op1 = U-8'd128;
	endcase
end

assign product = op1*op2;

endmodule 