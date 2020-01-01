// clock domain cross sync 
module cdc_capt_sync(
		     input  clk,
		     input  nreset,
		     input  async_i,
		     output sync_o
		     );
   reg 			    d_sync1;
   reg 			    d_sync2;
   
   always @(posedge clk or negedge nreset)
     if (!nreset) 
       begin
	  d_sync1 <= 1'b0;
	  sync_o <= 1'b0;
       end 
     else 
       begin
	  d_sync1 <= async_i;
	  d_sync2 <= d_sync1;
       end

   assign sync_o = d_sync2;
endmodule
