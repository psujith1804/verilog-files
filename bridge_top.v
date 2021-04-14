module bridge_top(hclk,hresetn,hwrite,hreadyin,htrans,haddr,hwdata,prdata,
					pwrite,penable,psel,paddr,pwdata,hreadyout,hresp,hrdata);


	input hclk,hresetn,hwrite,hreadyin;
	input [1:0]htrans;
	input [31:0] haddr,hwdata,prdata;

	output pwrite,penable;
	output [2:0] psel;
	output [31:0] paddr,pwdata,hrdata;
	output hreadyout;
	output [1:0] hresp;

	wire [31:0] haddr_1,haddr_2,hwdata_1,hwdata_2,hrdata;
	wire [2:0]temp_selx;


	apb uut1(valid,haddr_1,haddr_2,hwdata_1,hwdata_2,temp_selx,hreadyout,hclk,hresetn,hwrite,pwrite,penable,psel,paddr,pwdata,prdata,hwrite_reg,hresp,hrdata);
	AHB_SLAVE_INTERFACE uut2(hclk,hresetn,hwrite,hreadyin,htrans,haddr,hwdata,valid,haddr_1,haddr_2,hwdata_1,hwdata_2,temp_selx,hwrite_reg);

endmodule

module apb(valid,haddr_1,haddr_2,hw_data_1,hw_data_2,temp_selx,hreadyout,hclk,hresetn,hwrite,pwrite,penable,psel,paddr,pwdata,prdata,hwrite_reg,hresp,hrdata);

	input valid,hwrite,hclk,hresetn,hwrite_reg;
	input [2:0] temp_selx;
	input [31:0] haddr_2,haddr_1,hw_data_1,hw_data_2,prdata;

	output reg pwrite,penable,hreadyout;
	output reg [31:0] paddr,pwdata,hrdata;
	output reg [2:0] psel;
	output reg [1:0] hresp;

	reg pwrite_temp,penable_temp,hreadyout_temp;
	reg [31:0] paddr_temp,pwdata_temp;
	reg [2:0] psel_temp;

	parameter st_idle = 3'b000,st_wait = 3'b001,st_read=3'b010,st_write=3'b011,st_writep=3'b100;
	parameter st_renable=3'b101,st_wenable=3'b110,st_wenablep=3'b111;

	reg [2:0] ps,ns;

	//present state logic
	always @(posedge hclk)
	begin 
		if( hresetn )
			ps <= st_idle;
		else
			ps <= ns; 
	end

	//next state and output logic
	always @(*)
	begin 
		ns = st_idle;
		case(ps)

			st_idle: begin 

				
				if( valid && !hwrite)
					ns = st_read;

				else if(valid && hwrite)
					ns = st_wait;

	  			else if(!valid)
					ns = st_idle;

				//output 
				pwdata_temp = 0;
				penable_temp = 0;
				psel_temp = 0;
				pwrite_temp = 0;
				paddr_temp = 0;
				hreadyout_temp = 1;
			end

			
			st_wait: begin
				if(!valid)
					ns = st_write;
				else
					ns = st_writep;

				//output 
				pwdata_temp = 0;
				penable_temp = 1'b0;
				psel_temp = 3'b000;
				pwrite_temp = 1'b0;
				paddr_temp = 32'h00000000;
				hreadyout_temp = 1'b0;


			end 

			st_read: begin 
				ns = st_renable;

				//output 
				pwdata_temp = 32'h0000_0000;
				penable_temp = 1'b0;
				psel_temp = temp_selx;
				pwrite_temp = 1'b0;
				paddr_temp = haddr_2;
				hreadyout_temp = 1'b0;

			end

			st_write: begin
				if(valid)
					ns = st_wenablep;
				else
					ns = st_wenable;

				//output 
				pwdata_temp = hw_data_2;
				penable_temp = 1'b0;
				psel_temp = temp_selx;
				pwrite_temp = hwrite;
				paddr_temp = haddr_2;
				hreadyout_temp = 1'b0;

			end  

			st_writep:begin 
				ns  = st_wenablep;

				//output 
				pwdata_temp = hw_data_2;
				penable_temp = 1'b0;
				psel_temp = temp_selx;
				pwrite_temp = hwrite;
				paddr_temp = haddr_2;
				hreadyout_temp = 1'b0;


			end

			st_renable:begin 
				if(!valid)
					ns = st_idle;

				else if(valid && !hwrite)
					ns = st_read;

				else if(valid && hwrite)
					ns =st_wait;

				//output 
				pwdata_temp = 0;
				penable_temp = 1;
				psel_temp = temp_selx;
				pwrite_temp = 0;
				paddr_temp = haddr_2;
				hreadyout_temp = 1;


			end

			st_wenable: begin 
				if(!valid)
					ns = st_idle;
				else if(valid && !hwrite)
					ns = st_read;

				else if(valid && hwrite)
					ns =st_wait;

				//output 
				pwdata_temp = hw_data_2;
				penable_temp = 1'b1;
				psel_temp = temp_selx;
				pwrite_temp = hwrite;
				paddr_temp = haddr_2;
				hreadyout_temp = 1;


			end
			st_wenablep:begin 
				if(!valid && hwrite_reg)
					ns  = st_write;
				else if(valid && hwrite_reg)
					ns = st_writep;
				else
					ns = st_read;

				//output 
				pwdata_temp = hw_data_2;
				penable_temp = 1'b1;
				psel_temp  = temp_selx;
				pwrite_temp = hwrite;
				paddr_temp = haddr_2;
				hreadyout_temp = 1'b0;

			end


		endcase

	end


	always @(posedge hclk)
	begin 
		if(hresetn)
		begin 
			pwrite <= 0;
			penable <= 0;
			hreadyout <= 0;
			paddr <= 0;
			pwdata <= 0;
			psel <= 0;
		end

		else
		begin 
			pwrite <= pwrite_temp;
			penable <= penable_temp;
			hreadyout <= hreadyout_temp;
			paddr <= paddr_temp;
			pwdata <= pwdata_temp;
			psel <= psel_temp;
			hrdata <=prdata;
			
			end
	end

endmodule

module AHB_SLAVE_INTERFACE(hclk,hresetn,hwrite,hreadyin,htrans,haddr,hwdata,valid,haddr_1,haddr_2,hwdata_1,hwdata_2,temp_selx,hwrite_reg);

  input hclk,hresetn,hreadyin,hwrite;
  input [1:0] htrans;
  input [31:0] haddr,hwdata;

  output reg valid;
  output reg hwrite_reg;
  output reg [2:0] temp_selx;
  output reg [31:0]  hwdata_2,hwdata_1,haddr_2,haddr_1;

  parameter NONSEQ = 2'b10, SEQ= 2'b11;

  // address decoding

  always @(*)
  begin
    if(haddr >= 32'h80000000 && haddr < 32'h84000000)
      temp_selx = 3'b001;
    else if(haddr >= 32'h84000000 && haddr < 32'h88000000)
      temp_selx = 3'b010;
    else if(haddr >= 32'h88000000 && haddr < 32'h8C000000)
      temp_selx = 3'b100;
end

//pipelining

always @(posedge hclk)
begin 
  if(hresetn == 1'b1)
  begin 
    haddr_1 <= 32'h0;
    haddr_2 <= haddr_1;
    hwdata_1 <= 32'b0;
    hwdata_2 <= 32'b0;
    hwrite_reg <= 1'b0;
    end
  else
  begin
    haddr_1 <= haddr;
    haddr_2 <= haddr_1;
    hwdata_1 <= hwdata;
    hwdata_2 <= hwdata_1;
    hwrite_reg <= hwrite;

    end
end

//generating the valid signal

always @(*)
begin 
  valid = 1'b0;

  if(hreadyin == 1'b1 && (htrans == NONSEQ || htrans == SEQ) && (haddr >= 32'h80000000 && haddr < 32'h8C000000))
    valid = 1'b1;

end

endmodule