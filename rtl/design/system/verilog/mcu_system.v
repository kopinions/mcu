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
		    parameter BOOT_MEM_TYPE=`MCU_BOOT_MEM_TYPE,

`ifdef MCU_INCLUDE_DMA
		    parameter INCLUDE_DMA=1,
		    parameter NUM_DMA_CHANNEL=1,
`else
		    parameter INCLUDE_DMA=0,
		    parameter NUM_DMA_CHANNEL=1,
`endif
`ifdef MCU_INCLUDE_JTAG
		    parameter INCLUDE_JTAG=1,
`else
		    parameter INCLUDE_JGAG=0,
`endif
		    parameter MPU_PRESENT=1,
		    parameter NUM_IRQ=32,
		    parameter LVL_WIDTH = 3,
		    parameter TRACE_LVL = 3,
		    parameter DEBUG_LVL = 3,
		    parameter RESET_ALL_REGS = 0,
		    parameter OBSERVATION = 0,
		    parameter WIC_PRESENT = 1,
		    parameter WIC_LINES = 35,
		    parameter BB_PRESENT=1,
		    parameter CONST_AHB_CTRL=1,
		    parameter BOOTLOADER_PRESENT=(BOOT_MEM_TYPE==0)? 0 : 1)
   (
    input wire 	       FCLK,
   
    input wire 	       PORSETn,
    input wire 	       RSTBYPASS,
    input wire 	       CGBYPASS,

    input wire 	       HCLKCPU,
    input wire 	       HCLKSYS,
    input wire 	       HRESETn,
   
    input wire 	       PCLK,
    input wire 	       PCLKG,
    input wire 	       PRESETn,
    input wire 	       PCLKEN,

    output wire [31:0] FLASH_HADDR,
    output wire [1:0]  FLASH_HTRANS,
    output wire [2:0]  FLASH_HSIZE,
    output wire [2:0]  FLASH_HBURST,
    output wire        FLASH_HWRITE,
    output wire [31:0] FLASH_HWDATA,
    output wire        FLASH_HSEL,
    output wire        FLASH_HREADY,
    input wire 	       FLASH_HREDAYOUT,
    input wire [31:0]  FLASH_HRDATA,
    input wire 	       FLASH_HRESP,


    output wire [11:0] RTC_PADDR,
    output wire        RTC_PSEL,
    output wire        RTC_PENABLE,
    output wire        RTC_PWRITE,
    output wire [31:0] RTC_PWDATA,
    input wire 	       RTC_PREADY,
    input wire [31:0]  RTC_PRDATA,
    input wire 	       RTC_PSLVERR,

    input wire 	       RTC_INT,

    output wire [11:0] FLASH_PADDR,
    output wire        FLASH_PSEL,
    output wire        FLASH_PENABLE,
    output wire        FLASH_PWRITE,
    output wire [31:0] FLASH_PWDATA,
    input wire 	       FLASH_PREADY,
    input wire [31:0]  FLASH_PRDATA,
    input wire 	       FLASH_PSLVERR,

    output wire [31:0] SRAM_HADDR,
    output wire [1:0]  SRAM_HTRANS,
    output wire [2:0]  SRAM_HSIZE,
    output wire [2:0]  SRAM_HBURST,
    output wire        SRAM_HWRITE,
    output wire [31:0] SRAM_HWDATA,
    output wire        SRAM_HSEL,
    output wire        SRAM_HREADY,
    input wire 	       SRAM_HREDAYOUT,
    input wire [31:0]  SRAM_HRDATA,
    input wire 	       SRAM_HRESP,

    input wire 	       PLL_LOCK,
    output wire [18:0] PLL_CTRL,

    input wire 	       ADC_PWON,
    input wire [11:0]  ADC_B,
    input wire 	       ADC_RDY,
    output wire [18:0] ADC_CTRL,

    input wire 	       CFG_BOOT,
    output wire [31:0] RCCCFGR_REG,
    output wire        PDDS_REG

    output wire        BOOT_HSEL,
    input wire 	       BOOT_HREADYOUT,
    input wire 	       BOOT_HRDATA,
    input wire 	       BOOT_HRESP,

    output wire        APBACTIVE,
    output wire        SLEEPING,
    output wire        SLEEPDEEP,
    output wire        GATEHCLK,
    output wire        WAKEUP,
    output wire        SYSRESETREQ,
    output wire        WDOGRESETREQ,
    output wire        LOCKUP,
    output wire        LOCKUPRESET,
    output wire        PMUENABLE,
    input wire 	       WICENREQ, // WIC enable request from pmu
    output wire        WICENACK,
    input wire 	       STOPREQ,
    output wire        STOPACK,
    input wire 	       STBYREQ, // 
    output wire        STBYACK,

    output wire        CDBGPWRUPREQ, // Debug power up request to pmu
    input wire 	       CDBGPWRUPACK, 

    input wire 	       ISOLATEn, // Isolate control from pmu
    input wire 	       RETAINn, // State retention control from pmu

    input wire 	       nTRST,
    input wire 	       SWDITMS,
    input wire 	       SWCLKTCK,
    input wire 	       TDI,
    output wire        TDO,
    output wire        nTDOEN,
    output wire        SWDO,
    output wire        SWDOEN,
    output wire        JTAGNSW,

    input wire 	       TRACECLKIN,
    output wire        TRACECLK,
    output wire [3:0]  TRACEDATA,
    output wire        SWV,

    input wire 	       UART0_RXD,
    output wire        UART0_TXD,
    output wire        UART0_TXEN,

    input wire 	       UART1_TXD,
    output wire        UART1_TXD,
    output wire UART1_TXEN,

    input wire TIMER0_EXTIN,
    input wire TIMER1_EXTIN,

    // wakeup event from wic?
    input wire WKUPEVENT,

    // SPI
    input wire SPICLK,
    input wire nSPIRST,
    output wire SPIINTR,
    output wire SPIFSSOUT,
    output wire SPICLKOUT,
    input wire SPIRXD,
    output wire SPITXD, 
    output wire nSPICTLOE,
    input wire SPICLKIN,
    input wire SPIFSSIN,
    output wire nSPIOE,


    // I2C
    input wire SCLI,
    output wire SCLO,
    output wire nSCLOEN,
    input wire SDAI,
    output wire SDAO,
    output wire nSDAOEN,

    // GPIO 0
    input wire [15:0] GPIO0_IN,
    output wire [15:0] GPIO0_OUT,
    output wire [15:0] GPIO0_OUTEN,
    output wire [15:0] GPIO_ALTFUNC, // GPIO alternate function(pin mux)

    // GPIO 1
    input wire [15:0] GPIO1_IN,
    output wire [15:0] GPIO1_OUT,
    output wire [15:0] GPIO_OUTEN,
    output wire [15:0] GPIO1_ALTFUNC,
   
    input wire DFTSE // DFT Scan Enable
    );


   // i-code bus from processor
   wire [31:0] 	       cm_i_haddr;
   wire [1:0] 	       cm_i_htrans;
   wire [2:0] 	       cm_i_hsize;
   wire [2:0] 	       cm_i_hburst;
   wire [3:0] 	       cm_i_hprot;
   wire [31:0] 	       cm_i_hrdata;
   wire 	       cm_i_hready;
   wire [1:0] 	       cm_i_hresp;
   
   // d-code bus from processor
   wire [31:0] 	       cm_d_haddr;
   wire [1:0] 	       cm_d_htrans;
   wire 	       cm_d_hwrite;
   wire [2:0] 	       cm_d_hsize;
   wire [2:0] 	       cm_d_hburst;
   wire [3:0] 	       cm_d_hprot;
   wire [31:0] 	       cm_d_hwdata;
   wire 	       cm_d_hready;
   wire [1:0] 	       cm_d_hresp;
   wire [31:0] 	       cm_d_hrdata;
   wire [1:0] 	       cm_d_hmaster;
   wire [2:0] 	       cm_d_hruser;
   
   // d-code exclusive
   wire 	       cm_d_exreq;
   wire 	       cm_d_exresp;

   // sys bus from processor
   wire [31:0] 	       cm_s_haddr;
   wire [1:0] 	       cm_s_htrans;
   wire 	       cm_s_hwrite;
   wire [2:0] 	       cm_s_hsize;
   wire [2:0] 	       cm_s_hburst;
   wire [3:0] 	       cm_s_hprot;
   wire [31:0] 	       cm_s_hwdata;
   wire 	       cm_s_hready;
   wire [1:0] 	       cm_s_hresp;
   wire [31:0] 	       cm_s_hrdata;
   wire [1:0] 	       cm_s_hmaster;
   wire 	       cm_s_hmasterlock;
   wire [2:0] 	       cm_s_hruser;
   
   // sys bus exclusive from processor
   wire 	       cm_s_exreq;
   wire 	       cm_s_exresp;

   // dma bus from dma controller 
   wire [31:0] 	       dmac_haddr;
   wire [1:0] 	       dmac_htrans;
   wire 	       dmac_hwrite;
   wire [2:0] 	       dmac_hsize;
   wire [2:0] 	       dmac_hburst;
   wire [3:0] 	       dmac_hprot;
   wire [31:0] 	       dmac_hwdata;
   wire 	       dmac_hready;
   wire [1:0] 	       dmac_hresp;
   wire [31:0] 	       dmac_hrdata;
   wire 	       dmac_hmasterlock;

   wire 	       dmac_psel;
   wire 	       dmac_pready;
   wire 	       dmac_pslverr;
   wire 	       dmac_prdata;

   // combined code bus from busmatrix
   wire 	       code_hsel;
   wire [31:0] 	       code_haddr;
   wire [1:0] 	       code_htrans;
   wire 	       code_hwrite;
   wire [2:0] 	       code_hsize;
   wire [2:0] 	       code_hburst;
   wire [3:0] 	       code_hprot;
   wire [31:0] 	       code_hwdata;
   wire 	       code_hready;
   wire 	       code_hreadyout;
   wire [1:0] 	       code_hresp;
   wire [31:0] 	       code_hrdata;
   wire 	       code_hmasterlock;
   wire [2:0] 	       code_hauser;

   // sys bus from busmatrix
   wire 	       sys_hsel;
   wire [31:0] 	       sys_haddr;
   wire [1:0] 	       sys_htrans;
   wire 	       sys_hwrite;
   wire [2:0] 	       sys_hsize;
   wire [2:0] 	       sys_hburst;
   wire [3:0] 	       sys_hprot;
   wire [31:0] 	       sys_hwdata;
   wire 	       sys_hready;
   wire 	       sys_hreadyout;
   wire [1:0] 	       sys_hresp;
   wire [31:0] 	       sys_hrdata;
   wire 	       sys_hmasterlock;
   wire [2:0] 	       sys_hauser;
   
   // adc
   wire [31:0] 	       adc_prdata;
   wire 	       adc_intr;

   wire 	       defslv0_hsel;
   wire 	       defslv0_hreadyout;
   wire 	       defslv0_hrdata;
   wire 	       defslv0_hresp;
   
   wire 	       defslv1_hsel;
   wire 	       defslv1_hreadyout;
   wire 	       defslv1_hrdata;
   wire 	       defslv1_hresp;
   
   wire 	       apbsys_hsel;
   wire 	       apbsys_hreadyout;
   wire 	       apbsys_hrdata;
   wire 	       apbsys_hresp;
   
   wire 	       gpio0_hsel;
   wire 	       gpio0_hreadyout;
   wire 	       gpio0_hrdata;
   wire 	       gpio0_hresp;
   
   wire 	       gpio1_hsel;
   wire 	       gpio1_hreadyout;
   wire 	       gpio1_hrdata;
   wire 	       gpio1_hresp;
   
   wire 	       sysctrl_hsel;
   wire 	       sysctrl_hreadyout;
   wire 	       sysctrl_hrdata;
   wire 	       sysctrl_hresp;

   // external intterupt
   wire [15:0] 	       exti;
   wire 	       dbgen;


   // APB expansion signal
   wire [11:0] 	       exp_paddr;
   wire [31:0] 	       exp_pwdata;
   wire 	       exp_pwrite;
   wire 	       exp_penable;


   wire 	       remap_ctrl;


   // interrupts
   wire [239:0]        intisr_cm;
   wire 	       intnmi_cm;
   wire 	       fp_excp;
   wire [15:0] 	       gpio0_intr;
   wire 	       gpio0_combintr;
   wire [15:0] 	       gpio1_intr;
   wire 	       gpio1_combintr;
   
   wire [31:0] 	       apbsubsys_intr;
   wire 	       watchdog_intr;
   wire 	       dma_done;
   wire 	       dma_err;


   // event signals
   wire 	       TXEV;
   wire 	       RXEV;
   

   // systic timer
   wire 	       STCLKEN;
   wire [25:0] 	       STCALIB;

   // processor debug signals
   wire 	       DBGRESTART;
   wire 	       DBGRESTARTED;
   wire 	       EDBGRQ;

   // processor status
   wire 	       HALTED;
   wire [47:0] 	       TSVALUE;
   wire 	       TSCLKCHANGE;

   wire 	       bigendian;

   
endmodule // mcu_system
