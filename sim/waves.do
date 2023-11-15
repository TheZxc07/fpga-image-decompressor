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
add wave UUT/IDCT_unit/IS_state
add wave UUT/IDCT_unit/IDCT_state

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {IDCT RAM signals}
add wave -uns UUT/IDCT_unit/S_prime_address_a
add wave -hex UUT/IDCT_unit/S_prime_write_data_a
add wave -bin UUT/IDCT_unit/S_prime_write_enable_a
add wave -uns UUT/IDCT_unit/S_prime_address_b
add wave -hex UUT/IDCT_unit/S_prime_write_data_b
add wave -bin UUT/IDCT_unit/S_prime_write_enable_b
add wave -uns UUT/IDCT_unit/M_address_a
add wave -hex UUT/IDCT_unit/M_write_data_a
add wave -uns UUT/IDCT_unit/M_address_b
add wave -hex UUT/IDCT_unit/S_prime_read_data_a
add wave -hex UUT/IDCT_unit/S_prime_read_data_b
add wave -dec UUT/IDCT_unit/M_read_data_a 
add wave -dec UUT/IDCT_unit/M_read_data_b 

add wave -divider -height 10 {IDCT signals}
add wave -uns UUT/IDCT_unit/S_matrix
add wave -bin UUT/IDCT_unit/row_identifier
add wave -dec UUT/IDCT_unit/S_prime_data
add wave -dec UUT/IDCT_unit/M_data
add wave -uns UUT/IDCT_unit/op_select
#add wave -uns UUT/IDCT_unit/element_cont
add wave -uns UUT/IDCT_unit/block_cont_i_r
add wave -uns UUT/IDCT_unit/block_cont_j_r
add wave -uns UUT/IDCT_unit/block_cont_i_w
add wave -uns UUT/IDCT_unit/block_cont_j_w
add wave -hex UUT/IDCT_unit/coeff_data
add wave -uns UUT/IDCT_unit/coeff_address_a
add wave -hex UUT/IDCT_unit/coeff_read_data_a
add wave -uns UUT/IDCT_unit/coeff_address_b
add wave -hex UUT/IDCT_unit/coeff_read_data_b
#add wave -uns UUT/IDCT_unit/i
#add wave -uns UUT/IDCT_unit/j	


add wave -divider -height 10 {IDCT arithmetic signals}
add wave -uns UUT/IDCT_unit/S_signal
add wave -dec UUT/IDCT_unit/result
add wave -dec UUT/IDCT_unit/accumulator
add wave -dec UUT/IDCT_unit/S_prime_data_buf
add wave -dec UUT/IDCT_unit/M_data_buf
add wave -dec UUT/IDCT_unit/op1_1
add wave -dec UUT/IDCT_unit/op1_2
add wave -dec UUT/IDCT_unit/op1_3
add wave -dec UUT/IDCT_unit/op1_4
add wave -dec UUT/IDCT_unit/op2_1
add wave -dec UUT/IDCT_unit/op2_2
add wave -dec UUT/IDCT_unit/op2_3
add wave -dec UUT/IDCT_unit/op2_4
