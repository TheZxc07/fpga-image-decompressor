
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module MIC17_decompressor (

   input  logic            Clock,
   input  logic            Resetn,

   input  logic   [15:0]   SRAM_read_data,
	input  logic 				Start,
	output logic				Finish,
	//input  logic 	[9:0]	   j;

	output logic 				SRAM_we_n,
   output logic   [15:0]   SRAM_write_data,
   output logic   [17:0]   SRAM_address

);

logic [6:0] S_prime_address_a, S_prime_address_b;
logic [15:0] S_prime_write_data_a, S_prime_write_data_b, S_prime_read_data_a, S_prime_read_data_b;
logic S_prime_write_enable_a, S_prime_write_enable_b;

assign S_prime_write_enable_b = 1'b0;

logic decode_start;

logic get_s_prime;
logic test;
logic test1;

logic quantization_matrix;

logic [17:0] UCSC_SRAM_address;
logic [17:0] IDCT_SRAM_address;
logic [17:0] decode_SRAM_address;

logic [15:0] UCSC_SRAM_write_data;
logic [15:0] IDCT_SRAM_write_data;
logic [15:0] decode_SRAM_write_data;

logic UCSC_SRAM_we_n;
logic IDCT_SRAM_we_n;
logic decode_SRAM_we_n;

logic M1_start;
logic M2_start;
logic M1_finish;
logic M2_finish;

logic S_prime_full;
logic fill_instruction;
logic Fill_instruction;

assign quantization_matrix = 1'b0;


MIC17_decompressor_state_type MIC17_state;

dual_port_RAM3 S_prime_RAM (
	.address_a ( S_prime_address_a ),
	.address_b ( S_prime_address_b ),
	.clock ( Clock ),
	.data_a ( S_prime_write_data_a ),
	.data_b ( S_prime_write_data_b ),
	.wren_a ( S_prime_write_enable_a ),
	.wren_b ( S_prime_write_enable_b ),
	.q_a ( S_prime_read_data_a ),
	.q_b ( S_prime_read_data_b )
	);
	
	
decode_controller decode_unit (

   .Clock(Clock),
   .Resetn(Resetn),

   .SRAM_read_data(SRAM_read_data),
	.Start(decode_start),
	.Get_S_prime(Fill_instruction),
	.quantization_matrix(quantization_matrix),
				
	.RAM_address(S_prime_address_a),
	.RAM_write_data(S_prime_write_data_a),
	.RAM_write_enable(S_prime_write_enable_a),
	
	.S_prime_loaded(S_prime_full),
	
	.SRAM_we_n(decode_SRAM_we_n),
   .SRAM_write_data(decode_SRAM_write_data),
   .SRAM_address(decode_SRAM_address)
);

IDCT_controller IDCT_unit (
	.Clock(Clock),
	.Resetn(Resetn),
	
	.SRAM_read_data(SRAM_read_data),
	.Start(M2_start),
	.Finish(M2_finish),
	
	.SRAM_we_n(IDCT_SRAM_we_n),
	.SRAM_write_data(IDCT_SRAM_write_data),
	.SRAM_address(IDCT_SRAM_address),
	
	.S_prime_RAM_address(S_prime_address_b),
	.S_prime_RAM_read_data(S_prime_read_data_b),
	
	.fill_s_prime(fill_instruction)
);	

interp_colourspace_conversion UCSC_unit (
	.Clock(Clock),
	.Resetn(Resetn),
	
	.SRAM_read_data(SRAM_read_data),
	.Start(M1_start),
	.Finish(M1_finish),
	
	.SRAM_we_n(UCSC_SRAM_we_n),
	.SRAM_write_data(UCSC_SRAM_write_data),
	.SRAM_address(UCSC_SRAM_address)
);

assign Fill_instruction = (MIC17_state == S_MIC17_M3_M2) ? fill_instruction : get_s_prime;

logic start_buf;

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
	
		decode_start <= 1'b0;
		Finish <= 1'b0;
		start_buf <= 1'b0;
		M2_start <= 1'b0;
		M1_start <= 1'b0;
		Finish <= 1'b0;
		get_s_prime <= 1'b0;
	
		MIC17_state <= S_MIC17_IDLE;
	
	end else begin
	
		case(MIC17_state)
		
			S_MIC17_IDLE: begin
				
				start_buf <= Start;
				if (Start && ~start_buf) begin
					Finish <= 1'b0;
					MIC17_state <= S_MIC17_WAIT_M3_GET_S_PRIME;
					decode_start <= 1'b1;
					get_s_prime <= 1'b1;
					
				end
			
			end
			
			S_MIC17_WAIT_M3_GET_S_PRIME: begin
		
				if (S_prime_full) begin
					get_s_prime <= 1'b0;
					M2_start <= 1'b1;
					MIC17_state <= S_MIC17_M3_M2;
				end
				
			end
			
			S_MIC17_M3_M2: begin
		
				if (M2_finish) begin
					M1_start <= 1'b1;
					M2_start <= 1'b0;
					MIC17_state <= S_MIC17_M1;
				end
			
			end
			
			S_MIC17_M1: begin
			
				if (M1_finish) begin
					M1_start <= 1'b0;
					MIC17_state <= S_MIC17_IDLE;
					Finish <= 1'b1;
				end
			
			end
			
		
		endcase
	end

end

always_comb begin

	case(MIC17_state)
	
		S_MIC17_WAIT_M3_GET_S_PRIME: begin
			SRAM_address = decode_SRAM_address;
			SRAM_write_data = decode_SRAM_write_data;
			SRAM_we_n = decode_SRAM_we_n;
		end
		
		S_MIC17_M1: begin
			SRAM_address = UCSC_SRAM_address;
			SRAM_write_data = UCSC_SRAM_write_data;
			SRAM_we_n = UCSC_SRAM_we_n;
		end
		
		S_MIC17_M3_M2: begin
			case(fill_instruction)
				1'b0: begin
					SRAM_address = IDCT_SRAM_address;
					SRAM_write_data = IDCT_SRAM_write_data;
					SRAM_we_n = IDCT_SRAM_we_n;
				end
				1'b1: begin
					SRAM_address = decode_SRAM_address;
					SRAM_write_data = decode_SRAM_write_data;
					SRAM_we_n = decode_SRAM_we_n;
				end
			endcase
		end
		
		default: begin
			SRAM_address = 18'd0;
			SRAM_write_data = 16'd0;
			SRAM_we_n = 1'b1;
		end
	
	endcase

end



endmodule
