module sberday_de10lite (
  //--------------- CLOCK              ------------------//
    input                   ADC_CLK_10,
    input                   MAX10_CLK1_50,
    input                   MAX10_CLK2_50,
  //--------------- SDRAM              ------------------//
    output        [12:0]    DRAM_ADDR,
    output         [1:0]    DRAM_BA,
    output                  DRAM_CAS_N,
    output                  DRAM_CKE,
    output                  DRAM_CLK,
    output                  DRAM_CS_N,
    inout         [15:0]    DRAM_DQ,
    output                  DRAM_LDQM,
    output                  DRAM_RAS_N,
    output                  DRAM_UDQM,
    output                  DRAM_WE_N,
  //--------------- SEG7               ------------------//
    output         [7:0]    HEX0,
    output         [7:0]    HEX1,
    output         [7:0]    HEX2,
    output         [7:0]    HEX3,
    output         [7:0]    HEX4,
    output         [7:0]    HEX5,
  //--------------- KEY                ------------------//
    input          [1:0]    KEY,
  //--------------- LED                ------------------//
    output         [9:0]    LEDR,
  //--------------- SW                 ------------------//
    input          [9:0]    SW,
  //--------------- VGA                ------------------//
    output reg     [3:0]    VGA_B,
    output reg     [3:0]    VGA_G,
    output reg              VGA_HS,
    output reg     [3:0]    VGA_R,
    output reg              VGA_VS,
  //--------------- Accelerometer      ------------------//
    output                  GSENSOR_CS_N,
    input          [2:1]    GSENSOR_INT,
    output                  GSENSOR_SCLK,
    inout                   GSENSOR_SDI,
    inout                   GSENSOR_SDO,
  //--------------- Arduino            ------------------//
    inout         [15:0]    ARDUINO_IO,
    inout                   ARDUINO_RESET_N,
  //--------------- GPIO, GPIO connect to GPIO Default --//
    inout         [35:0]    GPIO
);
  //------------------------- Signals declaration          ----------------------------//
    //----------------------- Clocks                       --------------------------//
      wire            vga_clk     ;     // 25 MHz, phase 0 degrees
      wire            spi_clk     ;     //  2 MHz, phase 0 degrees
      wire            spi_clk_out ;     //  2 MHz, phase 270 degrees
      wire            btn_clk     ;     //  1 MHz, phase   0 degrees
    //----------------------- VGA Controller               --------------------------//
      wire [31:0]     col, row;         // Pixcels Coordinates 
      wire [3:0]      red, green, blue; // Pixcels Colors
      // Timing signals - don't touch these.
        wire          h_sync, v_sync;   // Horizontal & Vertical synchronization
        wire          disp_ena;         // Image output is allowed
    //----------------------- ROM                          --------------------------//
      wire  [15:0]  rom_out     ;       // VGA memory reading data
      reg   [15:0]  rom_reg     ;       // VGA memory registred reading data
      wire  [13:0]  read_address;       // VGA Memory reading address
    //----------------------- ROM Ghost Image Read         --------------------------//
      wire  [15:0]  rom_ghost_out     ;       // VGA memory reading data
      reg   [15:0]  rom_ghost_reg     ;       // VGA memory registred reading data
      wire  [13:0]  read_ghost_address;       // VGA Memory reading address
    //----------------------- JoyStick                     --------------------------//
      // JoyStick Cross
        wire js_button_a, js_button_a_u, js_button_a_d;
        wire js_button_b, js_button_b_u, js_button_b_d;
        wire js_button_c, js_button_c_u, js_button_c_d;
        wire js_button_d, js_button_d_u, js_button_d_d;
      // JoyStick start/select buttons
        wire js_button_e, js_button_e_u, js_button_e_d;
        wire js_button_f, js_button_f_u, js_button_f_d;
      wire [11:0] joystick_data_x;      // JoyStick X data from ADC
      wire [11:0] joystick_data_y;      // JoyStick Y data from ADC
    //----------------------- Accelerometor                --------------------------//
      wire [15:0]     accel_data_x;     // FPGA board accelerometer X data
      wire [15:0]     accel_data_y;     // FPGA board accelerometer Y data
      wire            accel_data_update;
    //----------------------- Demo                         --------------------------//
      wire [1:0]      demo_regime_status;
      
  //------------------------- Clock & Reset                ----------------------------//
    assign arst_n = js_button_e;
    pll pll_inst (
      .inclk0   ( MAX10_CLK1_50 ),
      .c0       (               ),  // 50 MHz, phase   0 degrees
      .c1       ( vga_clk       ),  // 25 MHz, phase   0 degrees
      .c2       ( spi_clk       ),  //  2 MHz, phase   0 degrees
      .c3       ( spi_clk_out   ),  //  2 MHz, phase 270 degrees
      .c4       ( btn_clk       ),  //  1 MHz, phase   0 degrees
      .locked   (               )
    );

  //------------------------- IO Pads assertions           ----------------------------//
    //----------------------- JoySTick Shield              --------------------------//
      //----------------------- Debouncers                   --------------------------//
        button_debouncer dbns_a (
          .clk         ( vga_clk       ),
          .arst_n      ( arst_n        ),
          .sw_i        ( ARDUINO_IO[2] ),
          .sw_state_o  ( js_button_a   ),
          .sw_down_o   ( js_button_a_d ),
          .sw_up_o     ( js_button_a_u )
        );
        button_debouncer dbns_b (
          .clk         ( vga_clk       ),
          .arst_n      ( arst_n        ),
          .sw_i        ( ARDUINO_IO[3] ),
          .sw_state_o  ( js_button_b   ),
          .sw_down_o   ( js_button_b_d ),
          .sw_up_o     ( js_button_b_u )
        );
        button_debouncer dbns_c (
          .clk         ( vga_clk       ),
          .arst_n      ( arst_n        ),
          .sw_i        ( ARDUINO_IO[4] ),
          .sw_state_o  ( js_button_c   ),
          .sw_down_o   ( js_button_c_d ),
          .sw_up_o     ( js_button_c_u )
        );
        button_debouncer dbns_d (
          .clk         ( vga_clk       ),
          .arst_n      ( arst_n        ),
          .sw_i        ( ARDUINO_IO[5] ),
          .sw_state_o  ( js_button_d   ),
          .sw_down_o   ( js_button_d_d ),
          .sw_up_o     ( js_button_d_u )
        );
        button_debouncer dbns_e (
          .clk         ( vga_clk       ),
          .arst_n      ( arst_n        ),
          .sw_i        ( ARDUINO_IO[6] ),
          .sw_state_o  ( js_button_e   ),
          .sw_down_o   ( js_button_e_d ),
          .sw_up_o     ( js_button_e_u )
        );
        button_debouncer dbns_f (
          .clk         ( vga_clk       ),
          .arst_n      ( arst_n        ),
          .sw_i        ( ARDUINO_IO[7] ),
          .sw_state_o  ( js_button_f   ),
          .sw_down_o   ( js_button_f_d ),
          .sw_up_o     ( js_button_f_u )
        );
      // Analog-Digital Convertor //
     	  adc0 u0 (
          .CLOCK  ( vga_clk         ),   // CLK 25MHz
          .CH0    ( joystick_data_x ),   // CH0
          .CH1    ( joystick_data_y ),   // CH1
          .CH2    (                 ),   // CH2
          .CH3    (                 ),   // CH3
          .CH4    (                 ),   // CH4
          .CH5    (                 ),   // CH5
          .CH6    (                 ),   // CH6
          .CH7    (                 ),   // CH7
          .RESET  (           )    // reset
        );
    //----------------------- LED Red                      --------------------------//
      assign LEDR [1:0] = demo_regime_status;
      assign LEDR [9:2] = 8'h00;
    //----------------------- Seven Segments Indicators    --------------------------//
      seg7e seven_segment_indicator_1 (
        .bcd  ( joystick_data_x[11:8] ), // <= PUT YOUR BINARY VALUE HERE
        .seg  ( HEX0 )
      );
      seg7 seven_segment_indicator_2 (
        .bcd  ( joystick_data_x[7:4] ), // <= PUT YOUR BINARY VALUE HERE
        .seg  ( HEX1 )
      );
      seg7e seven_segment_indicator_3 (
        .bcd  ( joystick_data_x[3:0] ), // <= PUT YOUR BINARY VALUE HERE
        .seg  ( HEX2 )
      );
      seg7e seven_segment_indicator_4 (
        .bcd  ( joystick_data_y[11:8] ), // <= PUT YOUR BINARY VALUE HERE
        .seg  ( HEX3 )
      );
      seg7 seven_segment_indicator_5 (
        .bcd  ( joystick_data_y[7:4] ), // <= PUT YOUR BINARY VALUE HERE
        .seg  ( HEX4 )
      );
      seg7e seven_segment_indicator_6 (
        .bcd  ( joystick_data_y[3:0] ), // <= PUT YOUR BINARY VALUE HERE
        .seg  ( HEX5 )
      );
    //----------------------- Accelerometer                --------------------------//
      accel accelerometer (
        //Clocks & Resets
          .clk                ( vga_clk       ),  // 25 MHz, phase   0 degrees
          .spi_clk            ( spi_clk       ),  //  2 MHz, phase   0 degrees
          .spi_clk_out        ( spi_clk_out   ),  //  2 MHz, phase 270 degrees
          .arst_n             ( arst_n        ),
        //Accelerometer values
          .accel_data_x       ( accel_data_x      ),
          .accel_data_y       ( accel_data_y      ),
          .accel_data_update  ( accel_data_update ),
        //Accelerometer IOs
          .GSENSOR_CS_N       ( GSENSOR_CS_N  ),
          .GSENSOR_INT        ( GSENSOR_INT   ),
          .GSENSOR_SCLK       ( GSENSOR_SCLK  ),
          .GSENSOR_SDI        ( GSENSOR_SDI   ),
          .GSENSOR_SDO        ( GSENSOR_SDO   )
      );
    //----------------------- VGA controller               --------------------------//
      vga_controller control (
        .pixel_clk  ( vga_clk       ), // Pixel clock 25MHz
        .reset_n    ( arst_n        ), // Active low synchronous reset
        .h_sync     ( h_sync        ), // horizontal sync signal
        .v_sync     ( v_sync        ), // vertical sync signal
        .disp_ena   ( disp_ena      ), // display enable (0 = all colors must be blank)
        .column     ( col           ), // horizontal pixel coordinate
        .row        ( row           )  // vertical pixel coordinate
      );
      //--------------------- VGA IOs                      -------------------------//
      always @(posedge vga_clk) begin
        if (disp_ena == 1'b1) begin
          VGA_R <= red  ;
          VGA_B <= blue ;
          VGA_G <= green;
        end 
        else begin
          VGA_R <= 4'd0;
          VGA_B <= 4'd0;
          VGA_G <= 4'd0;
        end
          VGA_HS <= h_sync;
          VGA_VS <= v_sync;
      end

  //------------------------- ROM                          ---------------------------//
    always @(posedge vga_clk or negedge arst_n) begin //Sber logo memory reading
      if      ( !arst_n )
        rom_reg <= 16'h0;
      else if ( rom_out == 16'h0 )  //If value 0 print zero
        rom_reg <= 16'h0;
      else                          //If value not 0 print green
        rom_reg <= 16'h0080;
    end
    
    //Screen resoulution is 640x480, the logo size is 128x128. We need to put the logo in the center.
    //(640-128)/2=256 & (480-128)/2=176.
    assign read_address = (col - stick_border_hl_c) - 255 + ((row - stick_border_hl_r))*128; 
    rom rom (
      .address  ( read_address   ),
      .clock    ( vga_clk        ),
      .q        ( rom_out        )
    );

    //------------------------- ROM Ghost                 ---------------------------//
    always @(posedge vga_clk or negedge arst_n) begin //Sber logo memory reading
      if      ( !arst_n )
        rom_ghost_reg <= 16'h0;
      else if ( rom_ghost_out == 16'h0 )  //If value 0 print zero
        rom_ghost_reg <= 16'h0;
      else                          //If value not 0 print green
        rom_ghost_reg <= 16'h0FAA;
    end
    
    assign read_ghost_address = (col - ghost_border_hl_c) - 191 + ((row - ghost_border_hl_r)) * 256;

    rom_ghost rom_ghost(
      .address ( read_ghost_address ),
      .clock (vga_clk),
      .q (rom_ghost_out)
    );
	 
	   wire   [9:0]     stick_border_hl_c;
     wire   [8:0]     stick_border_hl_r;

     wire   [9:0]     ghost_border_hl_c;
     wire   [8:0]     ghost_border_hl_r;

  //------------------------- Demo                         ----------------------------//
    demo demo_module (
      //--------------------- Clock & Reset                ----------------------------//
        .btn_clk                ( btn_clk         ),  //CLK 1MHz
        .vga_clk                ( vga_clk         ),
        .arst_n                 ( arst_n          ),
      //--------------------- Accelerometer                ----------------------------//
        .accel_data_x           ( accel_data_x    ),
        .accel_data_y           ( accel_data_y    ),
      //--------------------- JoyStick                     ----------------------------//
        .joystick_data_x        ( joystick_data_x ),
        .joystick_data_y        ( joystick_data_y ),
        .js_button_a            ( js_button_a     ),
        .js_button_b            ( js_button_b     ),
        .js_button_c            ( js_button_c     ),
        .js_button_d            ( js_button_d     ),
        .js_button_f_d          ( js_button_f_d   ),
      //--------------------- Memory data for logo         ----------------------------//
        .rom_data               ( rom_reg         ),  
        .rom_ghost_data         ( rom_ghost_reg ),
      //--------------------- Pixcels Coordinates          ----------------------------//
        .col                    ( col[9:0]        ),  // only bottom 10 bits needed to count to 640
        .row                    ( row[8:0]        ),  // only bottom  9 bits needed to count to 480
      //--------------------- VGA outputs from demo        ----------------------------//
        .red                    ( red             ),  // 4-bit color output
        .green                  ( green           ),  // 4-bit color output
        .blue                   ( blue            ),  // 4-bit color output
      //--------------------- Switches for demo            ----------------------------//
        .SW                     ( SW [2:0]            ),  // We are using switches to change background
      //--------------------- Demo regime status           ----------------------------//
        .demo_regime_status     ( demo_regime_status  ),   // Red led on the board which show REGIME
		  .stick_border_hl_c (stick_border_hl_c),
		  .stick_border_hl_r(stick_border_hl_r),

      .ghost_border_hl_c (enemy_1_border_hl_c),
      .ghost_border_hl_r (enemy_border_hl_r)
    );

endmodule
