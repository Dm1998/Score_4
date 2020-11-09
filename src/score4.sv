module score4 (
	input  logic clk,
	input  logic rst,

	input  logic left,
	input  logic right,
	input  logic put,
	
	output logic player,
	output logic invalid_move,
	output logic win_a,
	output logic win_b,
	output logic full_panel,

	output logic hsync,
	output logic vsync,
	output logic [3:0] red,
	output logic [3:0] green,
	output logic [3:0] blue	
);

//FSM STATES
enum logic[2:0] {IDLE=3'b000, TURN=3'b001, CHECK_PUT=3'b100, CHECK_WIN =3'b101, END=3'b111} state;

logic turn , vsync_ ; // turn,vsync are needed at vga

logic rst_vga;

logic [6:0]	put_line; 		// One-hot, vga usage
logic [2:0] put_pointer;

logic [5:0][6:0] panel,player1,player2;

logic o_left,o_put,o_right; // Edged signals
logic invalid_move_col, invalid_move_r;
// FSM 

always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		put_line 	<= 64;
		put_pointer <= 6;
		panel  		<= 0;
		player1 	<= 0;	
		player2 	<= 0;				
		turn    	<= 0;
		state 		<= TURN;
	
	end
	else begin
		case(state)
		IDLE: ;			

		TURN: begin
			
			if( invalid_move_r ) begin
					// Recognise from which side borders were exceeded
					if( right ) begin				
						put_line <= 7'b0000001;
						put_pointer <= 0 ;
					end
					
					else if( left ) begin
						put_pointer <= 6 ;
						put_line <= 7'b1000000;
					end
					
			end
			else if( o_left && !invalid_move_r ) begin
				
				put_line <= put_line << 1;
				put_pointer <= put_pointer + 1'b1;
				
			end
			else if( o_right && !invalid_move_r ) begin
			
				put_line <= put_line >> 1;
				put_pointer <= put_pointer - 1'b1;
				
			end
			else if( o_put && !invalid_move_col ) state <= CHECK_PUT ;
		
	
		end
				
		CHECK_PUT: begin
																						// Choose spot from bottom to top
																						//For player 1
						if( ! ( panel[5][put_pointer] && panel[4][put_pointer] ) ) begin	// If NAND=1 => there is an empty spot 5-4, 3-2, 1-0
																						// First empty spot is where we put ( lower pointer / higher spot ) 
							if( !panel[5][put_pointer]) begin                                                                             //  0
								
								panel[5][put_pointer] <= 1;                                                                               //  1 
								
								if(!turn) player1[5][put_pointer] <=1;
								else	 player2[5][put_pointer] <=1;
							end                                                                                                           //  2 
							else begin                                                                                                    //  3 
								
								panel[4][put_pointer] <= 1;                                                                                
								
								if(!turn) player1[4][put_pointer] <=1;                                                                    //  4 
								else 	  player2[4][put_pointer] <=1;																	  //  5 
							end                                                                                                           
						end
					
					
						else if( !(panel[3][put_pointer] && panel[2][put_pointer]) ) begin
						
							if( !panel[3][put_pointer]) begin
								
								panel[3][put_pointer] <= 1;
								
								if(!turn) player1[3][put_pointer] <=1;
								else	  player2[3][put_pointer] <=1;
								
							end
							else begin
								
								panel[2][put_pointer] <= 1;
								
								if(!turn) player1[2][put_pointer] <=1;
								else 	  player2[2][put_pointer] <=1;
								
							end
						end
					
						else if( !(panel[1][put_pointer] && panel[0][put_pointer]) ) begin
						
							if( !panel[1][put_pointer]) begin
								
								panel[1][put_pointer] <= 1;
								
								if(!turn) player1[1][put_pointer] <=1;
								else   	  player2[1][put_pointer] <=1;
								
							end
							else begin
								
								panel[0][put_pointer] <= 1;
								
								if(!turn) player1[0][put_pointer] <=1;
								else      player2[0][put_pointer] <=1;
							
							end
						end

						state <= CHECK_WIN;

						
				 
		
		end
		
//		VGA : begin
//			
//			if(!vsync_) begin
//				
//				if(!invalid_move) begin
//					state <= CHECK_WIN;
//					
//				end
//			end
//		end
//		
//		VGA_move : begin
//			
//			if(!vsync_) begin	
//				if(!invalid_move)  state <= TURN;
//			end
//		end		
//
				
		CHECK_WIN: begin
			
			if( win_a ) begin
				$display("~~~~~~~~~ Congratulations Player 1! ~~~~~~~~~");
				$display(" 	");
				state <= END;
			end
			
			else if( win_b ) begin 
				$display("~~~~~~~~~ Congratulations Player 2! ~~~~~~~~~");
				$display(" 	");
				state <= END;
			end
			
			else if(  full_panel && !win_a && !win_b ) begin
				$display("~~~~~~~~~ We have a tie here! ~~~~~~~~~");
				state <= END;
			end
			
			else if( !full_panel && !win_a && !win_b  ) begin
				state <= TURN;
				turn <= !turn;
			end

		end
		
		
		END: begin
			$display("~~~~~~~~~ The End ~~~~~~~~~");
			state <= IDLE;
		end
		
		endcase// case

	end// else
end// ALWAYS-FF END


always_comb begin

	if(rst) begin
		invalid_move_r = 0;
	end
	else begin
		if( ~( |put_line ) ) begin
			$display("~~~~~~~~~~~~~~~~ Exceeded put line border ~~~~~~~~~~~~~~~~ ");
			$display("~~~~~~~~~~~~~~~~        Try Again !       ~~~~~~~~~~~~~~~~ \n ");
			invalid_move_r = 1; // out from border
		end
		else	invalid_move_r = 0;
	end	
	
end


always_comb begin
	if(rst) invalid_move_col = 0;
	else begin
		
		if ( panel[0][put_pointer] && o_put ) begin
			
				$display("~~~~~~~~~~~~~~~~       Full Column      ~~~~~~~~~~~~~~~~");
				$display("~~~~~~~~~~~~~~~~  Try Another Column !   ~~~~~~~~~~~~~~~~");
				invalid_move_col = 1; // full line
		end
		else	invalid_move_col = 0; 
		
	end
end

// Edge Signals
// -----------------------------------------------------

logic edge_reg_put ;
logic edge_reg_left;
logic edge_reg_right ;
logic falling_edge_put  , rising_edge_put;
logic falling_edge_left , rising_edge_left;
logic falling_edge_right, rising_edge_right;


always_ff @(posedge clk, posedge rst) begin

	if (rst)	begin
		edge_reg_left<= 1'b0;
		edge_reg_right <= 1'b0;
		edge_reg_put <= 1'b0;
	end
	
	else begin
		edge_reg_right <= right;
		edge_reg_left<= left;
		edge_reg_put <= put;
	end
	
end


assign falling_edge_put = edge_reg_put & (~put);
assign rising_edge_put = (~edge_reg_put) & put;
assign falling_edge_left = edge_reg_left & ( ~left );
assign rising_edge_left = ( ~edge_reg_left ) & left;
assign falling_edge_right = edge_reg_right & (~right);
assign rising_edge_right = (~edge_reg_right) & right;


always_comb begin
 

		o_left= 0;
		o_right= 0;
		o_put= 0;

	
	
	
		if( falling_edge_left && ~rising_edge_left)	o_left=0;
		else if( rising_edge_left && ~falling_edge_left) o_left=1;
	
		
		if( falling_edge_right && ~rising_edge_right )	o_right=0;
		else if( rising_edge_right && ~falling_edge_right ) o_right=1;
		else o_right = 0;
		
		if( falling_edge_put && ~rising_edge_put )	o_put=0;
		else if( rising_edge_put && ~falling_edge_put ) o_put=1;
		else o_put = 0;
		
	
	
end
//  -----------------------------------------------------



// Winning and Full Flags
always_comb begin
	
		win_a = 0;	 
		win_b = 0;
		full_panel = 0;
	
	 
		// Full Panel	
			if( &panel == 1 ) full_panel  = 1;
			else full_panel = 0;
		// Diagonal to left win Player2
	
				if ( (player2[0][3] && player2[1][4] && player2[2][5] && player2[3][6] ) || ( player2[2][0] && player2[3][1] && player2[4][2] && player2[5][3] ) ) win_b =1;
			else if ( (player2[0][1] && player2[1][2] && player2[2][3] && player2[3][4] ) || ( player2[1][2] && player2[2][3] && player2[3][4] && player2[4][5] ) || ( player2[2][3] && player2[3][4] && player2[4][5] && player2[5][6] )   )	win_b =1; 
			else if ( (player2[0][0] && player2[1][1] && player2[2][2] && player2[3][3] ) || ( player2[1][1] && player2[2][2] && player2[3][3] && player2[4][4] ) || ( player2[2][2] && player2[3][3] && player2[4][4] && player2[5][5] )   )	win_b =1;
			else if ( (player2[1][0] && player2[2][1] && player2[3][2] && player2[4][3] ) || ( player2[2][1] && player2[3][2] && player2[4][3] && player2[5][4] ) ) win_b =1;
			else if ( (player2[0][2] && player2[1][3] && player2[2][4] && player2[3][5] ) || ( player2[1][3] && player2[2][4] && player2[3][5] && player2[4][6] ) ) win_b =1;
			
	
		// Diagonal to right win Player2
	
			else if ( ( player2[2][6] && player2[3][5] && player2[4][4] && player2[5][3] ) || ( player2[0][3] && player2[1][2]  && player2[2][1] && player2[3][0] ) ) win_b =1;
			else if ( (player2[0][5] && player2[1][4]  && player2[2][3] && player2[3][2] ) || ( player2[1][4] && player2[2][3] && player2[3][2] && player2[4][1] ) || ( player2[2][3] && player2[3][2] && player2[4][1] && player2[5][0] )   )	win_b =1;
			else if ( (player2[0][6] && player2[1][5]  && player2[2][4] && player2[3][3] ) || ( player2[1][5] && player2[2][4] && player2[3][3] && player2[4][2] ) || ( player2[2][4] && player2[3][3] && player2[4][2] && player2[5][1] )   )	win_b =1;
			else if ( (player2[1][6]  && player2[2][5] && player2[3][4] && player2[4][3] ) || ( player2[2][5] && player2[3][4] && player2[4][3] && player2[5][2] ) )  win_b =1;
			else if ( (player2[0][4]  && player2[1][3] && player2[2][2] && player2[3][1] ) || ( player2[1][3] && player2[2][2] && player2[3][1] && player2[4][0] ) )  win_b =1; 
			
		
	
		// Row win  Player2
		
			else if ( ( player2[0][6] && player2[0][5] && player2[0][4] && player2[0][3] )  || ( player2[0][5] && player2[0][4] && player2[0][3] && player2[0][2] ) || ( player2[0][4] && player2[0][3] && player2[0][2] && player2[0][1] ) || ( player2[0][3] && player2[0][2] && player2[0][1] && player2[0][0] ) )	win_b =1 ;
			else if( ( player2[1][6] && player2[1][5] && player2[1][4] && player2[1][3] )  || ( player2[1][5] && player2[1][4] && player2[1][3] && player2[1][2] ) || ( player2[1][4] && player2[1][3] && player2[1][2] && player2[1][1] ) || ( player2[1][3] && player2[1][2] && player2[1][1] && player2[1][0] ) )	win_b =1 ;
			else if( ( player2[2][6] && player2[2][5] && player2[2][4] && player2[2][3] )  || ( player2[2][5] && player2[2][4] && player2[2][3] && player2[2][2] ) || ( player2[2][4] && player2[2][3] && player2[2][2] && player2[2][1] ) || ( player2[2][3] && player2[2][2] && player2[2][1] && player2[2][0] ) )	win_b =1 ;
			else if( ( player2[3][6] && player2[3][5] && player2[3][4] && player2[3][3] )  || ( player2[3][5] && player2[3][4] && player2[3][3] && player2[3][2] ) || ( player2[3][4] && player2[3][3] && player2[3][2] && player2[3][1] ) || ( player2[3][3] && player2[3][2] && player2[3][1] && player2[3][0] ) )	win_b =1 ;
			else if( ( player2[4][6] && player2[4][5] && player2[4][4] && player2[4][3] )  || ( player2[4][5] && player2[4][4] && player2[4][3] && player2[4][2] ) || ( player2[4][4] && player2[4][3] && player2[4][2] && player2[4][1] ) || ( player2[4][3] && player2[4][2] && player2[4][1] && player2[4][0] ) )	win_b =1 ;
			else if( ( player2[5][6] && player2[5][5] && player2[5][4] && player2[5][3] )  || ( player2[5][5] && player2[5][4] && player2[5][3] && player2[5][2] ) || ( player2[5][4] && player2[5][3] && player2[5][2] && player2[5][1] ) || ( player2[5][3] && player2[5][2] && player2[5][1] && player2[5][0] ) )	win_b =1 ;
			
		
		// Column win Player2
		
			else if( ( player2[0][6] && player2[1][6] && player2[2][6] && player2[3][6] )  || ( player2[1][6] && player2[2][6] && player2[3][6] && player2[4][6] ) || ( player2[2][6] && player2[3][6] && player2[4][6] && player2[5][6] )  ) win_b =1 ;
			else if( ( player2[0][5] && player2[1][5] && player2[2][5] && player2[3][5] )  || ( player2[1][5] && player2[2][5] && player2[3][5] && player2[4][5] ) || ( player2[2][5] && player2[3][5] && player2[4][5] && player2[5][5] )  ) win_b =1 ;
			else if( ( player2[0][4] && player2[1][4] && player2[2][4] && player2[3][4] )  || ( player2[1][4] && player2[2][4] && player2[3][4] && player2[4][4] ) || ( player2[2][4] && player2[3][4] && player2[4][4] && player2[5][4] )  ) win_b =1 ;
			else if( ( player2[0][3] && player2[1][3] && player2[2][3] && player2[3][3] )  || ( player2[1][3] && player2[2][3] && player2[3][3] && player2[4][3] ) || ( player2[2][3] && player2[3][3] && player2[4][3] && player2[5][3] )  ) win_b =1 ;
			else if( ( player2[0][2] && player2[1][2] && player2[2][2] && player2[3][2] )  || ( player2[1][2] && player2[2][2] && player2[3][2] && player2[4][2] ) || ( player2[2][2] && player2[3][2] && player2[4][2] && player2[5][2] )  ) win_b =1 ;
			else if( ( player2[0][1] && player2[1][1] && player2[2][1] && player2[3][1] )  || ( player2[1][1] && player2[2][1] && player2[3][1] && player2[4][1] ) || ( player2[2][1] && player2[3][1] && player2[4][1] && player2[5][1] )  ) win_b =1 ;
			else if( ( player2[0][0] && player2[1][0] && player2[2][0] && player2[3][0] )  || ( player2[1][0] && player2[2][0] && player2[3][0] && player2[4][0] ) || ( player2[2][0] && player2[3][0] && player2[4][0] && player2[5][0] )  ) win_b =1 ;
			else win_b =0;
			
		// Diagonal to left win  Player1
	
				 if( ( player1[0][3] && player1[1][4] && player1[2][5] && player1[3][6] ) || ( player1[2][0] && player1[3][1] && player1[4][2] && player1[5][3] ) ) win_a =1;
			else if ( (player1[0][1] && player1[1][2] && player1[2][3] && player1[3][4] ) || ( player1[1][2] && player1[2][3] && player1[3][4] && player1[4][5] ) || ( player1[2][3] && player1[3][4] && player1[4][5] && player1[5][6] )   )	win_a =1; 
			else if ( (player1[0][0] && player1[1][1] && player1[2][2] && player1[3][3] ) || ( player1[1][1] && player1[2][2] && player1[3][3] && player1[4][4] ) || ( player1[2][2] && player1[3][3] && player1[4][4] && player1[5][5] )   )	win_a =1;
			else if ( (player1[1][0] && player1[2][1] && player1[3][2] && player1[4][3] ) || ( player1[2][1] && player1[3][2] && player1[4][3] && player1[5][4] ) ) win_a =1;
			else if ( (player1[0][2] && player1[1][3] && player1[2][4] && player1[3][5] ) || ( player1[1][3] && player1[2][4] && player1[3][5] && player1[4][6] ) ) win_a =1;
			
	
		// Diagonal to right win Player1
	
			else if( ( player1[2][6] && player1[3][5] && player1[4][4] && player1[5][3] ) || ( player1[0][3] && player1[1][2]  && player1[2][1] && player1[3][0] ) ) win_a =1;
			else if ( (player1[0][5] && player1[1][4]  && player1[2][3] && player1[3][2] ) || ( player1[1][4] && player1[2][3] && player1[3][2] && player1[4][1] ) || ( player1[2][3] && player1[3][2] && player1[4][1] && player1[5][0] )   )	win_a =1;
			else if ( (player1[0][6] && player1[1][5]  && player1[2][4] && player1[3][3] ) || ( player1[1][5] && player1[2][4] && player1[3][3] && player1[4][2] ) || ( player1[2][4] && player1[3][3] && player1[4][2] && player1[5][1] )   )	win_a =1;
			else if ( (player1[1][6]  && player1[2][5] && player1[3][4] && player1[4][3] ) || ( player1[2][5] && player1[3][4] && player1[4][3] && player1[5][2] ) )  win_a =1;
			else if ( (player1[0][4]  && player1[1][3] && player1[2][2] && player1[3][1] ) || ( player1[1][3] && player1[2][2] && player1[3][1] && player1[4][0] ) )  win_a =1; 
			
		
	
		// Row win  Player1
			else if( ( player1[0][6] && player1[0][5] && player1[0][4] && player1[0][3] )  || ( player1[0][5] && player1[0][4] && player1[0][3] && player1[0][2] ) || ( player1[0][4] && player1[0][3] && player1[0][2] && player1[0][1] ) || ( player1[0][3] && player1[0][2] && player1[0][1] && player1[0][0] ) )	win_a =1 ;
			else if( ( player1[1][6] && player1[1][5] && player1[1][4] && player1[1][3] )  || ( player1[1][5] && player1[1][4] && player1[1][3] && player1[1][2] ) || ( player1[1][4] && player1[1][3] && player1[1][2] && player1[1][1] ) || ( player1[1][3] && player1[1][2] && player1[1][1] && player1[1][0] ) )	win_a =1 ;
			else if( ( player1[2][6] && player1[2][5] && player1[2][4] && player1[2][3] )  || ( player1[2][5] && player1[2][4] && player1[2][3] && player1[2][2] ) || ( player1[2][4] && player1[2][3] && player1[2][2] && player1[2][1] ) || ( player1[2][3] && player1[2][2] && player1[2][1] && player1[2][0] ) )	win_a =1 ;
			else if( ( player1[3][6] && player1[3][5] && player1[3][4] && player1[3][3] )  || ( player1[3][5] && player1[3][4] && player1[3][3] && player1[3][2] ) || ( player1[3][4] && player1[3][3] && player1[3][2] && player1[3][1] ) || ( player1[3][3] && player1[3][2] && player1[3][1] && player1[3][0] ) )	win_a =1 ;
			else if( ( player1[4][6] && player1[4][5] && player1[4][4] && player1[4][3] )  || ( player1[4][5] && player1[4][4] && player1[4][3] && player1[4][2] ) || ( player1[4][4] && player1[4][3] && player1[4][2] && player1[4][1] ) || ( player1[4][3] && player1[4][2] && player1[4][1] && player1[4][0] ) )	win_a =1 ;
			else if( ( player1[5][6] && player1[5][5] && player1[5][4] && player1[5][3] )  || ( player1[5][5] && player1[5][4] && player1[5][3] && player1[5][2] ) || ( player1[5][4] && player1[5][3] && player1[5][2] && player1[5][1] ) || ( player1[5][3] && player1[5][2] && player1[5][1] && player1[5][0] ) )	win_a =1 ;
			
	
		// Column win Player1
			else if( ( player1[0][6] && player1[1][6] && player1[2][6] && player1[3][6] )  || ( player1[1][6] && player1[2][6] && player1[3][6] && player1[4][6] ) || ( player1[2][6] && player1[3][6] && player1[4][6] && player1[5][6] )  ) win_a =1 ;
			else if( ( player1[0][5] && player1[1][5] && player1[2][5] && player1[3][5] )  || ( player1[1][5] && player1[2][5] && player1[3][5] && player1[4][5] ) || ( player1[2][5] && player1[3][5] && player1[4][5] && player1[5][5] )  ) win_a =1 ;
			else if( ( player1[0][4] && player1[1][4] && player1[2][4] && player1[3][4] )  || ( player1[1][4] && player1[2][4] && player1[3][4] && player1[4][4] ) || ( player1[2][4] && player1[3][4] && player1[4][4] && player1[5][4] )  ) win_a =1 ;
			else if( ( player1[0][3] && player1[1][3] && player1[2][3] && player1[3][3] )  || ( player1[1][3] && player1[2][3] && player1[3][3] && player1[4][3] ) || ( player1[2][3] && player1[3][3] && player1[4][3] && player1[5][3] )  ) win_a =1 ;
			else if( ( player1[0][2] && player1[1][2] && player1[2][2] && player1[3][2] )  || ( player1[1][2] && player1[2][2] && player1[3][2] && player1[4][2] ) || ( player1[2][2] && player1[3][2] && player1[4][2] && player1[5][2] )  ) win_a =1 ;
			else if( ( player1[0][1] && player1[1][1] && player1[2][1] && player1[3][1] )  || ( player1[1][1] && player1[2][1] && player1[3][1] && player1[4][1] ) || ( player1[2][1] && player1[3][1] && player1[4][1] && player1[5][1] )  ) win_a =1 ;
			else if( ( player1[0][0] && player1[1][0] && player1[2][0] && player1[3][0] )  || ( player1[1][0] && player1[2][0] && player1[3][0] && player1[4][0] ) || ( player1[2][0] && player1[3][0] && player1[4][0] && player1[5][0] )  ) win_a =1 ;
			else win_a =0;	

	
end

// Assigns 
assign rst_vga = ~ ( rst | o_left  | o_put | o_right  ); 

assign player = turn ;
assign vsync = vsync_;
assign invalid_move = invalid_move_col | invalid_move_r;

// Connect with VGA

vga vga(clk,rst_vga,turn,panel,player1,player2,put_line,hsync,vsync_,red,green,blue);


			
endmodule