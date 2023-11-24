# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer
add wave UUT/MIC17_unit/MIC17_state
add wave UUT/MIC17_unit/UCSC_unit/UCSC_state

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {UCSC signals}
add wave -hex UUT/MIC17_unit/UCSC_unit/Y
add wave -hex UUT/MIC17_unit/UCSC_unit/FIR_bufU
add wave -hex UUT/MIC17_unit/UCSC_unit/FIR_bufV

add wave -divider -height 10 {UCSC arithmetic signals}
add wave -dec UUT/MIC17_unit/UCSC_unit/U_accumulator
add wave -dec UUT/MIC17_unit/UCSC_unit/upsampled_U
add wave -dec UUT/MIC17_unit/UCSC_unit/V_accumulator
add wave -dec UUT/MIC17_unit/UCSC_unit/upsampled_V
add wave -dec UUT/MIC17_unit/UCSC_unit/prod_1
add wave -dec UUT/MIC17_unit/UCSC_unit/op1_1
add wave -dec UUT/MIC17_unit/UCSC_unit/op2_1
add wave -dec UUT/MIC17_unit/UCSC_unit/prod_2
add wave -dec UUT/MIC17_unit/UCSC_unit/op1_2
add wave -dec UUT/MIC17_unit/UCSC_unit/op2_2
add wave -dec UUT/MIC17_unit/UCSC_unit/prod_3
add wave -dec UUT/MIC17_unit/UCSC_unit/op1_3
add wave -dec UUT/MIC17_unit/UCSC_unit/op2_3
add wave -dec UUT/MIC17_unit/UCSC_unit/prod_4
add wave -dec UUT/MIC17_unit/UCSC_unit/op1_4
add wave -dec UUT/MIC17_unit/UCSC_unit/op2_4




#add wave -divider -height 10 {Decoder signals}
#add wave -bin UUT/MIC17_unit/fill_instruction
#add wave -bin UUT/MIC17_unit/decode_unit/code
#add wave -bin UUT/MIC17_unit/decode_start
#add wave -uns UUT/MIC17_unit/decode_unit/index_ptr
#add wave -hex UUT/MIC17_unit/decode_unit/SRAM_data_buf_0
#add wave -hex UUT/MIC17_unit/decode_unit/SRAM_data_buf_1
#add wave -hex UUT/MIC17_unit/decode_unit/SR
#add wave -uns UUT/MIC17_unit/S_prime_address_a
#add wave -uns UUT/MIC17_unit/S_prime_write_data_a
#add wave -bin UUT/MIC17_unit/S_prime_write_enable_a
#add wave -uns UUT/MIC17_unit/decode_unit/RAM_address
#add wave -hex UUT/MIC17_unit/decode_unit/RAM_write_data
#add wave -uns UUT/MIC17_unit/decode_unit/element_cont
#add wave -hex UUT/MIC17_unit/decode_unit/dequantized_data
#add wave -dec UUT/MIC17_unit/decode_unit/data

#add wave -uns UUT/MIC17_unit/decode_unit/access_index
#add wave -uns UUT/MIC17_unit/decode_unit/k
#add wave -dec UUT/MIC17_unit/decode_unit/data_00x
#add wave -dec UUT/MIC17_unit/decode_unit/data_01x
#add wave -uns UUT/MIC17_unit/decode_unit/data_100
#add wave -uns UUT/MIC17_unit/decode_unit/data_101
#add wave -uns UUT/MIC17_unit/decode_unit/data_110

#add wave -divider -height 10 {IDCT RAM signals}
#add wave -uns UUT/MIC17_unit/decode_unit/RAM_address
#add wave -uns UUT/MIC17_unit/IDCT_unit/S_prime_RAM_address
#add wave -bin UUT/MIC17_unit/IDCT_unit/matrix_select
#add wave -uns UUT/MIC17_unit/IDCT_unit/S_prime_address_a
#add wave -hex UUT/MIC17_unit/IDCT_unit/S_prime_write_data_a
#add wave -bin UUT/MIC17_unit/IDCT_unit/S_prime_write_enable_a
#add wave -uns UUT/MIC17_unit/IDCT_unit/S_prime_address_b
#add wave -hex UUT/MIC17_unit/IDCT_unit/S_prime_write_data_b
#add wave -bin UUT/MIC17_unit/IDCT_unit/S_prime_write_enable_b
#add wave -uns UUT/IDCT_unit/M_address_a
#add wave -hex UUT/IDCT_unit/M_write_data_a
#add wave -uns UUT/IDCT_unit/M_address_b
#add wave -hex UUT/IDCT_unit/S_prime_read_data_a
#add wave -hex UUT/IDCT_unit/S_prime_read_data_b
#add wave -dec UUT/IDCT_unit/M_read_data_a 
#add wave -dec UUT/IDCT_unit/M_read_data_b 

#add wave -divider -height 10 {IDCT signals}
#add wave -uns UUT/IDCT_unit/S_matrix
#add wave -bin UUT/IDCT_unit/row_identifier
#add wave -dec UUT/IDCT_unit/S_prime_data
#add wave -dec UUT/IDCT_unit/M_data
#add wave -uns UUT/IDCT_unit/op_select
#add wave -uns UUT/IDCT_unit/element_cont
#add wave -uns UUT/IDCT_unit/block_cont_i_r
#add wave -uns UUT/IDCT_unit/block_cont_j_r
#add wave -uns UUT/IDCT_unit/block_cont_i_w
#add wave -uns UUT/IDCT_unit/block_cont_j_w
#add wave -hex UUT/IDCT_unit/coeff_data
#add wave -uns UUT/IDCT_unit/coeff_address_a
#add wave -hex UUT/IDCT_unit/coeff_read_data_a
#add wave -uns UUT/IDCT_unit/coeff_address_b
#add wave -hex UUT/IDCT_unit/coeff_read_data_b
#add wave -uns UUT/IDCT_unit/i
#add wave -uns UUT/IDCT_unit/j	


#add wave -divider -height 10 {IDCT arithmetic signals}
#add wave -uns UUT/IDCT_unit/S_signal
#add wave -dec UUT/IDCT_unit/result
#add wave -dec UUT/IDCT_unit/accumulator
#add wave -dec UUT/IDCT_unit/S_prime_data_buf
#add wave -dec UUT/IDCT_unit/M_data_buf
#add wave -dec UUT/IDCT_unit/op1_1
#add wave -dec UUT/IDCT_unit/op1_2
#add wave -dec UUT/IDCT_unit/op1_3
#add wave -dec UUT/IDCT_unit/op1_4
#add wave -dec UUT/IDCT_unit/op2_1
#add wave -dec UUT/IDCT_unit/op2_2
#add wave -dec UUT/IDCT_unit/op2_3
#add wave -dec UUT/IDCT_unit/op2_4
