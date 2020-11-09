module vga (
	input  logic clk,
	input  logic rst,
	input  logic turn,

	input  logic [5:0][6:0] panel,player1,player2,
	input  logic [6:0]		put_line,
	
	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue	
);

//vga
logic flag;
logic [8:0] rows;
logic [9:0] columns;

//score4
logic [2:0]	p_row,p_column;
logic flag_row, flag_column, flag_put;


//Clock divider_vga
always_ff @(posedge clk, negedge rst) begin
	if(!rst) begin
		flag<=0;
	end
	else begin
		flag<=~flag;
	end
end


//Counters_vga
always_ff @(posedge clk,negedge rst) begin
	if(!rst) begin
		rows<=0;
		columns<=0;
	end
	else begin
		if(flag) begin
			if( columns < 799 ) begin 	
				columns<=columns+ 1'b1;
			end
			else begin
				columns<=0;	
				if( rows < 523 ) begin
					rows<=rows+1'b1;
				end
				else 
					rows<=0;
			end
		end	
	end
end

//Sync_vga
always_comb begin

		//Hsync
		if( columns<752 && columns>654 ) begin
			hsync = 0;
		end	
		
		else  begin	
			hsync = 1;
		end

		//Vsync

		if( rows<493 && rows>490 ) begin
			vsync=0;
		end
		else  begin	
			vsync=1;	
		end
end


//Colours 
always_comb begin
			if( columns<640 && rows<480 ) begin
				//panel
				if ( flag_row && flag_column && panel[ p_row ][ p_column ] )	begin
					if( player1[ p_row ][ p_column ] )	begin
						red=4'b1111;
						blue=4'b0000;
						green=4'b0001;
					end
					else  begin
						red=4'b0000;
						blue=4'b0011;
						green=4'b1111;
					end
				end
				//put line
				else if ( flag_put && flag_column && put_line[p_column] ) begin
					if(!turn) begin
						red=4'b1111;
						blue=4'b0001;
						green=4'b0000;
					end
					else begin
						red=4'b0000;
						blue=4'b0011;
						green=4'b1111;
					end
				end	
				//blank 
				else begin
					red=4'b0000;
					blue=4'b0000;
					green=4'b0000;
				end
			end
			else begin
				red=4'b0000;
				blue=4'b0000;
				green=4'b0000;
			end
end		


//flag_column_score4
always_comb begin

if(!rst) begin
	p_column=0;
	flag_column=0;
end
else begin
	if 	(columns>59 && columns<90) begin
		flag_column=1;
		p_column=6;
	end
	else if (columns>119 && columns<150) begin
		flag_column=1;
		p_column=5;
	end
	else if (columns>179 && columns<210) begin
		flag_column=1;
		p_column=4;
	end
	else if (columns>239 && columns<270) begin
		flag_column=1;
		p_column=3;
	end
	else if (columns>299 && columns<330) begin
		flag_column=1;
		p_column=2;
	end
	else if (columns>359 && columns<390) begin
		flag_column=1;
		p_column=1;
	end
	else if (columns>419 && columns<450) begin
		flag_column=1;
		p_column=0;
	end
	else begin 
		flag_column=0;
		p_column=0;
	end
		
end
end

//flag_row_score4 && flag_put
always_comb begin

if(!rst) begin
	p_row=0;
	flag_row=0;
	flag_put=0;
end
else begin
	if 	(rows>29 && rows<60) begin
		flag_row=1;
		p_row=3'b000;
		flag_put=0;
	end
	else if (rows>89 && rows<120) begin
		flag_row=1;
		p_row=1;
		flag_put=0;
	end
	else if (rows>149 && rows<180) begin
		flag_row=1;
		p_row=2;
		flag_put=0;
	end
	else if (rows>209 && rows<240) begin
		flag_row=1;
		p_row=3;
		flag_put=0;
	end
	else if (rows>269 && rows<300) begin
		flag_row=1;
		p_row=4;
		flag_put=0;
	end
	else if (rows>329 && rows<360) begin
		flag_row=1;
		p_row=5;
		flag_put=0;
	end
	else if (rows>389 && rows<410) begin
		flag_put=1;
		flag_row=0;	
		p_row=0;
	end
	else begin
		flag_row=0;
		flag_put=0;
		p_row=0;
	end
end
end

endmodule