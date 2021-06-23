`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent
// Engineer: Arthur Brown
// 
// Create Date: 09/07/2017 11:30:35 AM
// Module Name: top
// Project Name: Zybo Z7 XADC Demo
// Target Devices: Zybo Z7 10 or 20
// Tool Versions: Vivado 2016.4
// Description: This demo instantiates an XADC Wizard block and uses it to capture data from the JXADC port. 
//              This data is displayed as the brightness of the four onboard LEDs.
// 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module xadc_user_logic_pot_led_out(
	input S_AXI_ACLK,
    input slv_reg_wren,
    input slv_reg_rden,
    input [2:0] axi_awaddr,
    input [2:0] axi_araddr,
    input [31:0] S_AXI_WDATA,
    input S_AXI_ARESETN,
    
    output [15:0] data_out,
    output wire [3:0] led,
    input [7:0] ja
);
    reg [6:0] daddr = 0; // address of channel to be read
    reg [1:0] ledidx = 0; // index of the led to capture data for
    reg [3:0] sw_reg;
    
    wire eoc; // xadc end of conversion flag
    wire [15:0] dout; // xadc data out bus
    wire drdy;
    
    reg [1:0] _drdy = 0; // delayed data ready signal for edge detection
    
    reg [7:0] data0 = 0, // stored XADC data, only the uppermost byte
              data1 = 0,
              data2 = 0,
              data3 = 0;
              
    reg [7:0] pwm_count; // shared pwm counter
    reg [7:0] pwm_duty0; // duty cycles for the 4 pwm led brightness controllers
    reg [7:0] pwm_duty1;
    reg [7:0] pwm_duty2;
    reg [7:0] pwm_duty3;
    
    xadc_wiz_0 myxadc (
        .dclk_in        (S_AXI_ACLK),
        .den_in         (eoc), // drp enable, start a new conversion whenever the last one has ended
        .dwe_in         (0),
        .daddr_in       (daddr), // channel address
        .di_in          (0),
        .do_out         (dout), // data out
        .drdy_out       (drdy), // data ready
        .eoc_out        (eoc), // end of conversion
       
        .vauxn6         (ja[7]),
        .vauxp6         (ja[3]),
        
        .vauxn7         (ja[5]),
        .vauxp7         (ja[1]),
        
        .vauxn14        (ja[4]),
        .vauxp14        (ja[0]),
        
        .vauxn15        (ja[6]),
        .vauxp15        (ja[2])
    );
    
	assign data_out = dout[15:0];
	
	always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
           sw_reg <= 4'b0;
       else 
          begin
              if (slv_reg_wren && (axi_awaddr == 3'h3)) 
                  begin
                      sw_reg <= S_AXI_WDATA[3:0];
                  end
          end
     end
	
    always@(posedge S_AXI_ACLK)
        _drdy <= {_drdy[0], drdy};
        
    always@(*)
        case (ledidx)
        0: daddr = 7'h1E;
        1: daddr = 7'h17;
        2: daddr = 7'h1F;
        3: daddr = 7'h16;
        default: daddr = 7'h1E;
        endcase
        
    always@(posedge S_AXI_ACLK) begin
        if (_drdy == 2'b10) begin // on negative edge
            ledidx <= ledidx + 1;
            case (ledidx)
            0: data0 <= dout[15:8];
            1: data1 <= dout[15:8];
            2: data2 <= dout[15:8];
            3: data3 <= dout[15:8];
            endcase
        end
    end
    
    always@(posedge S_AXI_ACLK)
        pwm_count <= pwm_count + 1;
        
    always@(posedge S_AXI_ACLK)
        if (pwm_count == 0) begin
            pwm_duty0 <= data0;
            pwm_duty1 <= data1;
            pwm_duty2 <= data2;
            pwm_duty3 <= data3;
        end
   
    assign led[0] = (pwm_count <= pwm_duty0) ? 1 : 0;
    assign led[1] = (pwm_count <= pwm_duty1) ? 1 : 0;
    assign led[2] = (pwm_count <= pwm_duty2) ? 1 : 0;
    assign led[3] = (pwm_count <= pwm_duty3) ? 1 : 0;
endmodule

 
//***********************************************************
