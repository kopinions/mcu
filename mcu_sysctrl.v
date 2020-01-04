module mcu_sysctrl(
		   input wire 	      HCLK,
		   input wire 	      HRESETn,
		   input wire 	      FCLK,
		   input wire 	      PORESETn,

		   input wire 	      HSEL,
		   input wire 	      HREADY,
		   input wire [1:0]   HTRANS,
		   input wire [2:0]   HSIZE,
		   input wire 	      HWRITE,
		   input wire [11:0]  HADDR,
		   input wire [31:0]  HWDATA,
		   output wire 	      HREADYOUT,
		   output wire 	      HRESP,
		   output reg [31:0]  HRDATA,

		   input wire 	      STOPREQ,
		   output wire 	      STOPACK,
		   input wire 	      STBYREQ,
		   output wire 	      STBYACK,

		   input wire 	      SLEEPHOLDREQn,
		   output wire 	      SLEEPHOLDACKn,

		   input wire 	      PLL_LOCK,
		   output [18:0]      wire PLL_CTRL,

		   output wire [31:0] RCCCFGR_REG,
		   output wire 	      PDDS_REG,
		   input wire 	      CFG_BOOT,

		   input wire 	      SYSRESETREQ,
		   input wire 	      WDOGRESETREQ,
		   input wire 	      LOCKUP,


		   output wire 	      REMAP,
		   output wire 	      PMUENABLE,
		   output wire 	      LOCKUPRESET);

`include mcu_sysctrl_const_pkg.v

   reg 				      stopreq_sync;
   reg 				      stbyreq_sync;

   reg 				      ahb_trans_reg;
   reg [12:0] 			      haddr_reg;
   reg [2:0] 			      hsize_reg;
   reg 				      hwrite_reg;

   reg [3:0] 			      byte_sel;


   wire [3:0] 			      we;
   
   wire [31:0] 			      remap_reg;
   wire [31:0] 			      pmuenable_reg;
   wire [31:0] 			      lockupreset_reg;
   wire [31:0] 			      pwrcr_reg;
   wire [31:0] 			      rcccfgr1_reg;
   wire [31:0] 			      rcccr_reg;
   wire [31:0] 			      resetinfo_reg;
   
   
   
   
   cdc_capt_sync u_sync_stopreq(
				.clk(FCLK),
				.nreset(PORESETn),
				.async_i(STOPREQ),
				.sync_o(stopreq_sync));

   cdc_capt_sync u_sync_stopreq(
				.clk(FCLK),
				.nreset(PORESETn),
				.async_i(STBYREQ),
				.sync_o(stbyreq_sync));
   
   assign SLEEPHOLDACKn = ~stbyreq_sync;
   assign STOPACK = 1'b1;
   assign STBYACK = ~SLEEPHOLDACKn;

   // HTRANS: 00=IDLE, 01=BUSY, 10=NONSEQ, 11=SEQ
   assign ahb_trans = HSEL & HREADY & HTRANS[1];

   // sysctrl no need to wait to read, this is always ready
   assign HREADYOUT = 1'b1;

   always @(posedge HCLK or negedge PORESETn)
     begin
	if (~PORESETn)
	  ahb_trans_reg <= 1'b0;
	else
	  ahb_trans_reg <= ahb_trans;
     end
   

   always @(posedge HCLK or negedge PORESETn)
     begin
	if (~PORESETn)
	  begin
	     haddr_reg <= 12'b0;
	     hsize_reg <= 3'b0;
	     hwrite_reg <= 1'b0;
	  end
	else if (ahb_trans)
	  begin
	     haddr_reg <= HADDR;
	     hsize_reg <= HSIZE;
	     hwrite_reg <= HWRITE;
	  end
     end // always @ (posedge HCLK or negedge PORESETn)

   
   always @*
     begin
	if (hsize_reg == 3'b000) // byte
	  begin
	     case (haddr_reg[1:0])
	       2'b00: byte_sel = 4'b0001;
	       2'b01: byte_sel = 4'b0010;
	       2'b10: byte_sel = 4'b0100;
	       2'b11: byte_sel = 4'b1000;
	     endcase // case (haddr_reg[1:0])
	  end
	else if (hsize_reg == 3'b001) // half word
	  begin
	     if (haddr_reg[1])
	       byte_sel = 4'b1100;
	     else
	       byte_sel = 4'b0011;
	  end
	else
	  byte_sel = 4'b1111;
     end // always @ *

   wire [3:0] we_always;
   assign we_always = byte_sel & {4{hwrite_reg}};
   assign we = we_always & {4{ahb_trans_reg}};
   
   reg 	      reset_init;
   reg 	      remap_bits;
   
   always @ (posedge HCLK or negedge PORESETn ) begin
      if (~PORESETn)
	reset_init <=1'b0;
      else
	reset_init <=1'b1;
   end

   always @ (posedge HCLK or negedge HRESETn) begin
      if (~HRESETn)
	remap_bits <= MCU_REMAP_RESET[0];
      else if (HADDR[11:2] == MCU_REMAP_OFFSET[11:2] && we[0])
	remap_bits <= HWDATA[0];
      else if (~reset_init)
	remap_bits <= CFG_BOOT;
   end
   
   assign remap_reg = {31'h0, remap_bits};
   assign REMAP = remap_reg[0];

   // pmuenable
   reg pmuenable_bits;   
   always @ (posedge HCLK or negedge HRESETn) begin
      if (~HRESETn)
	pmuenable_bits <= MCU_PMUENABLE_OFFSET[0];
      else if (HADDR[11:2] == MCU_PMUENABLE_RESET[11:2] && we[0])
	pmuenable_bits <= HWDATA[0];
   end

   assign pmuenable_reg = {31'h0, pmuenable_bits};
   assign PMUENABLE = pmuenable[0];

   // lockupreset
   reg lockupreset_bits;   
   always @ (posedge HCLK or negedge HRESETn) begin
      if (~HRESETn)
	lockupreset_bits <= MCU_LOCKUPRESET_RESET[0];
      else if (HADDR[11:2] == MCU_LOCKUPRESET_OFFSET[11:2] && we[0])
	lockupreset_bits <= HWDATA[0];
   end

   assign lockupreset_reg = {31'h0, lockupreset_bits};
   assign LOCKUPRESET = lockupreset_reg[0];

   // RESETINFO
   reg [2:0] resetinfo_bits;
   always @ (posedge HCLK or negedge HRESETn ) begin
      if (~HRESETn)
	resetinfo_bits <= MCU_RESETINFO_RESET[2:0];
      else
	begin
	   if (SYSRESETREQ) begin
	      resetinfo_bits[0] <= 1'b1;
	   end
	   if (WDOGRESETREQ) begin
	      resetinfo_bits[1] <= 1'b1;
	   end
	   if (LOCKUP) begin
	      resetinfo_bits[2] <= 1'b1;
	   end
	end // else: !if(~HRESETn)
   end // always @ (posedge HCLK or negedge HRESETn )

   assign resetinfo_reg = {29'h0, resetinfo_bits};
   
   // Reset Clock Control Control register
   reg   [1:0] rcccr_bits;
   always @ (posedge HCLK or negedge PORESETn) begin
      if (~PORESETn)
	rcccr_bits[1:0] <= {MCU_RCC_CR_RESET[24], MCU_RCC_CR_RESET[0]};
      else begin
	 if (haddr_reg[11:2]==MCU_RCC_CR_OFFSET[11:2]) begin
	    if (we[3]) begin
	       rccrr_bits[1] <= HWDATA[24];
	    end
	    if (we[0]) begin
	       rcccr_bits[0] <= HWDATA[0];
	    end
	 end
	 
      end // else: !if(~PORESETn)
   end // always @ (posedge HCLK or negedge PORESETn)

   reg rcccr_lock;
   always @ (posedge HCLK or negedge PORESETn) begin
      if (~PORESETn)
	rcccr_lock <= 1'b0;
      else
	rcccr_lock <= PLL_LOCK;
   end

   assign rcccr_reg = {6'h0, rcccr_lock, rcccr_bits[1], 23'h0, rcccr_bits[0]};

   // RCC_CFGR
   reg [11:0]  rcccfgr_bits;
   always @ ( posedge HCLK or negedge PORESETn ) begin
      if (~PORESETn) begin
	 rcccfgr_bits <= {MCU_RCC_CFGR_RESET[26:24], MCU_RCC_CFGR_RESET[10:8], MCU_RCC_CFGR_RESET[7:4], MCU_RCCCFGR_RESET[2], MCU_RCCCFGR_RESET[0]};
      end
      else if (haddr_reg[11:2] == MCU_RCCCFGR_OFFSET[11:2])  begin
	 if (we[3]) begin
	    rcccfgr_bits[11:9] = HWDATA[26:24];
	 end
	 if (we[1]) begin
	    rcccfgr_bits[8:6] = HWDATA[10:8];
	 end
	 if (we[0]) begin
	    rcccfgr_bits[5:2] = HWDATA[7:4];
	    rcccfgr_bits[1] = HWDATA[2];
	    rcccfgr_bits[0] = HWDATA[0];
	 end
      end // if (haddr_reg[11:2] == MCU_RCCCFGR_OFFSET[11:2])
   end // always @ ( posedge HCLK or negedge PORESETn )

   assign RCCCFGR_REG = {5'h0, rcccfgr_bits[11:9], 13'h0, rcccfgr_bits[8:6], rcccfgr_bits[5:2], 1'b0, rcccfgr_bits[1], 1'b0, rcccfgr_bits[0]};

   // RCC_CFGR1
   reg [15:0]  rcccfgr1_bits;
   always @ ( posedge HCLK or negedge PORESETn ) begin
      if (~PORESETn) begin
	 rcccfgr1_bits <= {MCU_RCC_CFGR1_RESET[15:0]};
      end
      else if (haddr_reg[11:2] == MCU_RCCCFGR1_OFFSET[11:2])  begin
	 if (we[1]) begin
	    rcccfgr1_bits[15:8] = HWDATA[15:8];
	 end
	 if (we[0]) begin
	    rcccfgr1_bits[7:0] = HWDATA[7:0];
	 end
      end
   end // always @ ( posedge HCLK or negedge PORESETn )

   assign rcccfgr1_reg = {16'h0, rcccfgr1_bits};

   reg   [1] pwrcr_bits;
   always @ ( posedge HCLK or negedge PORESETn ) begin
      if (~PORESETn) begin
	 pwrcr_bits <= {MCU_PWR_CR_RESET[1]};
      end
      else if (haddr_reg[11:2] == MCU_PWR_CR_OFFSET[11:2] && we[0])  begin
	 pwrcr_bits <= HWDATA[1];
      end
   end

   assign pwrcr_reg <= {30'h0, pwrcr_bits, 1'b0};
   assign PDDS_REG = pwrcr_bits;
   
   reg   [31:0] rdata;
   always @ ( * ) begin
      rdata = 32'h0;
      case (haddr_reg[11:2]) 
	MCU_REMAP_OFFSET[11:2]: begin
	   rdata = remap_reg;
	end
	MCU_PMUENABLE_OFFSET[11:2]: begin
	   rdata = pmuenable_reg;
	end
	MCU_LOCKUPRESET_OFFSET[11:2]: begin
	   rdata = lockupreset_reg;
	end
	MCU_RESETINFO_OFFSET[11:2]: begin
	   rdata = resetinfo_reg;
	end
	MCU_RCCCR_OFFSET[11:2]: begin
	   rdata = rcccr_reg;
	end
	MCU_RCCCFGR_OFFSET[11:2]: begin
	   rdata = RCCCFGR_REG;
	end
	MCU_RCCCFGR1_OFFSET[11:2]: begin
	   rdata = rcccfgr1_reg;
	end
	MCU_PWRCR_OFFSET[11:2]: begin
	   rdata = pwrcr_reg;
	end
      endcase
   end // always @ ( * )

   always @ ( /*AUTOSENSE*/ ) begin
      if (~PORESETn) begin
	 HRDATA <= 32'h0;
      end
      else if (~hwrite_reg && HREADY)  begin
	 HRDATA <= rdata;
      end
   end

   assign HRESP = 1'b0;
   
   assign PLL_CTRL = {
		      rcccfgr1_reg, 
		      rcccr_reg[24], 
		      rcccr_reg[0]
		      };
   
   
endmodule // mcu_sysctrl
