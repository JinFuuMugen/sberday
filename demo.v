module demo (
  //--------- Clock & Resets                     --------//
    input          btn_clk         ,  // Pixel clock 1MHz     
    input          vga_clk         ,  // VGA clock 25 MHz	 
    input          arst_n          ,  // Active low synchronous reset   
  //--------- JoyStick                           --------//
    input  [11:0]  joystick_data_x ,
    input  [11:0]  joystick_data_y ,
    input          js_button_a     ,
    input          js_button_b     ,
    input          js_button_c     ,
    input          js_button_d     ,
    input          js_button_f_d   ,
  //--------- Accelerometer                      --------//
    input  [15:0]  accel_data_x    ,
    input  [15:0]  accel_data_y    ,
  //--------- Pixcels Coordinates                --------//
    input  [9:0]   col             ,
    input  [8:0]   row             , 
  //--------- Data from memory with logo         --------//
    input  [15:0]  rom_data        ,
    input  [15:0] rom_ghost_data,
  //--------- VGA outputs                        --------//
    output [3:0]   red             ,  // 4-bit color output
    output [3:0]   green           ,  // 4-bit color output
    output [3:0]   blue            ,  // 4-bit color output
  //--------- Switches for background colour     --------//
    input  [2:0]   SW              ,
  //--------- Regime                             --------//
    output [1:0]   demo_regime_status,    // Red led on the board which show REGIME
	 
	  output reg[9:0]   stick_border_hl_c,
     output  reg[8:0]   stick_border_hl_r,

      output	reg	[9:0]	 enemy_1_border_hl_c,
	 output	reg	[8:0]	 enemy_1_border_hl_r
);
  
  //------------------------- Variables                    ----------------------------//
    //----------------------- Regime control               --------------------------// 
      wire         change_regime ;
      reg   [1:0]  regime_store  ;
    //----------------------- Coordinates regs             --------------------------//
      reg   [11:0] x_store_reg;
      reg   [11:0] y_store_reg;
      reg   [15:0] accel_x_store_reg;
      reg   [15:0] accel_y_store_reg;
    //----------------------- Counters                     --------------------------//
      reg   [18:0] accel_counter;
      reg   [20:0] regime_counter;
      wire         regime_overflow;
      wire         accel_overflow;
    //----------------------- Stick movement               --------------------------//
      parameter    stick_width  = 64; 
      parameter    stick_height = 64; 
      reg          stick_active;
      reg          indicator;
//      reg  [9:0]   stick_border_hl_c;
//      reg  [8:0]   stick_border_hl_r;

	reg 		    enemy_clk;
		reg			 enemy_1_active;
      parameter    enemy_1_width  = 64; 
      parameter    enemy_1_height = 64;
		parameter    enemy_1_path_len = 150;
		parameter    enemy_1_start_position_c = 500;
		parameter    enemy_1_start_position_r = 62;
		reg	[1:0]	 enemy_1_direction;
		reg 	[9:0]	 enemy_1_step_count;
		
		reg			 enemy_2_active;
      parameter    enemy_2_width  = 25; 
      parameter    enemy_2_height = 25;
		parameter    enemy_2_path_len = 300;
		parameter    enemy_2_start_position_c = 200;
		parameter    enemy_2_start_position_r = 10;
		reg	[1:0]	 enemy_2_direction;
		reg 	[9:0]	 enemy_2_step_count;
		reg	[9:0]	 enemy_2_border_hl_c;
		reg	[8:0]	 enemy_2_border_hl_r;
		
		reg			 enemy_3_active;
      parameter    enemy_3_width  = 25; 
      parameter    enemy_3_height = 25;
		parameter    enemy_3_path_len = 500;
		parameter    enemy_3_start_position_c = 0;
		parameter    enemy_3_start_position_r = 0;
		reg	[1:0]	 enemy_3_direction;
		reg 	[9:0]	 enemy_3_step_count;
		reg	[9:0]	 enemy_3_border_hl_c;
		reg	[8:0]	 enemy_3_border_hl_r;
    //----------------------- Sber logo timer              --------------------------//
      reg [31:0]   sber_logo_counter; // 32 bit timer
      reg 	 you_lose;


  //------------------------- Coordinates regs             ----------------------------//
    always @ (posedge btn_clk) begin
      x_store_reg       <= joystick_data_x   ;
      y_store_reg       <= joystick_data_y   ;
      accel_x_store_reg <= accel_data_x ;
      accel_y_store_reg <= accel_data_y ;
    end

  //------------------------- Counters                     ----------------------------//
    always @ ( posedge btn_clk ) begin
      if (accel_counter == 19'd10000) 
        accel_counter <= 0; 
      else 
        accel_counter <= accel_counter + 1'b1;
    end
    //
    assign accel_overflow   = ( accel_counter  == 19'd10000   );
	 
	 reg [11:0] out_background;
	 
	 //// 					labirint //////////////////////////////////////////////////////////
	 always @ (posedge vga_clk or negedge arst_n) begin
		if ( !arst_n ) begin
			out_background <= 0;
		end
		else begin
			if ((col[7:0] < 190) && (row[6:0] < 62))
				out_background = 12'h0;
			else
				out_background = 12'hFFFF;
		end
	end

  //------------------------- Regime control               ----------------------------//
    always @ (posedge vga_clk or negedge arst_n) begin
    if ( !arst_n ) begin
      regime_store <= 2'b11;
    end
    else if ( change_regime && ( regime_store > 2'b00) ) begin
      regime_store <= regime_store - 1'b1;
    end
    else if (regime_store == 2'b00) 
      regime_store <= 2'b11;
    end
    assign change_regime      = js_button_f_d;
    assign demo_regime_status = regime_store;
	 
	 reg  move_c;
	 reg  move_r;

  //------------------------- Stick movement in 3 regimes  ----------------------------//
    always @ (posedge btn_clk or negedge arst_n) begin
      if ( !arst_n ) begin
        stick_border_hl_c <= 0; 
        stick_border_hl_r <= 63;
		  move_c <= 0;
		  move_r <= 0;
      end 
      else 
		if(!you_lose)
		begin
		
			if ( ( stick_border_hl_r[6:0] < 67 ) && ( stick_border_hl_r[6:0] >= 60 ) ) begin
				move_c <= 1;
			end else begin
				move_c <= 0;
			end
			if ( ( stick_border_hl_c[7:0] >= 188 ) && ( stick_border_hl_c[7:0] < 195 ) ) begin
				move_r <= 1;
			end else begin
				move_r <= 0;
			end
			
			
		if (move_r || move_c) begin
        if      (regime_store == 2'b11) begin  // Buttons regime
          if      ( (!js_button_d) && accel_overflow && (stick_border_hl_c != 0  ) && move_c) begin
            stick_border_hl_c <= stick_border_hl_c - 1; 
          end
          else if ( (!js_button_b) && accel_overflow && (stick_border_hl_c != 639-stick_width) && move_c ) begin
            stick_border_hl_c <= stick_border_hl_c + 1; 
          end
          //
          if      ( (!js_button_c) && accel_overflow && (stick_border_hl_r != 479-stick_height) && move_r) begin
            stick_border_hl_r <= stick_border_hl_r + 1; 
          end
          else if ( (!js_button_a) && accel_overflow && (stick_border_hl_r != 0  ) && move_r ) begin
            stick_border_hl_r <= stick_border_hl_r - 1; 
          end
        end
        else if (regime_store == 2'b10) begin  // Accelerometer regime
          if ( ( accel_x_store_reg[15:8] == 8'b0000_0000 ) && accel_overflow && ( stick_border_hl_c != 0   ) && move_c ) begin
            stick_border_hl_c <= stick_border_hl_c - 1; 
          end
          if ( ( accel_x_store_reg[15:8] == 8'b1111_1111 ) && accel_overflow && ( stick_border_hl_c != 639-stick_width ) && move_c ) begin
            stick_border_hl_c <= stick_border_hl_c + 1; 
          end
          if ( ( accel_y_store_reg[15:8] == 8'b0000_0000 ) && accel_overflow && ( stick_border_hl_r != 479-stick_height ) && move_r ) begin
            stick_border_hl_r <= stick_border_hl_r + 1; 
          end
          if ( ( accel_y_store_reg[15:8] == 8'b1111_1111 ) && accel_overflow && ( stick_border_hl_r != 0   ) && move_r ) begin
            stick_border_hl_r <= stick_border_hl_r - 1; 
          end
        end
        else if (regime_store == 2'b01) begin  // JoyStick regime
          if      ( ( x_store_reg[11:4] > 8'h90 ) && accel_overflow && ( stick_border_hl_c != 639-stick_width ) && move_c ) begin
            stick_border_hl_c <= stick_border_hl_c + 1; 
          end
          else if ( ( x_store_reg[11:4] < 8'h1f   ) && accel_overflow && ( stick_border_hl_c != 0   ) && move_c ) begin
            stick_border_hl_c <= stick_border_hl_c - 1; 
          end
          else begin
            stick_border_hl_c <= stick_border_hl_c; 
          end
          //
          if      ( ( y_store_reg[11:4] > 8'h90  ) && accel_overflow && ( stick_border_hl_r != 0   ) && move_r ) begin
            stick_border_hl_r <= stick_border_hl_r - 1; 
          end
          else if ( ( y_store_reg[11:4] < 8'h1f  ) && accel_overflow && ( stick_border_hl_r != 479-stick_height ) && move_r ) begin
            stick_border_hl_r <= stick_border_hl_r + 1; 
          end
          else begin
            stick_border_hl_r <= stick_border_hl_r; 
          end
        end
		  end else begin //move err
			stick_border_hl_r <= stick_border_hl_r - 1;
			stick_border_hl_c <= stick_border_hl_c - 1;
		  end
		  
      end
    end

  //------------------------- Sber logo on start           ----------------------------//
//    always @ ( posedge vga_clk or negedge arst_n) begin 
//      if      ( !arst_n )  
//        sber_logo_counter <= 32'b0;
//      else if ( sber_logo_counter < 32'd1_00000000 )
//        sber_logo_counter <= sber_logo_counter + 1'b1;

	 reg [31:0] enemy_clk_count;
	 //------------------------- Enemy clk          ----------------------------//
    always @ ( posedge vga_clk or negedge arst_n) begin 
      if      ( !arst_n ) begin
        enemy_clk <='b0;
		  enemy_clk_count <= 32'b0;
      end
		else  begin
			if(enemy_clk_count < 32'd100000)
				enemy_clk_count <= enemy_clk_count + 1'b1;
			else begin
				enemy_clk_count <= 0;
				enemy_clk <= ~enemy_clk;
			end
		end
    end 
	 
	 
	 //------------------------- Enemy movement           ----------------------------//
    always @ ( posedge enemy_clk or negedge arst_n) begin 
      if      ( !arst_n )  begin
        enemy_1_border_hl_c <= enemy_1_start_position_c;
		  enemy_1_border_hl_r <= enemy_1_start_position_r;
		  enemy_1_step_count  <= 32'b0;
		  enemy_1_direction   <= 'h1;
		  
        enemy_2_border_hl_c <= enemy_2_start_position_c;
		  enemy_2_border_hl_r <= enemy_2_start_position_c;
		  enemy_2_step_count  <= 32'b0;
		  enemy_2_direction   <= 'h3;
		  
        enemy_3_border_hl_c <= enemy_3_start_position_c;
		  enemy_3_border_hl_r <= enemy_3_start_position_c;
		  enemy_3_step_count  <= 32'b0;
		  enemy_3_direction   <= 'h4;
		end
      else 
		if (!you_lose) 
		begin 
			if ( enemy_1_step_count < enemy_1_path_len) begin
				case(enemy_1_direction)
					'h1: begin
						enemy_1_border_hl_c <= enemy_1_border_hl_c + 1'b1;
					end
					'h2: begin
						enemy_1_border_hl_c <= enemy_1_border_hl_c - 1'b1;
					end
					'h3: begin
						enemy_1_border_hl_c <= enemy_1_border_hl_r + 1'b1;
					end
					'h4: begin
						enemy_1_border_hl_c <= enemy_1_border_hl_r - 1'b1;
					end
				endcase
				enemy_1_step_count <= enemy_1_step_count + 1'b1;
			end
			else begin
				case(enemy_1_direction)
					'h1: begin
						enemy_1_direction <= 'h2;
					end
					'h2: begin
						enemy_1_direction <= 'h1;
					end
					'h3: begin
						enemy_1_direction <= 'h4;
					end
					'h4: begin
						enemy_1_direction <= 'h3;
					end
				endcase
				enemy_1_step_count <= 32'b0;
			end
		end
    end 
//    end 

    always @ (posedge vga_clk or negedge arst_n) begin
      if (!arst_n) begin
        indicator         <= 0;
        stick_active      <= 0;
        enemy_1_active		  <= 0;
		  enemy_2_active		  <= 0;
		  you_lose				  <= 0;
		  enemy_3_active		  <= 0;
      end 
//      else if (sber_logo_counter < 32'd1_00000000) begin
//        stick_active      <= (col >= 10'd256) & (col <= 10'd384) & (row >= 9'd176) & (row <= 9'd304); // Logo size is 128x128 Pixcels
//        indicator         <= 0;  
//      end 
      else begin
        stick_active      <= (col >= stick_border_hl_c) & (col <= (stick_border_hl_c + stick_width)) & 
                             (row >= stick_border_hl_r) & (row <= (stick_border_hl_r + stick_height)) & (|rom_data);  
          enemy_1_active 	  <= (col >= enemy_1_border_hl_c) & (col <= (enemy_1_border_hl_c + enemy_1_width)) & 
                             (row >= enemy_1_border_hl_r) & (row <= (enemy_1_border_hl_r + enemy_1_height))& (|rom_ghost_data);
									  
		  you_lose			  <= (((stick_border_hl_c + stick_width >= enemy_1_border_hl_c) & 
										(stick_border_hl_c + stick_width <= enemy_1_border_hl_c + enemy_1_width)) |
										 ((stick_border_hl_c <= enemy_1_border_hl_c + enemy_1_width)&
										 (stick_border_hl_c >= enemy_1_border_hl_c)))&(
										 ((stick_border_hl_r + stick_height >= enemy_1_border_hl_r) &
										 (stick_border_hl_r + stick_height <= enemy_1_border_hl_r + enemy_1_height)) |
										
										 ((stick_border_hl_r >= enemy_1_border_hl_r) &
										 (stick_border_hl_r <= enemy_1_border_hl_r + enemy_1_height))
										 ) |(
										 (stick_border_hl_c  + stick_width >= enemy_1_border_hl_c + enemy_1_width) & 
										 (stick_border_hl_c  <= enemy_1_border_hl_c) &
										 (stick_border_hl_r  <= enemy_1_border_hl_r) &
										 (stick_border_hl_r + stick_height >= enemy_1_border_hl_r + enemy_1_height))
										 ;
                     indicator         <= 0;      
      end
    end
   
  //------------------------ VGA outputs                   ----------------------------// 
//    assign    red     = stick_active ? ( indicator ? 4'hf : rom_data[11:8]) : (SW[0] ? 4'h8 : {4{out_background[0]}}); 
//    assign    green   = stick_active ? ( indicator ? 4'hf : rom_data[7:4] ) : (SW[1] ? 4'h8 : {4{out_background[1]}});
//    assign    blue    = stick_active ? ( indicator ? 4'hf : rom_data[3:0] ) : (SW[2] ? 4'h8 : {4{out_background[2]}});
		assign    red     = you_lose ? 4'hf : enemy_1_active ? rom_ghost_data[11:8] : (stick_active ? ( indicator ? 4'hf : rom_data[11:8]) : out_background[3:0]); 
		assign    green   = you_lose ? 4'h0 : enemy_1_active ? rom_ghost_data[7:4]  : (stick_active ? ( indicator ? 4'hf : rom_data[7:4] ) : out_background[7:4]);
		assign    blue    = you_lose ? 4'h0 : enemy_1_active ? rom_ghost_data[3:0]  : (stick_active ? ( indicator ? 4'hf : rom_data[3:0] ) : out_background[11:8]);
//  assign    red     = you_lose ? 4'hf : (enemy_1_active ? rom_ghost_data[11:8] : (stick_active ? ( indicator ? 4'hf : rom_data[11:8]) : (SW[0] ? 4'h8 : 4'h0))); 
//    assign    green   = you_lose ? 4'h0 : (enemy_1_active ? rom_ghost_data[7:4]  : (stick_active ? ( indicator ? 4'hf : rom_data[7:4] ) : (SW[1] ? 4'h8 : 4'h0)));
//    assign    blue    = you_lose ? 4'h0 : (enemy_1_active ? rom_ghost_data[3:0]  : (stick_active ? ( indicator ? 4'hf : rom_data[3:0] ) : (SW[2] ? 4'h8 : 4'h0)));


endmodule
