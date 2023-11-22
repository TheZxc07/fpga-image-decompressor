`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module decode_controller (

   input  logic            Clock,
   input  logic            Resetn,

   input  logic   [15:0]   SRAM_read_data,
	input  logic 				Start,
	input  logic 				Get_S_prime,
	input  logic				quantization_matrix,
	//input  logic 	[9:0]	   j;

	output logic	[6:0]		RAM_address,
	output logic	[15:0]	RAM_write_data,
	output logic				RAM_write_enable,
	
	output logic				S_prime_loaded,
	
	output logic 				SRAM_we_n,
   output logic   [15:0]   SRAM_write_data,
   output logic   [17:0]   SRAM_address

);

decoder_state_type decode_state;

decoder_SRAM_state_type decode_SRAM_state;

decoder_SRAM_request_state_type decode_SRAM_request_state_0;
decoder_SRAM_request_state_type decode_SRAM_request_state_1;

logic [17:0] bitstream_base_address;

//logic [6:0] RAM_address;

logic [5:0] RAM_address_main;
logic RAM_segment;

logic [4:0] index_ptr;
logic [5:0] access_index;

assign access_index = index_ptr + 5'd16;

logic [31:0] SR;

logic load_buf;
logic load;

logic get_s_prime_buf;
logic start_buf;

//logic quantization_matrix;

logic [15:0] dequantized_data;

logic [15:0] SRAM_data_buf_0;
logic [15:0] SRAM_data_buf_1;
logic [5:0] element_cont;

logic [4:0] next_index;

logic [2:0] count;

logic lhp;

logic [47:0] access_wire;
assign access_wire = {SR, SR[31:16]};

wire [8:0] data_00x = access_wire[access_index-5'd2 -: 9];
wire [3:0] data_01x = access_wire[access_index-5'd2 -: 4];
wire [15:0] data_100 = access_wire[access_index-5'd3 -: 2];
wire [15:0] data_101 = access_wire[access_index-5'd3 -: 2];
wire [15:0] data_110 = access_wire[access_index-5'd3 -: 3];

logic [15:0] data;
logic [2:0] k; 

logic setup_done;

logic [2:0] code;

assign bitstream_base_address = 18'd76804;

assign code = access_wire[access_index -: 3];

assign SRAM_write_data = 16'd0;

//assign RAM_address = {RAM_segment, RAM_address_main};

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
	
		get_s_prime_buf <= 1'b0;
		k <= 3'd0;
		RAM_segment <= 1'b1;
		index_ptr <= 5'd31;
		element_cont <= 6'd0;
		
		RAM_address <= 7'd0;
		RAM_write_data <= 16'd0;
		RAM_write_enable <= 1'b0;
		S_prime_loaded <= 1'b0;
		count <= 3'd0;
		
		decode_state <= S_DECODE_IDLE;
	
	end else begin
	
		case(decode_state)
			
			S_DECODE_IDLE: begin
				
				if (Start) begin
				
					decode_state <= S_DECODE_WAIT_SETUP;
					element_cont <= 6'd0;
					
					index_ptr <= 5'd31;
				
				end
			
			end
			
			S_DECODE_WAIT_SETUP: begin
			
				if (setup_done) begin
					decode_state <= S_DECODE_AWAIT_INSTRUCTION;
				end
			
			end
			
			S_DECODE_AWAIT_INSTRUCTION: begin
			
				get_s_prime_buf <= Get_S_prime;
			
				if (Get_S_prime & ~get_s_prime_buf) begin
					
					S_prime_loaded <= 1'b0;
					decode_state <= S_DECODE_HUB;
					RAM_segment <= ~RAM_segment;
				end
			
			end
			
			S_DECODE_HUB: begin
				RAM_write_enable <= 1'b0;
				case(code)
					3'b000: begin
						decode_state <= S_DECODE_00X;
						data <= {7'h0, data_00x};
					end
					3'b001: begin
						decode_state <= S_DECODE_00X;
						data <= {7'h3f, data_00x};
					end
					3'b011: begin
						decode_state <= S_DECODE_01X;
						data <= {12'hfff, data_01x};
					end
					3'b010: begin
						decode_state <= S_DECODE_01X;
						data <= {12'h0, data_01x};
					end
					3'b100: begin
						decode_state <= S_DECODE_100;
						data <= -16'd1;
						count <= data_100;
					end
					3'b101: begin
						decode_state <= S_DECODE_101;
						data <= 16'd1;
						count <= data_101;
					end
					3'b110: begin
						decode_state <= S_DECODE_110;
						data <= 16'd0;
						count <= data_110;
						
					end
					3'b111:begin
						decode_state <= S_DECODE_111;
						data <= 16'd0;
					end
				endcase
				
				if (RAM_address[5:0] == 6'd63) begin
					decode_state <= S_DECODE_AWAIT_INSTRUCTION;
					//element_cont <= element_cont + 6'd1;
					RAM_address <= RAM_address + 6'd1;
					S_prime_loaded <= 1'b1;
				end
			
			end
			
			S_DECODE_00X: begin
				index_ptr <= index_ptr - 5'd11;
				RAM_address <= {RAM_segment, RAM_address_main};
				RAM_write_enable <= 1'b1;
				RAM_write_data <= dequantized_data;
				element_cont <= element_cont + 6'd1;
				
				decode_state <= S_DECODE_HUB;
			end
			S_DECODE_01X: begin
				index_ptr <= index_ptr - 5'd6;
				RAM_address <= {RAM_segment, RAM_address_main};
				RAM_write_enable <= 1'b1;
				RAM_write_data <= dequantized_data;
				element_cont <= element_cont + 6'd1;
				
				decode_state <= S_DECODE_HUB;
			end
			S_DECODE_100: begin
				RAM_address <= {RAM_segment, RAM_address_main};
				RAM_write_enable <= 1'b1;
				RAM_write_data <= dequantized_data;
				element_cont <= element_cont + 6'd1;
				
				if (count == 2'd0) begin
					if (k == 3'd3) begin
						decode_state <= S_DECODE_HUB;
						index_ptr <= index_ptr - 5'd5;
						k <= 3'd0;
					end else begin
						k <= k + 3'd1;
					end
				end else begin
					if (k == (count-2'd1)) begin
						decode_state <= S_DECODE_HUB;
						index_ptr <= index_ptr - 5'd5;
						k <= 3'd0;
					end else begin
						k <= k + 3'd1;
					end
				end
			end
			S_DECODE_101: begin
				RAM_address <= {RAM_segment, RAM_address_main};
				RAM_write_enable <= 1'b1;
				RAM_write_data <= dequantized_data;
				element_cont <= element_cont + 6'd1;
				
				if (count == 2'd0) begin
					if (k == 3'd3) begin
						decode_state <= S_DECODE_HUB;
						index_ptr <= index_ptr - 5'd5;
						k <= 3'd0;
					end else begin
						k <= k + 3'd1;
					end
				end else begin
					if (k == (count-2'd1)) begin
						decode_state <= S_DECODE_HUB;
						index_ptr <= index_ptr - 5'd5;
						k <= 3'd0;
					end else begin
						k <= k + 3'd1;
					end
				end
			end
			S_DECODE_110: begin
				RAM_address <= {RAM_segment, RAM_address_main};
				RAM_write_enable <= 1'b1;
				RAM_write_data <= dequantized_data;
				element_cont <= element_cont + 6'd1;
				
				if (count == 3'd0) begin
					if (k == 3'd7) begin
						decode_state <= S_DECODE_HUB;
						index_ptr <= index_ptr - 5'd6;
						k <= 3'd0;
					end else begin
						k <= k + 3'd1;
					end
				end else begin
					if (k == (count-2'd1)) begin
						decode_state <= S_DECODE_HUB;
						index_ptr <= index_ptr - 5'd6;
						k <= 3'd0;
					end else begin
						k <= k + 3'd1;
					end
				end
			end
			S_DECODE_111: begin
			
				element_cont <= element_cont + 6'd1;
				RAM_address <= {RAM_segment, RAM_address_main};
				RAM_write_enable <= 1'b1;
				RAM_write_data <= dequantized_data;
				
				if (element_cont == 6'd63) begin
					decode_state <= S_DECODE_HUB;
					index_ptr <= index_ptr - 5'd3;
				end
			end
		endcase
	
	end

end

always_latch begin
	case(decode_state)
		S_DECODE_00X: next_index = index_ptr - 5'd11;
		S_DECODE_01X: next_index = index_ptr - 5'd6;
		S_DECODE_100: next_index = index_ptr - 5'd5;
		S_DECODE_101: next_index = index_ptr - 5'd5;
		S_DECODE_110: next_index = index_ptr - 5'd6;
		S_DECODE_111: next_index = index_ptr - 5'd3;
		default: next_index = next_index;
	endcase
end

logic setup_0;

logic setup_1;

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
	
		SRAM_address <= 18'd0;
		setup_done <= 1'b0;
		
		SRAM_we_n <= 1'b1;
		SRAM_address <= bitstream_base_address;
		
		SR <= 32'd0;
		
		setup_0 <= 1'b0;
		setup_1 <= 1'b0;
		
		decode_SRAM_state <= S_DECODE_SRAM_IDLE;
	
	end else begin
	
		case(decode_SRAM_state)
		
			S_DECODE_SRAM_SETUP_0: begin
				SRAM_address <= SRAM_address + 18'd1;
				decode_SRAM_state <= S_DECODE_SRAM_SETUP_1;
				
			end
			
			S_DECODE_SRAM_SETUP_1: begin
				SRAM_address <= SRAM_address + 18'd1;
				decode_SRAM_state <= S_DECODE_SRAM_SETUP_2;
				
				//setup_0 <= 1'b1;
			end
			
			S_DECODE_SRAM_SETUP_2: begin
				SRAM_address <= SRAM_address + 18'd1;
				
				SR[31:16] <= SRAM_read_data;
				decode_SRAM_state <= S_DECODE_SRAM_SETUP_3;
				
				//setup_1 <= 1'b1;
				
			end
			
			S_DECODE_SRAM_SETUP_3: begin
				SR[15:0] <= SRAM_read_data;
				decode_SRAM_state <= S_DECODE_SRAM_SETUP_4;
				
				setup_0 <= 1'b1;
				
			end
			
			S_DECODE_SRAM_SETUP_4: begin
				//SRAM_data_buf_0 <= SRAM_read_data;
				decode_SRAM_state <= S_DECODE_SRAM_SETUP_5;
				
				setup_1 <= 1'b1;
				//setup_done <= 1'b1;
			end
			
			S_DECODE_SRAM_SETUP_5: begin
				//SRAM_data_buf_1 <= SRAM_read_data;
				decode_SRAM_state <= S_DECODE_SRAM_IDLE;
				setup_done <= 1'b1;
			end
		
			S_DECODE_SRAM_IDLE: begin
				load_buf <= load;
				start_buf <= Start;
			
				if (load && ~load_buf) begin
					SR[31:16] <= SRAM_data_buf_0;
					
					SRAM_address <= SRAM_address + 18'd1;
					SRAM_we_n <= 1'b1;
				end
				if (~load && load_buf) begin
					SR[15:0] <= SRAM_data_buf_1;
					
					SRAM_address <= SRAM_address + 18'd1;
					SRAM_we_n <= 1'b1;
				end
				if (Start && ~start_buf) begin
					decode_SRAM_state <= S_DECODE_SRAM_SETUP_0;
					SRAM_we_n <= 1'b1;
					SRAM_address <= bitstream_base_address;
				end
			end
		
		endcase
	
	end

end

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
		SRAM_data_buf_0 <= 16'd0;
	
		decode_SRAM_request_state_0 <= S_SRAM_SETUP;
	
	end else begin
		case(decode_SRAM_request_state_0)
		
			S_SRAM_SETUP: begin
			
				if (setup_0) begin
					SRAM_data_buf_0 <= SRAM_read_data;
					decode_SRAM_request_state_0 <= S_SRAM_REQUEST_IDLE;
				end
			
			end
			
			S_SRAM_REQUEST_IDLE: begin
				if (load && ~load_buf) begin
					decode_SRAM_request_state_0 <= S_SRAM_REQUEST_0;
				end
			end
			
			S_SRAM_REQUEST_0: begin
				decode_SRAM_request_state_0 <= S_SRAM_REQUEST_1;
			end
			
			S_SRAM_REQUEST_1: begin
				decode_SRAM_request_state_0 <= S_SRAM_REQUEST_2;
			end
			
			S_SRAM_REQUEST_2: begin
				SRAM_data_buf_0 <= SRAM_read_data;
				
				decode_SRAM_request_state_0 <= S_SRAM_REQUEST_IDLE;
			end
		
		endcase
	end

end

always_ff @ (posedge Clock or negedge Resetn) begin

	if (~Resetn) begin
		SRAM_data_buf_1 <= 16'd0;
		
		decode_SRAM_request_state_1 <= S_SRAM_SETUP;
	
	end else begin
		case(decode_SRAM_request_state_1)
		
			S_SRAM_SETUP: begin
			
				if (setup_1) begin
					SRAM_data_buf_1 <= SRAM_read_data;
					decode_SRAM_request_state_1 <= S_SRAM_REQUEST_IDLE;
				end
			
			end
			
			S_SRAM_REQUEST_IDLE: begin
				if (~load && load_buf) begin
					decode_SRAM_request_state_1 <= S_SRAM_REQUEST_0;
				end
			end
			
			S_SRAM_REQUEST_0: begin
				decode_SRAM_request_state_1 <= S_SRAM_REQUEST_1;
			end
			
			S_SRAM_REQUEST_1: begin
				decode_SRAM_request_state_1 <= S_SRAM_REQUEST_2;
			end
			
			S_SRAM_REQUEST_2: begin
				SRAM_data_buf_1 <= SRAM_read_data;
				
				decode_SRAM_request_state_1 <= S_SRAM_REQUEST_IDLE;
			end
		
		endcase
	end

end

always_comb begin

	if (next_index < 5'd16) begin
		load = 1'b1;
	end else begin
		load = 1'b0;
	end

end

always_comb begin

	case(element_cont) 
		
		6'd0: begin
			RAM_address_main = 6'd0;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd1: begin
			RAM_address_main = 6'd1;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[13:0], 2'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd2: begin
			RAM_address_main = 6'd8;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[13:0], 2'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd3: begin
			RAM_address_main = 6'd16;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd4: begin
			RAM_address_main = 6'd9;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd5: begin
			RAM_address_main = 6'd2;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd6: begin
			RAM_address_main = 6'd3;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd7: begin
			RAM_address_main = 6'd10;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd8: begin
			RAM_address_main = 6'd17;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0}; 
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd9: begin 
			RAM_address_main = 6'd24;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[12:0], 3'b0};
				1'b1: dequantized_data = {data[14:0], 1'b0};
			endcase
		end
		6'd10: begin 
			RAM_address_main = 6'd32;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd11: begin
			RAM_address_main = 6'd25;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd12: begin
			RAM_address_main = 6'd18;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd13: begin
			RAM_address_main = 6'd11;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd14: begin
			RAM_address_main = 6'd4;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd15: begin
			RAM_address_main = 6'd5;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd16: begin
			RAM_address_main = 6'd12;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd17: begin
			RAM_address_main = 6'd19;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd18: begin
			RAM_address_main = 6'd26;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd19: begin
			RAM_address_main = 6'd33;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd20: begin
			RAM_address_main = 6'd40;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[11:0], 4'b0};
				1'b1: dequantized_data = {data[13:0], 2'b0};
			endcase
		end
		6'd21: begin
			RAM_address_main = 6'd48;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd22: begin
			RAM_address_main = 6'd41;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd23: begin
		RAM_address_main = 6'd34;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd24: begin
			RAM_address_main = 6'd27;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd25: begin
			RAM_address_main = 6'd20;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd26: begin
			RAM_address_main = 6'd13;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd27: begin
			RAM_address_main = 6'd6;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd28: begin
			RAM_address_main = 6'd7;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd29: begin
			RAM_address_main = 6'd14;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd30: begin
			RAM_address_main = 6'd21;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd31: begin
			RAM_address_main = 6'd28;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd32: begin
			RAM_address_main = 6'd35;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd33: begin
			RAM_address_main = 6'd42;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd34: begin
			RAM_address_main = 6'd49;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd35: begin
			RAM_address_main = 6'd56;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[10:0], 5'b0};
				1'b1: dequantized_data = {data[12:0], 3'b0};
			endcase
		end
		6'd36: begin
			RAM_address_main = 6'd57;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd37: begin
			RAM_address_main = 6'd50;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd38: begin
			RAM_address_main = 6'd43;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd39: begin
			RAM_address_main = 6'd36;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd40: begin
			RAM_address_main = 6'd29;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd41: begin
			RAM_address_main = 6'd22;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd42: begin
			RAM_address_main = 6'd15;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd43: begin
			RAM_address_main = 6'd23;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd44: begin
			RAM_address_main = 6'd30;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd45: begin
			RAM_address_main = 6'd37;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd46: begin
			RAM_address_main = 6'd44;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd47: begin
			RAM_address_main = 6'd51;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd48: begin
			RAM_address_main = 6'd58;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd49: begin
			RAM_address_main = 6'd59;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd50: begin
			RAM_address_main = 6'd52;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd51: begin
			RAM_address_main = 6'd45;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd52: begin
			RAM_address_main = 6'd38;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd53: begin
			RAM_address_main = 6'd31;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[11:0], 4'b0};
			endcase
		end
		6'd54: begin
			RAM_address_main = 6'd39;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd55: begin
			RAM_address_main = 6'd46;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd56: begin
			RAM_address_main = 6'd53;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd57: begin
			RAM_address_main = 6'd60;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd58: begin
			RAM_address_main = 6'd61;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd59: begin
			RAM_address_main = 6'd54;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd60: begin
			RAM_address_main = 6'd47;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd61: begin
			RAM_address_main = 6'd55;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd62: begin
			RAM_address_main = 6'd62;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		6'd63: begin 
			RAM_address_main = 6'd63;
			case(quantization_matrix)
				1'b0: dequantized_data = {data[9:0], 6'b0};
				1'b1: dequantized_data = {data[10:0], 5'b0};
			endcase
		end
		
	endcase

end
endmodule
