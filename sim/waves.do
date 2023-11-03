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
add wave UUT/UCSC_unit/UCSC_state

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/UCSC_unit/i
add wave -uns UUT/UCSC_unit/j
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data
add wave -hex UUT/UCSC_unit/UCSC_sram_data
add wave -hex UUT/UCSC_unit/UCSC_sram_data_buf

add wave -divider -height 10 {VGA signals}
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

add wave -divider -height 10 {UCSC signals}
add wave -dec UUT/UCSC_unit/R_accumulator_E
add wave -dec UUT/UCSC_unit/G_accumulator_E
add wave -dec UUT/UCSC_unit/B_accumulator_E
add wave -dec UUT/UCSC_unit/R_accumulator_O
add wave -dec UUT/UCSC_unit/G_accumulator_O
add wave -dec UUT/UCSC_unit/B_accumulator_O
add wave -uns UUT/UCSC_unit/FIR_bufV
add wave -uns UUT/UCSC_unit/FIR_bufU
add wave -hex UUT/UCSC_unit/Y
add wave -dec UUT/UCSC_unit/V_accumulator
add wave -dec UUT/UCSC_unit/U_accumulator
add wave -uns UUT/UCSC_unit/upsampled_V
add wave -uns UUT/UCSC_unit/upsampled_U

add wave -divider -height 10 {UCSC arithmetic signals}
add wave -dec UUT/UCSC_unit/prod_1
add wave -dec UUT/UCSC_unit/prod_2
add wave -dec UUT/UCSC_unit/prod_3
add wave -dec UUT/UCSC_unit/prod_4
add wave -dec UUT/UCSC_unit/op1_1
add wave -dec UUT/UCSC_unit/op2_1
add wave -dec UUT/UCSC_unit/op1_2
add wave -dec UUT/UCSC_unit/op2_2
add wave -dec UUT/UCSC_unit/op1_3
add wave -dec UUT/UCSC_unit/op2_3
add wave -dec UUT/UCSC_unit/op1_4
add wave -dec UUT/UCSC_unit/op2_4
