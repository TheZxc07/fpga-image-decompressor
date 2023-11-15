
mem save -o SRAM.mem -f mti -data hex -addr hex -startaddress 0 -endaddress 262143 -wordsperline 8 /TB/SRAM_component/SRAM_data

if {[file exists $rtl/S_prime.ver]} {
	file delete $rtl/S_prime.ver
}
mem save -o S_prime.mem -f mti -data hex -addr decimal -wordsperline 1 /TB/UUT/IDCT_unit/S_prime_RAM/altsyncram_component/m_default/altsyncram_inst/mem_data

if {[file exists $rtl/M_matrix.ver]} {
	file delete $rtl/M_matrix.ver
}
mem save -o M_matrix.mem -f mti -data decimal -addr decimal -wordsperline 1 /TB/UUT/IDCT_unit/M_RAM/altsyncram_component/m_default/altsyncram_inst/mem_data
