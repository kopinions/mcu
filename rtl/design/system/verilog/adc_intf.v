module adc_intf(
		input wire 	   PCLK,
		input wire 	   PCLKG, 
		input wire 	   PRESETn,
		input wire 	   PSEL,
		input wire [11:2]  PADDR,
		input wire 	   PENABLE,
		input wire 	   PWRITE,
		input wire [31:0]  PWDATA,
		output wire [31:0] PRDATA,
		output wire 	   PREADY,
		output wire 	   PSLVERR,

		input wire 	   ADC_PWON,
		input wire 	   ADC_RDY,
		input wire [11:0]  ADC_B,
		output wire 	   ADC_CTRL,
		output wire 	   ADC_INT);

`include "mcu_adc_const_pkg.v"
   localparam S_IDLE = 3'h0;
   localparam S_PWON = 3'h1;
   localparam S_PWDN = 3'h2;
   localparam S_CAL = 3'h3;
   localparam S_NORMAL = 3'h4;
   localparam S_CONV = 3'h5;
   localparam S_CONV_DONE = 3'h6;
   
   wire 			   read_enable;
   wire 			   write_enable;
   wire 			   conv_done;

   reg 				   reg_adc_sr_eoc;
   reg 				   reg_adc_cr1_eocie;
   reg 				   reg_adc_cr2_swstart;
   reg 				   reg_adc_cr2_cal;
   reg 				   reg_adc_cr2_adon;
   reg [11:0] 			   reg_adc_dr;
   reg [31:0] 			   reg_prdata;
   reg [31:0] 			   rdata;

   reg [2:0] 			   current_state;
   reg [2:0] 			   next_state;

   reg [3:0] 			   reg_conv_count;

   reg 				   adc_int;
   reg [1:0] 			   adc_opm;
   
   

   assign read_enable = PSEL & (~PWRITE);
   assign write_enable = PSEL & PWRITE & (~PENABLE);

   // use pclk because the reg_adc_sr is related to inner status
   // this status is used to control the adc
   always @(posedge PCLK or negedge PRESETn)
     begin
	if (~PRESETn)
	  reg_adc_sr_eoc <= ADC_SR_RESET[1];
	else if (current_state == S_CONV_DONE)
	  reg_adc_sr_eoc <= 1'b1;
	else if(read_enable & (PADDR[11:2] == ADC_DR_OFFSET[11:2]))
	  reg_adc_sr_eoc <= 1'b0;
	else if (write_enable &(PADDR[11:2] == ADC_SR_OFFSET[11:2]))
	  reg_adc_sr_eoc <= 1'b0;
     end // always @ (posedge PCLK or negedge PRESETn)

   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn)
	  reg_adc_cr1_eocie <= ADC_CR1_RESET[5];
	else if (write_enable & (PADDR[11:2] == ADC_CR1_OFFSET[11:2]))
	  reg_adc_cr1_eocie <= PWDATA[5];
     end

   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn) begin
	   reg_adc_cr2_swstart <= ADC_CR2_RESET[22];
	   reg_adc_cr2_cal <= ADC_CR2_RESET[1];
	   reg_adc_cr2_adon <= ADC_CR2_RESET[0];
	end
	else if (write_enable && (PADDR[11:2] == ADC_CR2_OFFSET[11:2])) begin
	   reg_adc_cr2_swstart <= PWDATA[22];
	   reg_adc_cr2_cal <= PWDATA[1];
	   reg_adc_cr2_adon <= PWDATA[0];
	end
	else if (current_state == S_CONV | current_state == S_CONV_DONE) begin
	   reg_adc_cr2_swstart <= 1'b0;
	end
     end // always @ (posedge PCLKG or negedge PRESETn)

   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn) 
	  reg_adc_dr <= ADC_DR_RESET[11:0];
	else if(current_state == S_CONV_DONE)
	  reg_adc_dr <= ADC_B;
     end
   
   always @*
     begin
	case (PADDR[11:2])
	  ADC_SR_OFFSET[11:2]:
	    begin
	       rdata = reg_adc_sr_eoc;
	    end
	  ADC_CR1_OFFSET[11:2]:
	    begin
	       rdata = {26'h0, reg_adc_cr1_eocie, 5'h0}; 
	    end
	  ADC_CR2_OFFSET[11:2]:
	    begin
	       rdata = {9'h0, reg_adc_cr2_swstart, 20'h0, reg_adc_cr2_cal, reg_adc_cr2_adon};
	    end
	  ADC_DR_OFFSET[11:2]:
	    begin
	       rdata = {20'h0, reg_adc_dr}; 
	    end
	  default:
	    begin
	       rdata = 32'h0;
	    end
	endcase // case (PADDR[11:2])
     end // always @ *

   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn)
	  reg_prdata <= 32'h0;
	else
	  reg_prdata <= read_enable ? rdata: 32'h0;	
     end

   always @* 
     begin
	next_state = current_state;
	case (current_state)
	  S_IDLE:
	    if (reg_adc_cr2_adon)
	      next_state = S_PWON;
	  S_PWON:
	    if(ADC_PWON) 
	      next_state = S_PWDN;
	  S_PWDN:
	    if (reg_adc_cr2_adon)
	      next_state = S_CAL;
	  S_CAL:
	    if (ADC_RDY)
	      next_state = S_NORMAL;
	  S_NORMAL:
	    if (~reg_adc_cr2_adon)
	      next_state = S_PWDN;
	    else if (reg_adc_cr2_swstart)
	      next_state = S_CONV;
	    else if (reg_adc_cr2_cal)
	      next_state = S_CAL;
	  S_CONV:
	    if (conv_done)
	      next_state = S_CONV_DONE;
	  S_CONV_DONE:
	    next_state = S_NORMAL;
	  default:
	    next_state = S_PWDN;
	endcase // case (current_state)
     end // always @ *


   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn)
	  current_state <= S_IDLE;
	else
	  current_state <= next_state;
     end
   
   

   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn)
	  reg_conv_count <= 4'h0;
	else if ((current_state == S_NORMAL) & (next_state == S_CONV))
	  reg_conv_count <= 4'h0;
	else if ((current_state == S_CONV) & (reg_conv_count != 4'hD))
	  reg_conv_count <=  reg_conv_count + 4'h1;
     end
   
   assign conv_done = (reg_conv_count == 4'hD)? 1'b1 : 1'b0;
   

   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn)
	  adc_int <= 1'b0;
	else if (~reg_adc_cr1_eocie)
	  adc_int <= 1'b0;
	else if ((reg_adc_cr1_eocie) & (current_state == S_CONV_DONE))
	  adc_int <= 1'b1;
     end

   assign ADC_INT = adc_int;
   
   always @(posedge PCLKG or negedge PRESETn)
     begin
	if (~PRESETn)
	  adc_opm <= 2'b00;
	
	else
	  adc_opm <= (current_state == S_IDLE) | (current_state == S_PWDN) ? 2'b00: 2'b11;
     end

   assign ADC_CTRL = {adc_opm, reg_adc_cr2_cal};
endmodule // adc_intf
