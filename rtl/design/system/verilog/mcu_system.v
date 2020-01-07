`include "mcu_defs.v"
module mcu_system #(
`ifdef MCU_INCLUDE_CLKGATE
		    parameter CLKGATE_PRESENT=1,
`else
		    parameter CLKGATE_PRESENT=0,
`endif
		    parameter BASEADDR_GPIO0=32'h40010000,
		    parameter BASEADDR_GPIO1=32'h40011000,
		    parameter BE=0,
		    parameter BOOT_MEM_TYPE=`MCU_BOOT_MEM_TYPE
		    )
   ();
   

endmodule
