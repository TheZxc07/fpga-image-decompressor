
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module MIC17_decoder (

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

logic [6:0] S_p_x_S_address_a, S_p_x_S_address_b;
logic [31:0] S_p_x_S_write_data_a, S_p_x_S_write_data_b, S_p_x_S_read_data_a, S_p_x_S_read_data_b;
logic S_p_x_S_write_enable_a, S_p_x_S_write_enable_b;


full_decoder_state_type decode_state;

dual_port_RAM3 S_p_x_S_RAM (
	.address_a ( S_p_x_S_address_a ),
	.address_b ( S_p_x_S_address_b ),
	.clock ( Clock ),
	.data_a ( S_p_x_S_write_data_a ),
	.data_b ( S_p_x_S_write_data_b ),
	.wren_a ( S_p_x_S_write_enable_a ),
	.wren_b ( S_p_x_S_write_enable_b ),
	.q_a ( S_p_x_S_read_data_a ),
	.q_b ( S_p_x_S_read_data_b )
	);
	

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
	
	
	
	end else begin
	
		case(decode_state)
		
			S_DECODE_IDLE: begin
			
				if (Start) begin
				
					decode_state <= S_DECODE_IDLE;
					
				end
			
			end
		
		endcase
	end

end

endmodule
