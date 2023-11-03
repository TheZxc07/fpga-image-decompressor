`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [1:0] {
	S_IDLE,
	S_UART_RX,
	S_M1
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [6:0] {
	S_UCSC_IDLE,
	S_LEAD_IN_DELAY_0,
	S_LEAD_IN_DELAY_1,
	S_LEAD_IN_DELAY_2,
	S_LEAD_IN_DELAY_3,
	S_LEAD_IN_DELAY_4,
	S_LEAD_IN_DELAY_5,
	S_LEAD_IN_DELAY_6,
	S_LEAD_IN_DELAY_7,
	S_LEAD_IN_DELAY_8,
	S_LEAD_IN_DELAY_9,
	S_LEAD_IN_DELAY_10,
	S_LEAD_IN_DELAY_11,
	S_LEAD_IN_DELAY_12,
	S_LEAD_IN_DELAY_13,
	S_LEAD_IN_DELAY_14,
	S_LEAD_IN_DELAY_15,
	S_LEAD_IN_DELAY_16,
	S_LEAD_IN_DELAY_17,
	S_LEAD_IN_DELAY_18,
	S_LEAD_IN_DELAY_19,
	S_LEAD_IN_DELAY_20,
	S_LEAD_IN_DELAY_21,
	S_LEAD_IN_DELAY_22,
	S_COMMON_CASE_23,
	S_COMMON_CASE_24,
	S_COMMON_CASE_25,
	S_COMMON_CASE_26,
	S_COMMON_CASE_27,
	S_COMMON_CASE_28,
	S_COMMON_CASE_29,
	S_COMMON_CASE_30,
	S_COMMON_CASE_31,
	S_COMMON_CASE_32,
	S_COMMON_CASE_33,
	S_COMMON_CASE_34,
	S_LEAD_OUT_35,
	S_LEAD_OUT_36,
	S_LEAD_OUT_37,
	S_LEAD_OUT_38,
	S_LEAD_OUT_39,
	S_LEAD_OUT_40,
	S_LEAD_OUT_41,
	S_LEAD_OUT_42,
	S_LEAD_OUT_43,
	S_LEAD_OUT_44,
	S_LEAD_OUT_45,
	S_LEAD_OUT_46,
	S_LEAD_OUT_47,
	S_LEAD_OUT_48,
	S_LEAD_OUT_49,
	S_LEAD_OUT_50,
	S_LEAD_OUT_51,
	S_LEAD_OUT_52,
	S_LEAD_OUT_53,
	S_LEAD_OUT_54,
	S_LEAD_OUT_55,
	S_LEAD_OUT_56,
	S_LEAD_OUT_57,
	S_LEAD_OUT_58,
	S_LEAD_OUT_59,
	S_LEAD_OUT_60,
	S_LEAD_OUT_61,
	S_LEAD_OUT_62,
	S_LEAD_OUT_63,
	S_LEAD_OUT_64,
	S_LEAD_OUT_65,
	S_LEAD_OUT_66,
	S_LEAD_OUT_67
} ucsc_state_type;

typedef enum logic [3:0] {
	S_TEMP_IDLE,
	S_COLOURSPACE_CONVERT,
	S_COLOURSPACE_CONVERT_0
	
} colourspace_conversion_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;

`define DEFINE_STATE 1
`endif
