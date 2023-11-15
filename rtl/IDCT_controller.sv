
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module IDCT_controller (

   input  logic            Clock,
   input  logic            Resetn,

   input  logic   [15:0]   SRAM_read_data,
	input  logic 				Start,
	input  logic				SFull,
	
	output logic				Finish,
	//input  logic 	[9:0]	   j;

	output logic 				SRAM_we_n,
   output logic   [15:0]   SRAM_write_data,
   output logic   [17:0]   SRAM_address

);

IDCT_Controller_state_type IDCT_state;
IDCT_SRAM_state_type IS_state;

logic [5:0] M_address_a, M_address_b;
logic [4:0] S_prime_address_b, S_prime_address_a;
logic [3:0] coeff_address_a;
logic [4:0] coeff_address_b;
logic [7:0] k;
logic [31:0] S_prime_write_data_a, S_prime_write_data_b, coeff_write_data_a, coeff_write_data_b, M_write_data_a, M_write_data_b;
logic S_prime_write_enable_a, S_prime_write_enable_b, coeff_write_enable_a, coeff_write_enable_b, M_write_enable_a, M_write_enable_b;
logic [31:0] S_prime_read_data_a, S_prime_read_data_b, coeff_read_data_a, coeff_read_data_b, M_read_data_a, M_read_data_b;

logic [31:0] S_prime_data [3:0];
logic [31:0] M_data [7:0];
logic [31:0] coeff_data [3:0];

logic [31:0] S_prime_data_buf;
logic [31:0] M_data_buf [1:0];

logic [2:0] i;
logic [2:0] j;

logic fill_s_prime;
logic write_s;
logic s_prime_full;
logic op_select;
logic row_identifier;

logic start_buf;

logic matrix_select;

logic [31:0] accumulator;

logic [7:0] S_matrix [7:0];

logic [7:0] S_signal;


logic [31:0] result;

assign coeff_address_b = {1'b1, coeff_address_a};
assign M_address_b = M_address_a - 6'd1;
//assign S_prime_address_b = S_prime_address_a + 6'd1;

assign coeff_write_data_a = 32'd0;
assign coeff_write_data_b = 32'd0;
assign coeff_write_enable_a = 1'b0;
assign coeff_write_enable_b = 1'b0;

dual_port_RAM0 coeff_RAM (
	.address_a ( {3'b0, coeff_address_a} ),
	.address_b ( {2'b0, coeff_address_b} ),
	.clock ( Clock ),
	.data_a ( coeff_write_data_a ),
	.data_b ( coeff_write_data_b ),
	.wren_a ( coeff_write_enable_a ),
	.wren_b ( coeff_write_enable_b ),
	.q_a ( coeff_read_data_a ),
	.q_b ( coeff_read_data_b )
	);


dual_port_RAM1 S_prime_RAM (
	.address_a ( {1'b0, matrix_select, S_prime_address_a} ),
	.address_b ( {1'b0, ~matrix_select, S_prime_address_b} ),
	.clock ( Clock ),
	.data_a ( S_prime_write_data_a ),
	.data_b ( S_prime_write_data_b ),
	.wren_a ( S_prime_write_enable_a ),
	.wren_b ( S_prime_write_enable_b ),
	.q_a ( S_prime_read_data_a ),
	.q_b ( S_prime_read_data_b )
	);
	
dual_port_RAM2 M_RAM (
	.address_a ( {1'b0, M_address_a} ),
	.address_b ( {1'b0, M_address_b} ),
	.clock ( Clock ),
	.data_a ( M_write_data_a ),
	.data_b ( M_write_data_b ),
	.wren_a ( M_write_enable_a ),
	.wren_b ( M_write_enable_b ),
	.q_a ( M_read_data_a ),
	.q_b ( M_read_data_b )
	);	
	

logic [31:0] op1_1, op2_1, op1_2, op2_2, op1_3, op2_3, op1_4, op2_4;

logic [63:0] prod_1_long, prod_2_long, prod_3_long, prod_4_long;

logic [31:0] prod_1, prod_2, prod_3, prod_4;

assign prod_1_long = op1_1*op2_1;
assign prod_2_long = op1_2*op2_2;
assign prod_3_long = op1_3*op2_3;
assign prod_4_long = op1_4*op2_4;

assign prod_1 = prod_1_long[31:0];
assign prod_2 = prod_2_long[31:0];
assign prod_3 = prod_3_long[31:0];
assign prod_4 = prod_4_long[31:0];

assign result = prod_1 + prod_2 + prod_3 + prod_4;

always_comb begin

	S_signal = accumulator[23:16];
	
	if (|accumulator[31:24]) begin
		S_signal = 8'hFF;
	end
	if (accumulator[31]) begin
		S_signal = 8'h0;
	end

end

always_comb begin

	case(op_select)
	
		1'b0: begin
		
			case(matrix_select)
				1'b0: begin
					op1_1 = {{16{S_prime_data[0][31]}}, S_prime_data[0][31:16]};  
					op1_2 = {{16{S_prime_data[0][15]}}, S_prime_data[0][15:0]};	
					op1_3 = {{16{S_prime_data[1][31]}}, S_prime_data[1][31:16]};	
					op1_4 = {{16{S_prime_data[1][15]}}, S_prime_data[1][15:0]};	
				end
				1'b1: begin
					op1_1 = M_data[0];
					op1_2 = M_data[1];
					op1_3 = M_data[2];
					op1_4 = M_data[3];
				end
			endcase	
				
			op2_1 = {{16{coeff_data[0][31]}}, coeff_data[0][31:16]};		
			op2_2 = {{16{coeff_data[0][15]}}, coeff_data[0][15:0]};			
			op2_3 = {{16{coeff_data[1][31]}}, coeff_data[1][31:16]};		
			op2_4 = {{16{coeff_data[1][15]}}, coeff_data[1][15:0]};			
			
		end
		
		1'b1: begin
			case(matrix_select)
				1'b0: begin
					op1_1 = {{16{S_prime_data[2][31]}}, S_prime_data[2][31:16]};
					op1_2 = {{16{S_prime_data[2][15]}}, S_prime_data[2][15:0]};
					op1_3 = {{16{S_prime_data[3][31]}}, S_prime_data[3][31:16]};
					op1_4 = {{16{S_prime_data[3][15]}}, S_prime_data[3][15:0]};
				end
				1'b1: begin
					op1_1 = M_data[4];
					op1_2 = M_data[5];
					op1_3 = M_data[6];
					op1_4 = M_data[7];
				end
			endcase
				
			op2_1 = {{16{coeff_data[2][31]}}, coeff_data[2][31:16]};
			op2_2 = {{16{coeff_data[2][15]}}, coeff_data[2][15:0]};
			op2_3 = {{16{coeff_data[3][31]}}, coeff_data[3][31:16]};
			op2_4 = {{16{coeff_data[3][15]}}, coeff_data[3][15:0]};		
		
		
		end
	
	endcase

end

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
	
		op_select <= 1'b0;
		M_write_enable_b <= 1'b0;
		matrix_select <= 1'b1;
		fill_s_prime <= 1'b0;
		write_s <= 1'b0;
		
		coeff_data[3] <= 32'd0;
		coeff_data[2] <= 32'd0;
		coeff_data[1] <= 32'd0;
		coeff_data[0] <= 32'd0;
		
		S_prime_address_a <= 5'd0;
		M_address_a <= 6'd0;
		coeff_address_a <= 4'd0;
		
		S_prime_write_data_a <= 16'd0;
		S_prime_write_enable_a <= 1'b0;
		
		row_identifier <= 1'b0;
		M_write_data_a <= 32'd0;
		
		start_buf <= 1'b0;
		
		accumulator <= 32'd0;
	
		IDCT_state <= S_IDCT_IDLE;
		
	end else begin
		case(IDCT_state) 
			
			S_IDCT_IDLE: begin
				
				start_buf <= Start;
				
				if (Start & ~start_buf) begin
					
					fill_s_prime <= 1'b1;
					
					IDCT_state <= S_IDCT_WAIT_FILL_S_PRIME_DPRAM;
				end
			
			end
			
			S_IDCT_WAIT_FILL_S_PRIME_DPRAM: begin
			
				if (s_prime_full) begin
					IDCT_state <= S_IDCT_M_8x8_LEAD_IN_0;
					S_prime_address_a <= 5'd0;
					fill_s_prime <= 1'b0;
					
					coeff_address_a <= 4'd0;
					
					M_address_a <= 6'h38;
					matrix_select <= 1'b0;
					
					i <= 3'd0;
					j <= 3'd7;
				end
			
			end
			
			S_IDCT_M_8x8_LEAD_IN_0: begin
				
				S_prime_address_a <= S_prime_address_a + 5'd1;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_IN_1;
				
			end
			
			S_IDCT_M_8x8_LEAD_IN_1: begin
			
				S_prime_address_a <= S_prime_address_a + 5'd1;
				//S_prime_address_b <= S_prime_address_b + 7'd2;
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_data[0] <= S_prime_read_data_a;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_IN_2;
				
			end
			
			S_IDCT_M_8x8_LEAD_IN_2: begin
			
				S_prime_address_a <= S_prime_address_a + 5'd1;
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_data[1] <= S_prime_read_data_a;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_IN_3;
				
			end
			
			S_IDCT_M_8x8_LEAD_IN_3: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_data[2] <= S_prime_read_data_a;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_IN_4;
				
			end
			
			S_IDCT_M_8x8_LEAD_IN_4: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				S_prime_data[3] <= S_prime_read_data_a;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_IN_5;
			
			end
			
			S_IDCT_M_8x8_LEAD_IN_5: begin
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_0;
				
			end
			
			S_IDCT_M_ROW_0: begin
			
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				j <= j + 3'd1;
			
				coeff_address_a <= coeff_address_a + 4'd1;	
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_1;
			
			end
			
			S_IDCT_M_ROW_1: begin
			
				M_write_enable_a <= 1'b0;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				if (j == 3'd3) begin
					if (i == 3'd7) begin
						IDCT_state <= S_IDCT_M_8x8_LEAD_OUT_0;
					end else begin
						IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_0;
					end
				end else begin
					IDCT_state <= S_IDCT_M_ROW_0;
				end
			
			end
			
			S_IDCT_M_ROW_LEAD_OUT_0: begin
				
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				//S_prime_address_a <= S_prime_address_a + 6'd1;
				//S_prime_address_b <= S_prime_address_b + 7'd2;
	
				coeff_address_a <= coeff_address_a + 4'd1;
	
				accumulator <= result;
					
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_1;
				
			end
			
			S_IDCT_M_ROW_LEAD_OUT_1: begin
			
				M_write_enable_a <= 1'b0;
			
				S_prime_address_a <= S_prime_address_a + 5'd1;
				//S_prime_address_b <= S_prime_address_b + 7'd2;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_2;
			
			end
			
			S_IDCT_M_ROW_LEAD_OUT_2: begin
			
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				S_prime_address_a <= S_prime_address_a + 5'd1;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_3;
				
			end
			
			S_IDCT_M_ROW_LEAD_OUT_3: begin
			
				M_write_enable_a <= 1'b0;
			
				S_prime_address_a <= S_prime_address_a + 5'd1;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				S_prime_data_buf <= S_prime_read_data_a;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
			
				IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_4;
			
			end
	
			S_IDCT_M_ROW_LEAD_OUT_4: begin
			
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				S_prime_address_a <= S_prime_address_a + 5'd1;
			
				coeff_address_a <= coeff_address_a + 4'd1;	
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				S_prime_data[0] <= S_prime_data_buf;
				S_prime_data[1] <= S_prime_read_data_a;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_5;
			
			end
			
			S_IDCT_M_ROW_LEAD_OUT_5: begin
				
				M_write_enable_a <= 1'b0;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				S_prime_data[2] <= S_prime_read_data_a;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_6;
			
			end
			
			S_IDCT_M_ROW_LEAD_OUT_6: begin
			
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				coeff_address_a <= coeff_address_a + 4'd1;	
				
				accumulator <= result;
				
				op_select <= ~op_select;
	
				S_prime_data[3] <= S_prime_read_data_a;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_ROW_LEAD_OUT_7;
			
			end
			
			S_IDCT_M_ROW_LEAD_OUT_7: begin
			
				M_address_a <= M_address_a + 6'd1;
				M_write_enable_a <= 1'b0;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				i <= i + 3'd1;
				j <= 3'd7;
				
				IDCT_state <= S_IDCT_M_ROW_0;
			
			end
			
			S_IDCT_M_8x8_LEAD_OUT_0: begin
			
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				//M_address_b <= 7'd0;
				//M_write_enable_b <= 1'b0;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_OUT_1;
			
			end
			
			S_IDCT_M_8x8_LEAD_OUT_1: begin
			
				//M_address_b <= M_address_b + 6'd1;
				M_write_enable_a <= 1'b0;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_OUT_2;
				
			
			end
			
			S_IDCT_M_8x8_LEAD_OUT_2: begin
				
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				//M_address_b <= M_address_b + 6'd1;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_OUT_3;
			
			end
			
			S_IDCT_M_8x8_LEAD_OUT_3: begin
			
				M_write_enable_a <= 1'b0;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_OUT_4;
				
			end
			
			S_IDCT_M_8x8_LEAD_OUT_4: begin
			
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_OUT_5;
			
			end
			
			S_IDCT_M_8x8_LEAD_OUT_5: begin
			
				M_write_enable_a <= 1'b0;
	
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				IDCT_state <= S_IDCT_M_8x8_LEAD_OUT_6;
			
			end
			
			S_IDCT_M_8x8_LEAD_OUT_6: begin
				
				M_address_a <= M_address_a + 6'd8;
				M_write_enable_a <= 1'b1;
				M_write_data_a <= {{8{accumulator[31]}}, accumulator[31:8]};
				
				fill_s_prime <= 1'b1;
				
				i <= i + 3'd1;
				
				IDCT_state <= S_IDCT_S_8x8_LEAD_IN_0;
				
			end
			
			S_IDCT_S_8x8_LEAD_IN_0: begin
			
				write_s <= 1'b0;
			
				M_address_a <= M_address_a + 6'd2;
				M_write_enable_a <= 1'b0;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				fill_s_prime <= 1'b0;
				
				IDCT_state <= S_IDCT_S_8x8_LEAD_IN_1;
			
			end
			
			S_IDCT_S_8x8_LEAD_IN_1: begin
			
				M_address_a <= M_address_a + 6'd2;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				matrix_select <= 1'b1;
				
				IDCT_state <= S_IDCT_S_8x8_LEAD_IN_2;
			
			end
			
			S_IDCT_S_8x8_LEAD_IN_2: begin
			
				M_address_a <= M_address_a + 6'd2;
				
				M_data[0] <= M_read_data_b;
				M_data[1] <= M_read_data_a;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_8x8_LEAD_IN_3;
				
			end
			
			S_IDCT_S_8x8_LEAD_IN_3: begin
			
				M_address_a <= M_address_a + 6'd2;
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				M_data[2] <= M_read_data_b;
				M_data[3] <= M_read_data_a;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_8x8_LEAD_IN_4;
			
			end
			
			S_IDCT_S_8x8_LEAD_IN_4: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				M_data[4] <= M_read_data_b;
				M_data[5] <= M_read_data_a;
				
				IDCT_state <= S_IDCT_S_8x8_LEAD_IN_5;
			
			end
			
			S_IDCT_S_8x8_LEAD_IN_5: begin
				
				coeff_address_a <= coeff_address_a + 4'd1;
				
				M_data[6] <= M_read_data_b;
				M_data[7] <= M_read_data_a;
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_8x8_LEAD_IN_6;
			
			end
			
			S_IDCT_S_8x8_LEAD_IN_6: begin
			
				S_prime_address_a <= S_prime_address_a - 5'd3;
				
				coeff_address_a <= coeff_address_a + 4'd1;
			
				row_identifier <= 1'b0;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_0;
			
			end
			
			S_IDCT_S_COLUMN_0: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
			
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[0], S_signal};
				
				end else begin
					S_matrix[0] <= S_signal;
				end
					
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_1;
			
			end
			
			S_IDCT_S_COLUMN_1: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				S_prime_write_enable_a <= 1'b0;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_2;
			
			end
			
			S_IDCT_S_COLUMN_2: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
			
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[1], S_signal};
				
				end else begin
					S_matrix[1] <= S_signal;
				end
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
			
				IDCT_state <= S_IDCT_S_COLUMN_3;
			
			end
			
			S_IDCT_S_COLUMN_3: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_write_enable_a <= 1'b0;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_4;
			
			end
			
			S_IDCT_S_COLUMN_4: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[2], S_signal};
				
				end else begin
					S_matrix[2] <= S_signal;
				end
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_5;
			
			end
			
			S_IDCT_S_COLUMN_5: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_write_enable_a <= 1'b0;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_6;
			
			end
			
			S_IDCT_S_COLUMN_6: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[3], S_signal};
				
				end else begin
					S_matrix[3] <= S_signal;
				end
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_7;
			
			end
			
			S_IDCT_S_COLUMN_7: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_write_enable_a <= 1'b0;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_8;
			
			end
			
			S_IDCT_S_COLUMN_8: begin
			
				M_address_a <= M_address_a + 6'd2;
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[4], S_signal};
				
				end else begin
					S_matrix[4] <= S_signal;
				end
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
			
				IDCT_state <= S_IDCT_S_COLUMN_9;
			
			end
			
			S_IDCT_S_COLUMN_9: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_write_enable_a <= 1'b0;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_10;
			
			end
			
			S_IDCT_S_COLUMN_10: begin
			
				M_address_a <= M_address_a + 6'd2;
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[5], S_signal};
				
				end else begin
					S_matrix[5] <= S_signal;
				end
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				M_data_buf[0] <= M_read_data_b;
				M_data_buf[1] <= M_read_data_a;
				
				IDCT_state <= S_IDCT_S_COLUMN_11;
			
			end
			
			S_IDCT_S_COLUMN_11: begin
			
				M_address_a <= M_address_a + 6'd2;
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_write_enable_a <= 1'b0;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				IDCT_state <= S_IDCT_S_COLUMN_12;
			
			end
			
			S_IDCT_S_COLUMN_12: begin
			
				M_address_a <= M_address_a + 6'd2;
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[6], S_signal};
				
				end else begin
					S_matrix[6] <= S_signal;
				end
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				M_data[0] <= M_data_buf[0];
				M_data[1] <= M_data_buf[1];
				M_data[2] <= M_read_data_b;
				M_data[3] <= M_read_data_a;
				
				IDCT_state <= S_IDCT_S_COLUMN_13;
			
			end
			
			S_IDCT_S_COLUMN_13: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				S_prime_write_enable_a <= 1'b0;
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				M_data[4] <= M_read_data_b;
				M_data[5] <= M_read_data_a;
			
				IDCT_state <= S_IDCT_S_COLUMN_14;
			
			end
			
			S_IDCT_S_COLUMN_14: begin
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				if (row_identifier) begin
				
					S_prime_address_a <= S_prime_address_a + 5'd4;
					S_prime_write_enable_a <= 1'b1;
					S_prime_write_data_a <=  {S_matrix[7], S_signal};
				
				end else begin
					S_matrix[7] <= S_signal;
				end
				
				accumulator <= result;
				
				op_select <= ~op_select;
				
				coeff_data[0] <= coeff_read_data_a;
				coeff_data[1] <= coeff_read_data_b;
				
				M_data[6] <= M_read_data_b;
				M_data[7] <= M_read_data_a;
				
				IDCT_state <= S_IDCT_S_COLUMN_15;
			
			end
			
			
			S_IDCT_S_COLUMN_15: begin
			
				S_prime_write_enable_a <= 1'b0;
			
				coeff_address_a <= coeff_address_a + 4'd1;
				
				row_identifier <= ~row_identifier; 
				
				accumulator <= accumulator + result;
				
				op_select <= ~op_select;
				
				i <= i + 3'd1;
				
				coeff_data[2] <= coeff_read_data_a;
				coeff_data[3] <= coeff_read_data_b;
				
				if (row_identifier) begin
					S_prime_address_a <= S_prime_address_a + 5'd1;
				end
				
				if (i == 3'd7) begin
					IDCT_state <= S_IDCT_WAIT_FILL_S_PRIME_DPRAM;
					write_s <= 1'b1;
				end else begin
					IDCT_state <= S_IDCT_S_COLUMN_0;
				end
			end
			
		endcase
	end
end


logic [17:0] Y_base_addr;
assign Y_base_addr = 18'd76800;
logic [17:0] UV_base_addr;
assign UV_base_addr = 18'd153600;

logic [17:0] base_addr;


logic [5:0] element_cont;

logic [2:0] element_row_r;
logic [2:0] element_column_r;

logic [2:0] element_row_w;
logic [1:0] element_column_w;

assign element_row_r = element_cont[5:3];
assign element_column_r = element_cont[2:0];

assign element_row_w = element_cont[4:2];
assign element_column_w = element_cont[1:0];

logic [5:0] last_row_block_r;
logic [5:0] last_row_block_w;


logic [5:0] block_cont_j_r;
logic [6:0] block_cont_i_r;

logic [5:0] block_cont_j_w;
logic [6:0] block_cont_i_w;


logic [17:0] row_address_Y_r;
logic [17:0] row_address_UV_r;
logic [17:0] row_address_r;
logic [17:0] column_address_r;

logic [17:0] row_address_Y_w;
logic [17:0] row_address_UV_w;
logic [17:0] row_address_w;
logic [17:0] column_address_w;

logic segment_indicator_r;
logic segment_indicator_w;
 
logic [15:0] SRAM_data [1:0];

logic fill_s_prime_buf;

logic write_s_buf;

logic [17:0] row_address_UV;
logic [17:0] row_address_Y;

assign last_row_block_r = segment_indicator_r ? 6'd19 : 6'd39;

assign last_row_block_w = segment_indicator_w ? 6'd19 : 6'd39;

assign row_address_Y_r = {{block_cont_i_r, element_row_r}, 8'b0} + {{block_cont_i_r, element_row_r}, 6'b0};
assign row_address_UV_r = {{block_cont_i_r, element_row_r}, 7'b0} + {{block_cont_i_r, element_row_r}, 5'b0};

assign column_address_r = {block_cont_j_r, element_column_r};

assign row_address_UV_w = {{{block_cont_i_w, element_row_w}, 6'b0} + {{block_cont_i_w, element_row_w}, 4'b0}} + 17'd19200;
assign row_address_Y_w = {{block_cont_i_w, element_row_w}, 7'b0} + {{block_cont_i_w, element_row_w}, 5'b0};

assign row_address_w = segment_indicator_w ? row_address_UV_w : row_address_Y_w;
assign column_address_w = {block_cont_j_w, element_column_w};

always_comb begin

	if (segment_indicator_r) begin
	
		base_addr = UV_base_addr;
		row_address_r = row_address_UV_r;
	
	end else begin
		base_addr = Y_base_addr;
		row_address_r = row_address_Y_r;
		
	end


end

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
	
		block_cont_j_r <= 6'd0;
		block_cont_i_r <= 5'd0;
		block_cont_j_w <= 6'd0;
		block_cont_i_w <= 5'd0;
		
		s_prime_full <= 1'b0;
		
		element_cont <= 6'd0;
		
		S_prime_write_enable_b <= 1'b0;
		S_prime_write_data_b <= 32'd0;
		
		S_prime_address_b <= 5'h1F;
		fill_s_prime_buf <= 1'b0;
		
		SRAM_address <= 18'd0;
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		
		segment_indicator_r <= 1'd0;
		segment_indicator_w <= 1'd0;
		
		IS_state <= S_IS_IDLE;
	
	end else begin
	
		case(IS_state)
		
			S_IS_IDLE: begin
			
				fill_s_prime_buf <= fill_s_prime;
				write_s_buf <= write_s;
				SRAM_we_n <= 1'b1;
				if (fill_s_prime && ~fill_s_prime_buf) begin
					IS_state <= S_IS_FILL_S_PRIME_LEAD_IN_0;
					//element_cont <= 6'd0;
					s_prime_full <= 1'b0;
				end
				
				if (write_s && ~write_s_buf) begin
					IS_state <= S_IS_WRITE_S_LEAD_IN_0;
				end
			
			end
			
			S_IS_FILL_S_PRIME_LEAD_IN_0: begin
				
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_we_n <= 1'b1;
				
				IS_state <= S_IS_FILL_S_PRIME_LEAD_IN_1;
				
			end
			
			S_IS_FILL_S_PRIME_LEAD_IN_1: begin
			
				element_cont <= element_cont + 6'd1;
			
				SRAM_address <= base_addr + row_address_r + column_address_r;
				
				IS_state <= S_IS_FILL_S_PRIME_LEAD_IN_2;
				
			end
			
			S_IS_FILL_S_PRIME_LEAD_IN_2: begin
			
				element_cont <= element_cont + 6'd1;
			
				SRAM_address <= base_addr + row_address_r + column_address_r;
				
				IS_state <= S_IS_FILL_S_PRIME_LEAD_IN_3;
			
			end
			
			S_IS_FILL_S_PRIME_LEAD_IN_3: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[0] <= SRAM_read_data;
				
				IS_state <= S_IS_FILL_S_PRIME_LEAD_IN_4;
			
			end
			
			S_IS_FILL_S_PRIME_LEAD_IN_4: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[1] <= SRAM_read_data;
				
				IS_state <= S_IS_FILL_S_PRIME_0;
			
			end
			
			S_IS_FILL_S_PRIME_0: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[0] <= SRAM_read_data;
				
				S_prime_address_b <= S_prime_address_b + 5'd1;
				S_prime_write_data_b <= {SRAM_data[0], SRAM_data[1]};
				S_prime_write_enable_b <= 1'b1;
				
				IS_state <= S_IS_FILL_S_PRIME_1;
				
			end
			
			S_IS_FILL_S_PRIME_1: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[1] <= SRAM_read_data;
				
				S_prime_write_enable_b <= 1'b0;
			
				IS_state <= S_IS_FILL_S_PRIME_2;
				
			end
			
			S_IS_FILL_S_PRIME_2: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[0] <= SRAM_read_data;
				
				S_prime_address_b <= S_prime_address_b + 5'd1;
				S_prime_write_data_b <= {SRAM_data[0], SRAM_data[1]};
				S_prime_write_enable_b <= 1'b1;
			
				IS_state <= S_IS_FILL_S_PRIME_3;
			
			end
			
			S_IS_FILL_S_PRIME_3: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[1] <= SRAM_read_data;
				
				S_prime_write_enable_b <= 1'b0;
				
				IS_state <= S_IS_FILL_S_PRIME_4;
			
			end
			
			S_IS_FILL_S_PRIME_4: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[0] <= SRAM_read_data;
				
				S_prime_address_b <= S_prime_address_b + 5'd1;
				S_prime_write_data_b <= {SRAM_data[0], SRAM_data[1]};
				S_prime_write_enable_b <= 1'b1;
				
				IS_state <= S_IS_FILL_S_PRIME_5;
			
			end
			
			S_IS_FILL_S_PRIME_5: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[1] <= SRAM_read_data;
				
				S_prime_write_enable_b <= 1'b0;
				
				IS_state <= S_IS_FILL_S_PRIME_6;
			
			end
			
			S_IS_FILL_S_PRIME_6: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[0] <= SRAM_read_data;
				
				S_prime_address_b <= S_prime_address_b + 5'd1;
				S_prime_write_data_b <= {SRAM_data[0], SRAM_data[1]};
				S_prime_write_enable_b <= 1'b1;
			
				IS_state <= S_IS_FILL_S_PRIME_7;
			
			end
			
			S_IS_FILL_S_PRIME_7: begin
			
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= base_addr + row_address_r + column_address_r;
				SRAM_data[1] <= SRAM_read_data;
				
				S_prime_write_enable_b <= 1'b0;
				
				if (element_cont == 6'd68) begin
					s_prime_full <= 1'b1;
					IS_state <= S_IS_IDLE;
					element_cont <= 6'd0;
					if (block_cont_j_r == last_row_block_r) begin
						block_cont_j_r <= 6'd0;
						if (block_cont_i_r == 7'd29 && ~segment_indicator_r) begin
							block_cont_i_r <= 5'd0;
							segment_indicator_r <= 1'b1;
						end else begin
							block_cont_i_r <= block_cont_i_r + 5'd1;
						end
					end else begin
						block_cont_j_r <= block_cont_j_r + 6'd1;
					end
				end else begin
					IS_state <= S_IS_FILL_S_PRIME_0;
				end
			
			end
			
			S_IS_WRITE_S_LEAD_IN_0: begin
			
				S_prime_address_b <= S_prime_address_b + 5'd1;
				
				IS_state <= S_IS_WRITE_S_LEAD_IN_1;
			
			end
			
			S_IS_WRITE_S_LEAD_IN_1: begin
			
				S_prime_address_b <= S_prime_address_b + 5'd1;
				
				IS_state <= S_IS_WRITE_S_0;
			
			end
			
			S_IS_WRITE_S_0: begin
			
				S_prime_address_b <= S_prime_address_b + 5'd1;
				
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= row_address_w + column_address_w;
				SRAM_write_data <= S_prime_read_data_b[15:0];
				SRAM_we_n = 1'b0;
				
				IS_state <= S_IS_WRITE_S_1;
			
			end
			
			S_IS_WRITE_S_1: begin
			
				S_prime_address_b <= S_prime_address_b + 5'd1;
				
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= row_address_w + column_address_w;
				SRAM_write_data <= S_prime_read_data_b[15:0];
				
				IS_state <= S_IS_WRITE_S_2;
					
			end
			
			S_IS_WRITE_S_2: begin
			
				S_prime_address_b <= S_prime_address_b + 5'd1;
				
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= row_address_w + column_address_w;
				SRAM_write_data <= S_prime_read_data_b[15:0];
				
				IS_state <= S_IS_WRITE_S_3;
				
			end
			
			S_IS_WRITE_S_3: begin
				
				element_cont <= element_cont + 6'd1;
				
				SRAM_address <= row_address_w + column_address_w;
				SRAM_write_data <= S_prime_read_data_b[15:0];
				
				if (element_cont == 5'd31) begin
					IS_state <= S_IS_IDLE;
					S_prime_address_b <= S_prime_address_b - 5'd1;
					element_cont <= 6'd0;
					if (block_cont_j_w == last_row_block_w) begin
						block_cont_j_w <= 6'd0;
						if (block_cont_i_w == 7'd29) begin
							//segment_indicator <= segment_indicator + 2'd1;
							//block_cont_i_w <= 5'd0;
							segment_indicator_w <= 1'b1;
						end else begin
							//block_cont_i_w <= block_cont_i_w + 5'd1;
						end
						block_cont_i_w <= block_cont_i_w + 5'd1;
					end else begin
						block_cont_j_w <= block_cont_j_w + 6'd1;
					end
				end else begin
					S_prime_address_b <= S_prime_address_b + 5'd1;
					IS_state <= S_IS_WRITE_S_0;
				end
			end
		
		endcase
	end

end

endmodule
