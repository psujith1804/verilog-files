module ahb_master(hclk,hresetn,hrdata,hresp,hreadyout,hwrite,hreadyin,htrans,haddr,hwdata);
	input hclk,hresetn,hreadyout;
	input [1:0] hresp;
	input [31:0] hrdata;

	output reg hwrite;
	output reg hreadyin;
	output reg [1:0] htrans;
	output reg [31:0] haddr,hwdata;

	parameter idle = 2'b00, busy = 2'b01, non_seq = 2'b10, seq = 2'b11;

	task delay();
		begin 
				#2;
		end

	endtask


	task single_write;

		begin 

			@(posedge hclk)
			delay;
			begin 
				hwrite = 1'b1;
				htrans = non_seq;
				haddr = 32'h8100_0000;
				hreadyin =1'b1;
			end

			@(posedge hclk)
			begin
				delay;
				htrans = idle;
				hwdata = 30;
			end
		
		end

	endtask

	task single_read;
		
		begin 
			@(posedge hclk)
			delay;
			begin 
				hwrite = 1'b0;
				htrans = non_seq;
				#1 haddr = 32'h8100_0000;
				hreadyin =1'b1;
			end

			@(posedge hclk)
			delay;
			begin 
				htrans = idle;
				hreadyin = 1'b0;
			end
		end

	endtask

endmodule