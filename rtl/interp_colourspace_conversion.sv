
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module interp_colourspace_conversion (

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

ucsc_state_type UCSC_state;


logic [15:0] Y;
logic [7:0] FIR_bufU [5:0];
logic [7:0] FIR_bufV [5:0];

logic [7:0] U_buf;
logic [7:0] V_buf;

logic [15:0] UCSC_sram_data [1:0];
logic [7:0] UCSC_sram_data_buf [1:0];

logic [7:0] upsampled_U;
logic [7:0] upsampled_V;
logic [31:0] U_accumulator;
logic [31:0] V_accumulator;

logic [17:0] SRAM_address_RGB;

logic [17:0] SRAM_address_Y;
logic [17:0] SRAM_address_U;
logic [17:0] SRAM_address_V;

logic [8:0] i;
logic [8:0] j;

logic [1:0] coefficient_select_V;
logic [1:0] coefficient_select_U;

logic [2:0] coefficient_select_RGB;
logic [1:0] op_select_RGB;
logic [2:0] op_select_RGB_O;

logic [31:0] R_accumulator_E;
logic [31:0] G_accumulator_E;
logic [31:0] B_accumulator_E;

logic [31:0] R_accumulator_O;
logic [31:0] G_accumulator_O;
logic [31:0] B_accumulator_O;

logic [31:0] cache_E;
logic [31:0] cache_O;

logic [31:0] op1_1;
logic [31:0] op2_1;

logic [15:0] op1_2;
logic [15:0] op2_2;

logic [15:0] op1_3;
logic [15:0] op2_3;

logic [31:0] op1_4;
logic [31:0] op2_4;

logic [63:0] prod_1;
logic [31:0] prod_2;
logic [31:0] prod_3;
logic [63:0] prod_4;
 
assign prod_1 = op1_1*op2_1;
assign prod_2 = op1_2*op2_2;
assign prod_3 = op1_3*op2_3;
assign prod_4 = op1_4*op2_4;

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
		SRAM_address <= 18'h0;
		SRAM_write_data <= 16'd0;
		
		V_accumulator <= 32'h0;
		U_accumulator <= 32'h0;
		Y <= 16'h0;
		
		upsampled_V <= 8'd0;
		upsampled_U <= 8'd0;
		
		SRAM_address_RGB <= 18'd146944;
		SRAM_address_Y <= 18'd0;
		SRAM_address_U <= 18'd38400;
		SRAM_address_V <= 18'd57600;
		SRAM_we_n <= 1'b1;

		UCSC_sram_data[0] <= 16'h0;
		UCSC_sram_data[1] <= 16'h0;
		
		R_accumulator_E <= 32'h0;
		G_accumulator_E <= 32'h0;
		B_accumulator_E <= 32'h0;
		
		R_accumulator_O <= 32'h0;
		G_accumulator_O <= 32'h0;
		B_accumulator_O <= 32'h0;
		
		coefficient_select_V <= 2'b0;
		coefficient_select_U <= 2'b0;
		
		coefficient_select_RGB <= 3'b0;
		op_select_RGB <= 3'd0;
			
		for (int i=0; i<6; i+=1) begin
			FIR_bufU[i] <= 8'd0;
			FIR_bufV[i] <= 8'd0;
		end
		
		i <= 9'd0;
		j <= 9'd0;
		
		UCSC_state <= S_UCSC_IDLE;
		
	end else begin
		case(UCSC_state)
			S_UCSC_IDLE: begin
				if (Start) begin
					SRAM_address_RGB <= 18'd146944;
					SRAM_address_Y <= 18'd0;
					SRAM_address_U <= 18'd38400;
					SRAM_address_V <= 18'd57600;
					Finish <= 1'b0;
					j <= 9'd0;
					i <= 9'd0;
					
					UCSC_state <= S_LEAD_IN_DELAY_0;
				end
			end
			S_LEAD_IN_DELAY_0: begin
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
				SRAM_we_n <= 1'b1;
				
				UCSC_state <= S_LEAD_IN_DELAY_1;
			end
			S_LEAD_IN_DELAY_1: begin
				SRAM_address <= SRAM_address_V;
				SRAM_address_V <= SRAM_address_V + 18'd1;
				
				UCSC_state <= S_LEAD_IN_DELAY_2;
			end
			S_LEAD_IN_DELAY_2: begin
				SRAM_address <= SRAM_address_U;
				SRAM_address_U <= SRAM_address_U + 18'd1;
				
				UCSC_state <= S_LEAD_IN_DELAY_3;
			end
			S_LEAD_IN_DELAY_3: begin
				SRAM_address <= SRAM_address_V;
				SRAM_address_V <= SRAM_address_V + 18'd1;
				
				Y <= SRAM_read_data;
				
				UCSC_state <= S_LEAD_IN_DELAY_4;
			end
			S_LEAD_IN_DELAY_4: begin
				SRAM_address <= SRAM_address_U;
				SRAM_address_U <= SRAM_address_U + 18'd1;
				
				UCSC_sram_data[0] <= SRAM_read_data;
				
				UCSC_state <= S_LEAD_IN_DELAY_5;
			end
			S_LEAD_IN_DELAY_5: begin
				SRAM_address <= SRAM_address_V;
				SRAM_address_V <= SRAM_address_V + 18'd1;
			
				UCSC_sram_data[1] <= SRAM_read_data;
				
				FIR_bufV[5] <= UCSC_sram_data[0][15:8];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				UCSC_state <= S_LEAD_IN_DELAY_6;
				
			end
			S_LEAD_IN_DELAY_6: begin
			
				SRAM_address <= SRAM_address_U;
				SRAM_address_U <= SRAM_address_U + 18'd1;
				
				UCSC_sram_data[0] <= SRAM_read_data;
				
				FIR_bufV[5] <= UCSC_sram_data[0][7:0];
				FIR_bufU[5] <= UCSC_sram_data[1][15:8];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				UCSC_state <= S_LEAD_IN_DELAY_7;
				
			end
			S_LEAD_IN_DELAY_7: begin
				
				UCSC_sram_data[1] <= SRAM_read_data;
			
				FIR_bufV[5] <= UCSC_sram_data[0][15:8];
				FIR_bufU[5] <= UCSC_sram_data[1][7:0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				UCSC_state <= S_LEAD_IN_DELAY_8;
				
			end
			S_LEAD_IN_DELAY_8: begin
			
				UCSC_sram_data[0] <= SRAM_read_data;
				
				FIR_bufV[5] <= UCSC_sram_data[0][7:0];
				FIR_bufU[5] <= UCSC_sram_data[1][15:8];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				UCSC_state <= S_LEAD_IN_DELAY_9;
			
			end
			S_LEAD_IN_DELAY_9: begin
			
				UCSC_sram_data[1] <= SRAM_read_data;
				
				FIR_bufV[5] <= UCSC_sram_data[0][15:8];
				FIR_bufU[5] <= UCSC_sram_data[1][7:0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				UCSC_state <= S_LEAD_IN_DELAY_10;
		
			end	
			S_LEAD_IN_DELAY_10: begin
			
				FIR_bufV[5] <= UCSC_sram_data[0][7:0];
				FIR_bufU[5] <= UCSC_sram_data[1][15:8];
			
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_V <= 2'd0;
				
				UCSC_state <= S_LEAD_IN_DELAY_11;
				
			end
			S_LEAD_IN_DELAY_11: begin
				
				SRAM_address <= SRAM_address_V;
				SRAM_address_V <= SRAM_address_V + 18'd1;
				
				SRAM_we_n <= 1'b1;
				
				FIR_bufU[5] <= UCSC_sram_data[1][7:0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_V <= 2'd1;
				coefficient_select_U <= 2'd0;
				
				V_accumulator <= 16'd128 + prod_2;
					
				UCSC_state <= S_LEAD_IN_DELAY_12;	
					
			end
			S_LEAD_IN_DELAY_12: begin
			
				SRAM_address <= SRAM_address_U;
				SRAM_address_U <= SRAM_address_U + 18'd1;
			
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3;
				
				V_buf <= FIR_bufV[0];
				U_buf <= FIR_bufU[0];
				
				UCSC_state <= S_LEAD_IN_DELAY_13;
				
			end
			S_LEAD_IN_DELAY_13: begin
				
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
			
				coefficient_select_U <= 2'd2;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				UCSC_state <= S_LEAD_IN_DELAY_14;
				
			end
			S_LEAD_IN_DELAY_14: begin
			
				UCSC_sram_data[0] <= SRAM_read_data;
				
				FIR_bufV[5] <= FIR_bufV[0];
				FIR_bufU[5] <= FIR_bufU[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_V <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				UCSC_state <= S_LEAD_IN_DELAY_15;
			
			end
			S_LEAD_IN_DELAY_15: begin
			
				UCSC_sram_data[1] <= SRAM_read_data;
				
				FIR_bufV[5] <= FIR_bufV[0];
				FIR_bufU[5] <= FIR_bufU[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				UCSC_state <= S_LEAD_IN_DELAY_16;
				
			end
			S_LEAD_IN_DELAY_16: begin
			
				FIR_bufV[5] <= FIR_bufV[0];
				FIR_bufU[5] <= FIR_bufU[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_U <= 2'd0;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				UCSC_state <= S_LEAD_IN_DELAY_17;
			
			end
			S_LEAD_IN_DELAY_17: begin
			
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[5] <= FIR_bufU[0];
			
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				upsampled_V <= V_accumulator[15:8];
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;
				
				V_accumulator <= 32'd128 + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				//j <= j + 9'd2;
				
				UCSC_state <= S_LEAD_IN_DELAY_18;
			
			end
			S_LEAD_IN_DELAY_18: begin
			
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
			
				upsampled_U <= U_accumulator[15:8];
				
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3; 
				
				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				G_accumulator_E <= prod_1[31:0];
				G_accumulator_O <= prod_4[31:0];
				
				B_accumulator_E <= prod_1[31:0];
				B_accumulator_O <= prod_4[31:0];
			
				UCSC_state <= S_LEAD_IN_DELAY_19;
			
			end
			S_LEAD_IN_DELAY_19: begin
			
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_U <= 2'd2;
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_IN_DELAY_20;
			
			end
			S_LEAD_IN_DELAY_20: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
			
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;
			
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_IN_DELAY_21;
				
			end
			S_LEAD_IN_DELAY_21: begin
			
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
					
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;
				
				UCSC_sram_data_buf[1] <= FIR_bufU[5];
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_IN_DELAY_22;
			
			end
			S_LEAD_IN_DELAY_22: begin
			
				coefficient_select_U <= 2'd0;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_COMMON_CASE_23;
			
			end
			S_COMMON_CASE_23: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				SRAM_we_n <= 1'b0;
				
				Y <= SRAM_read_data;
				
				if (j > 9'b0)
					FIR_bufU[5] <= UCSC_sram_data_buf[1];
				FIR_bufV[5] <= UCSC_sram_data[0][15:8];
			
				for (int i = 4; i >= 0; i-=1) begin
					if (j > 9'b0)
						FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				upsampled_V <= V_accumulator[15:8];
				V_buf <= FIR_bufV[1];
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;
				
				V_accumulator <= 32'd128 + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				j <= j + 9'd2;
				
				UCSC_state <= S_COMMON_CASE_24;
				
			end
			S_COMMON_CASE_24: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};
				
				FIR_bufU[5] <= UCSC_sram_data[1][15:8];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
							
				upsampled_U <= U_accumulator[15:8];
				U_buf <= FIR_bufU[1];
				
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3;
				
				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				cache_E <= prod_1[31:0];
				cache_O <= prod_4[31:0];
				
				UCSC_state <= S_COMMON_CASE_25;
			
			end
			S_COMMON_CASE_25: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};

				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_U <= 2'd2;
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;	
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
				G_accumulator_E <= cache_E;
				G_accumulator_O <= cache_O;
				
				B_accumulator_E <= cache_E;
				B_accumulator_O <= cache_O;
				
				UCSC_state <= S_COMMON_CASE_26;
			
			end
			S_COMMON_CASE_26: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
				
				SRAM_we_n <= 1'b1;
				
				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_COMMON_CASE_27;
			
			end
			S_COMMON_CASE_27: begin
			
				SRAM_address <= SRAM_address_V;
				SRAM_address_V <= SRAM_address_V + 18'd1;
				
				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;	
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_COMMON_CASE_28;
			
			end
			S_COMMON_CASE_28: begin
			
				SRAM_address <= SRAM_address_U;
				SRAM_address_U <= SRAM_address_U + 18'd1;

				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_U <= 2'd0;
		
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_COMMON_CASE_29;
				
			end
			S_COMMON_CASE_29: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_we_n <= 1'b0;
				
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				
				Y <= SRAM_read_data;
				
				UCSC_sram_data_buf[0] <= UCSC_sram_data[0][7:0];
				UCSC_sram_data_buf[1] <= UCSC_sram_data[1][7:0];
				
				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[0] <= FIR_bufV[5];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
				
				upsampled_V <= V_accumulator[15:8];
				V_buf <= FIR_bufV[2];

				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;	
				
				V_accumulator <= 32'd128 + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				j <= j + 9'd2;
			
				UCSC_state <= S_COMMON_CASE_30;
			
			end
			S_COMMON_CASE_30: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};

				UCSC_sram_data[0] <= SRAM_read_data;
				
				FIR_bufU[0] <= FIR_bufU[5];
				FIR_bufV[0] <= FIR_bufV[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
				
				upsampled_U <= U_accumulator[15:8];
				U_buf <= FIR_bufU[2];
				
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;	
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3;

				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				cache_E <= prod_1[31:0];
				cache_O <= prod_4[31:0];
			
				UCSC_state <= S_COMMON_CASE_31;
			
			end
			S_COMMON_CASE_31: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};
				
				UCSC_sram_data[1] <= SRAM_read_data;
			
				FIR_bufU[0] <= FIR_bufU[5];
				FIR_bufV[0] <= FIR_bufV[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
				
				coefficient_select_U <= 2'd2;
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;	
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
					
				G_accumulator_E <= cache_E;
				G_accumulator_O <= cache_O;
				
				B_accumulator_E <= cache_E;
				B_accumulator_O <= cache_O;
				
				UCSC_state <= S_COMMON_CASE_32;
		
			end
			S_COMMON_CASE_32: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
				
				SRAM_we_n <= 1'b1;

				FIR_bufU[0] <= FIR_bufU[5];
				FIR_bufV[0] <= FIR_bufV[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;	
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_COMMON_CASE_33;
				
			end
			S_COMMON_CASE_33: begin
			
				FIR_bufU[0] <= FIR_bufU[5];
				FIR_bufV[0] <= FIR_bufV[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
				
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;				
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;

				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];

				UCSC_state <= S_COMMON_CASE_34;
				
			end
			S_COMMON_CASE_34: begin
			
				FIR_bufU[0] <= FIR_bufU[5];
				FIR_bufV[5] <= UCSC_sram_data_buf[0];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_U <= 2'd0;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
				
				if (j == 9'd308) begin
					UCSC_state <= S_LEAD_OUT_35;
				end else begin
					UCSC_state <= S_COMMON_CASE_23;
				end
				
			end
			S_LEAD_OUT_35: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				SRAM_we_n <= 1'b0;
				
				Y <= SRAM_read_data;
				
				FIR_bufU[5] <= UCSC_sram_data_buf[1];
				FIR_bufV[5] <= UCSC_sram_data[0][15:8];
			
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				upsampled_V <= V_accumulator[15:8];
				V_buf <= FIR_bufV[1];
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;
				
				V_accumulator <= 32'd128 + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				j <= j + 9'd2;
				
				UCSC_state <= S_LEAD_OUT_36;
			
			end
			S_LEAD_OUT_36: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};
				
				FIR_bufU[5] <= UCSC_sram_data[1][15:8];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
							
				upsampled_U <= U_accumulator[15:8];
				U_buf <= FIR_bufU[1];
				
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3;
				
				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				cache_E <= prod_1[31:0];
				cache_O <= prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_37;
			
			
			end
			S_LEAD_OUT_37: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};

				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_U <= 2'd2;
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;	
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
				G_accumulator_E <= cache_E;
				G_accumulator_O <= cache_O;
				
				B_accumulator_E <= cache_E;
				B_accumulator_O <= cache_O;
				
				UCSC_state <= S_LEAD_OUT_38;
			
			end
			S_LEAD_OUT_38: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
				
				SRAM_we_n <= 1'b1;
				
				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_OUT_39;
			
			end
			S_LEAD_OUT_39: begin
			
				SRAM_address <= SRAM_address_V;
				SRAM_address_V <= SRAM_address_V + 18'd1;
				
				FIR_bufU[5] <= FIR_bufU[0];
				FIR_bufV[5] <= FIR_bufV[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;	
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_OUT_40;
			
			end
			S_LEAD_OUT_40: begin
				
				SRAM_address <= SRAM_address_U;
				SRAM_address_U <= SRAM_address_U + 18'd1;
				
				FIR_bufU[5] <= FIR_bufU[0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_U <= 2'd0;
		
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_41;
			
			end
			S_LEAD_OUT_41: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				SRAM_we_n <= 1'b0;
				
				Y <= SRAM_read_data;
				
				UCSC_sram_data_buf[0] <= UCSC_sram_data[0][7:0];
				UCSC_sram_data_buf[1] <= UCSC_sram_data[1][7:0];
				
				V_buf <= FIR_bufV[3];
				U_buf <= FIR_bufU[3];
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;
				
				upsampled_V <= V_accumulator[15:8];
				
				V_accumulator <= 32'd128 + prod_2;
				U_accumulator <= U_accumulator + prod_3;
		
				UCSC_state <= S_LEAD_OUT_42;
			
			end
			S_LEAD_OUT_42: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};
			
				UCSC_sram_data[0] <= SRAM_read_data;
			
				FIR_bufV[0] <= FIR_bufV[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
			
				upsampled_U <= U_accumulator[15:8];
				
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3;
				
				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				cache_E <= prod_1[31:0];
				cache_O <= prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_43;
			
			end
			S_LEAD_OUT_43: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};
				
				UCSC_sram_data[1] <= SRAM_read_data;
				
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_U <= 2'd2;
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
				G_accumulator_E <= cache_E;
				G_accumulator_O <= cache_O;
				
				B_accumulator_E <= cache_E;
				B_accumulator_O <= cache_O;
				
				UCSC_state <= S_LEAD_OUT_44;
				
			end
			S_LEAD_OUT_44: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
			
				SRAM_we_n <= 1'b1;
				
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_45;
			
			end
			S_LEAD_OUT_45: begin
			
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_46;
			
			end
			S_LEAD_OUT_46: begin
			
				FIR_bufV[5] <= UCSC_sram_data_buf[0];
				FIR_bufU[0] <= FIR_bufU[5];
				

				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_U <= 2'd0;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_47;
				
			end
			S_LEAD_OUT_47: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				SRAM_we_n <= 1'b0;
				
				Y <= SRAM_read_data;
			
				FIR_bufV[5] <= FIR_bufV[0];
				FIR_bufU[5] <= UCSC_sram_data_buf[1];
			
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				upsampled_V <= V_accumulator[15:8];
				
				V_buf <= FIR_bufV[1];
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;
				
				V_accumulator <= 32'd128 + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				UCSC_state <= S_LEAD_OUT_48;
			
			end
			S_LEAD_OUT_48: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};
			
				FIR_bufV[5] <= FIR_bufV[0];
				FIR_bufU[5] <= FIR_bufU[0];

				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				upsampled_U <= U_accumulator[15:8]; 
				
				U_buf <= FIR_bufU[1];
				
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3;

				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				cache_E <= prod_1[31:0];
				cache_O <= prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_49;
				
			end
			S_LEAD_OUT_49: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};
			
				FIR_bufV[5] <= FIR_bufV[0];
				FIR_bufU[5] <= FIR_bufU[0];

				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_U <= 2'd2;
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
				G_accumulator_E <= cache_E;
				G_accumulator_O <= cache_O;
				
				B_accumulator_E <= cache_E;
				B_accumulator_O <= cache_O;
				
				UCSC_state <= S_LEAD_OUT_50;
				
			end
			S_LEAD_OUT_50: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
			
				SRAM_we_n <= 1'b1;
				
				FIR_bufU[5] <= FIR_bufU[0];

				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufU[i] <= FIR_bufU[i+1];
				end	
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_51;
			
			end
			S_LEAD_OUT_51: begin
			
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;
			
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_52;
			
			end
			S_LEAD_OUT_52: begin
			
				coefficient_select_U <= 2'd0;
			
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_OUT_53;
			
			end
			S_LEAD_OUT_53: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
				
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				SRAM_we_n <= 1'b0;
				
				Y <= SRAM_read_data;
			
				upsampled_V <= V_accumulator[15:8];
				
				V_buf <= FIR_bufV[5];
				U_buf <= FIR_bufU[5];
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;
			
				V_accumulator <= 32'd128 + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				UCSC_state <= S_LEAD_OUT_54;
			
			end
			S_LEAD_OUT_54: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};
			
				upsampled_U <= U_accumulator[15:8];
				
				coefficient_select_V <= 2'd2;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;
			
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= 32'd128 + prod_3;
				
				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				cache_E <= prod_1[31:0];
				cache_O <= prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_55;
			
			end
			S_LEAD_OUT_55: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};
				
				coefficient_select_U <= 2'd2;
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;
			
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
				G_accumulator_E <= cache_E;
				G_accumulator_O <= cache_O;
				
				B_accumulator_E <= cache_E;
				B_accumulator_O <= cache_O;
				
				UCSC_state <= S_LEAD_OUT_56;
			
			end
			S_LEAD_OUT_56: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
				
				SRAM_we_n <= 1'b1;
			
				FIR_bufV[0] <= FIR_bufV[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
				end
				
				coefficient_select_V <= 2'd1;
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_57;
			
			end
			S_LEAD_OUT_57: begin
			
				SRAM_address <= SRAM_address_V;
				SRAM_address_V <= SRAM_address_V + 18'd1;

				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_V <= 2'd0;
				coefficient_select_U <= 2'd1;
				
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_OUT_58;
			
			end
			S_LEAD_OUT_58: begin
			
				SRAM_address <= SRAM_address_U;
				SRAM_address_U <= SRAM_address_U + 18'd1;
			
				FIR_bufV[0] <= FIR_bufV[5];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufV[i] <= FIR_bufV[i-1];
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				coefficient_select_U <= 2'd0;
				
				V_accumulator <= V_accumulator + prod_2;
				U_accumulator <= U_accumulator + prod_3;
			
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_OUT_59;
			
			end
			S_LEAD_OUT_59: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				SRAM_we_n <= 1'b0;
				
				Y <= SRAM_read_data;
			
				FIR_bufV[5] <= UCSC_sram_data[0][15:8];
				FIR_bufU[0] <= FIR_bufU[5];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
				end
				for (int i = 1; i <= 5; i+=1) begin
					FIR_bufU[i] <= FIR_bufU[i-1];
				end
				
				upsampled_V <= V_accumulator[15:8];
				
				coefficient_select_RGB <= 3'd0;
				op_select_RGB <= 2'd0;
				
				U_accumulator <= U_accumulator + prod_3;
				
				UCSC_state <= S_LEAD_OUT_60;
			
			end
			S_LEAD_OUT_60: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};
			
				UCSC_sram_data[0] <= SRAM_read_data;
			
				FIR_bufV[5] <= UCSC_sram_data[0][7:0];
				FIR_bufU[5] <= UCSC_sram_data[1][15:8];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				upsampled_U <= U_accumulator[15:8]; 
				
				V_buf <= FIR_bufV[2];
				
				coefficient_select_RGB <= 3'd1;
				op_select_RGB <= 2'd1;
				
				R_accumulator_E <= prod_1[31:0];
				R_accumulator_O <= prod_4[31:0];
				
				cache_E <= prod_1[31:0];
				cache_O <= prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_61;

			end
			S_LEAD_OUT_61: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};
				
				UCSC_sram_data[1] <= SRAM_read_data;
			
				FIR_bufV[5] <= UCSC_sram_data[0][15:8];
				FIR_bufU[5] <= UCSC_sram_data[1][7:0];
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				U_buf <= FIR_bufU[2];
				
				coefficient_select_RGB <= 3'd2;
				op_select_RGB <= 2'd2;
				
				R_accumulator_E <= R_accumulator_E + prod_1[31:0];
				R_accumulator_O <= R_accumulator_O + prod_4[31:0];
				
				G_accumulator_E <= cache_E;
				G_accumulator_O <= cache_O;
				
				B_accumulator_E <= cache_E;
				B_accumulator_O <= cache_O;
				
				UCSC_state <= S_LEAD_OUT_62;
				
			end
			S_LEAD_OUT_62: begin
			
				FIR_bufV[5] <= UCSC_sram_data[0][7:0];
				FIR_bufU[5] <= UCSC_sram_data[1][15:8];
				
				SRAM_we_n <= 1'b1;
				
				for (int i = 4; i >= 0; i-=1) begin
					FIR_bufV[i] <= FIR_bufV[i+1];
					FIR_bufU[i] <= FIR_bufU[i+1];
				end
				
				coefficient_select_RGB <= 3'd3;
				op_select_RGB <= 2'd1;
				
				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
				
				UCSC_state <= S_LEAD_OUT_63;
			
			end
			S_LEAD_OUT_63: begin
			
				coefficient_select_RGB <= 3'd4;
				op_select_RGB <= 2'd2;

				G_accumulator_E <= G_accumulator_E + prod_1[31:0];
				G_accumulator_O <= G_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_OUT_64;
			
			end
			S_LEAD_OUT_64: begin
			
				SRAM_address <= SRAM_address_Y;
				SRAM_address_Y <= SRAM_address_Y + 18'd1;
			
				coefficient_select_V <= 2'd0;
			
				B_accumulator_E <= B_accumulator_E + prod_1[31:0];
				B_accumulator_O <= B_accumulator_O + prod_4[31:0];
			
				UCSC_state <= S_LEAD_OUT_65;
			
			end
			S_LEAD_OUT_65: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {R_accumulator_E[23:16], G_accumulator_E[23:16]};
				SRAM_we_n <= 1'b0;
			
				UCSC_state <= S_LEAD_OUT_66;
			
			end
			S_LEAD_OUT_66: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {B_accumulator_E[23:16], R_accumulator_O[23:16]};
			
				UCSC_state <= S_LEAD_OUT_67;
			
			end
			S_LEAD_OUT_67: begin
			
				SRAM_address <= SRAM_address_RGB;
				SRAM_address_RGB <= SRAM_address_RGB + 18'd1;
			
				SRAM_write_data <= {G_accumulator_O[23:16], B_accumulator_O[23:16]};
				
				Y <= SRAM_read_data;
				
				coefficient_select_V <= 2'd0;
			
				if (i == 9'd239) begin
					UCSC_state <= S_UCSC_IDLE;
					Finish <= 1'b1;
				end else begin
					j <= 9'd0;
					i <= i + 9'd1;
					UCSC_state <= S_LEAD_IN_DELAY_11;
				end
			
			end
			default: UCSC_state <= S_UCSC_IDLE;
		endcase
	end
end

always_comb begin
	
	case(coefficient_select_RGB)
		
		3'd0 : begin
			op1_1 = 32'd76284;
			op1_4 = 32'd76284;
		end
		3'd1 : begin
			op1_1 = 32'd104595;
			op1_4 = 32'd104595;
		end
		3'd2 : begin
			op1_1 = -32'd25624;
			op1_4 = -32'd25624;
		end
		3'd3 : begin
			op1_1 = -32'd53281;
			op1_4 = -32'd53281;
		end
		3'd4 : begin
			op1_1 = 32'd132251;
			op1_4 = 32'd132251;
		end
		
		default: begin
			op1_1 = 32'd0;
			op1_4 = 32'd0;
		end
	endcase
	
end

always_comb begin

	case(coefficient_select_V)
	
		2'd0  : op1_2 = 16'd21;
		2'd1	: op1_2 = -16'd52;
		2'd2	: op1_2 = 16'd159;
		
		default op1_2 = 16'd0;
	endcase

end

always_comb begin

	case(coefficient_select_U)
	
		2'd0 : op1_3 = 16'd21;
		2'd1	: op1_3 = -16'd52;
		2'd2	: op1_3 = 16'd159;
		
		default op1_3 = 16'd0;
	endcase

end

assign op2_2 = {{8{1'b0}}, FIR_bufV[0]};
assign op2_3 = {{8{1'b0}}, FIR_bufU[0]};

logic [31:0] Y_E_long;
logic [31:0] Y_O_long;
logic [31:0] V_long;
logic [31:0] upsampled_V_long;
logic [31:0] U_long;
logic [31:0] upsampled_U_long;

assign Y_E_long = {{24{1'b0}}, Y[15:8]};
assign Y_O_long = {{24{1'b0}}, Y[7:0]};

assign V_long = {{24{1'b0}}, V_buf};
assign upsampled_V_long = {{24{1'b0}}, upsampled_V};

assign U_long = {{24{1'b0}}, U_buf};
assign upsampled_U_long = {{24{1'b0}}, upsampled_U};

always_comb begin

	case(op_select_RGB)
	
		2'd0 : begin
			op2_1 = Y_E_long - 32'd16;
			op2_4 = Y_O_long - 32'd16;
		end
		
		2'd1 : begin
			op2_1 = V_long - 32'd128;
			op2_4 = upsampled_V_long - 32'd128;
		end
		
		2'd2 : begin
			op2_1 = U_long - 32'd128;
			op2_4 = upsampled_U_long - 32'd128;
		end

	
	endcase
end


endmodule
