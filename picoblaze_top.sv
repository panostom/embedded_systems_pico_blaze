module picoblaze_top (
	input  logic       cpu_rst_i,
	input  logic       clk_i,
	input  logic       interrupt_req_i,
	input  logic [7:0] in_porta_i,
	input  logic [7:0] in_portb_i,
	input  logic [7:0] in_portc_i,
	input  logic [7:0] in_portd_i,
	output logic       interrupt_ack_o,
	output logic       write_strobe_o,
	output logic       k_write_strobe_o,
	output logic       read_strobe_o,
	output logic [7:0] out_portw_o,
	output logic [7:0] out_portx_o, //edw bgainei to avg_o
	output logic [7:0] out_porty_o,
	output logic [7:0] out_portz_o,	
	output logic [7:0] out_portk0_o,
	output logic [7:0] out_portk1_o,
	output logic [7:0] port_id_o
);

logic	[11:0]	address;
logic	[17:0]	instruction;
logic			bram_enable;
//logic	[7:0]		port_id;
logic	[7:0]		out_port;
logic	[7:0]		in_port;
//logic			write_strobe;
//logic			k_write_strobe;
//logic			read_strobe;
logic			interrupt;            //See note above
//logic			interrupt_ack;
logic			kcpsm6_sleep;         //See note above
//logic			kcpsm6_reset;         //See note above

//
// Some additional signals are required if your system also needs to reset KCPSM6. 
//

logic			cpu_reset;
logic			rdl;

//
// When interrupt is to be used then the recommended circuit included below requires 
// the following signal to represent the request made from your system.
//

//logic			int_request;

//
///////////////////////////////////////////////////////////////////////////////////////////
// Circuit Descriptions
///////////////////////////////////////////////////////////////////////////////////////////
//

  //
  /////////////////////////////////////////////////////////////////////////////////////////
  // Instantiate KCPSM6 and connect to Program Memory
  /////////////////////////////////////////////////////////////////////////////////////////
  //
  // The KCPSM6 parameters can be defined as required but the default values are shown below
  // and these would be adequate for most designs.
  //

  kcpsm6 #(
	.interrupt_vector	(12'h3FF),
	.scratch_pad_memory_size(64),
	.hwbuild		(8'h00))
  processor (
	.address 		(address),
	.instruction 	(instruction),
	.bram_enable 	(bram_enable),
	.port_id 		(port_id_o),
	.write_strobe 	(write_strobe_o),
	.k_write_strobe 	(k_write_strobe_o),
	.out_port 		(out_port),
	.read_strobe 	(read_strobe_o),
	.in_port 		(in_port),
	.interrupt 		(interrupt),
	.interrupt_ack 	(interrupt_ack_o),
	.reset 		(cpu_rst_i),
	.sleep		(kcpsm6_sleep),
	.clk 			(clk_i)); 

  //
  // In many designs (especially your first) interrupt and sleep are not used.
  // Tie these inputs Low until you need them. 
  // 

  assign kcpsm6_sleep = 1'b0;
  //assign interrupt = 1'b0;

  // The generics should be set to define the family, program size and enable the JTAG
  // Loader. As described in the documentation the initial recommended values are.  
  //    'S6', '1' and '1' for a Spartan-6 design.
  //    'V6', '2' and '1' for a Virtex-6 design.
  // Note that all 12-bits of the address are connected regardless of the program size
  // specified by the generic. Within the program memory only the appropriate address bits
  // will be used (e.g. 10 bits for 1K memory). This means it that you only need to modify 
  // the generic when changing the size of your program.   
  //
  // When JTAG Loader updates the contents of the program memory KCPSM6 should be reset 
  // so that the new program executes from address zero. The Reset During Load port 'rdl' 
  // is therefore connected to the reset input of KCPSM6.
  //

  program_rom_file #(
	.C_FAMILY		   ("V6"),   	//Family 'S6' or 'V6'
	.C_RAM_SIZE_KWORDS	(1),  	//Program size '1', '2' or '4'
	.C_JTAG_LOADER_ENABLE	(0))  	//Include JTAG Loader when set to '1' 
  program_rom (    				//Name to match your PSM file
 	.rdl 			(),
	.enable 		(bram_enable),
	.address 		(address),
	.instruction 	(instruction),
	.clk 			(clk_i)
);


  //
  /////////////////////////////////////////////////////////////////////////////////////////
  // Constant-Optimised Output Ports 
  /////////////////////////////////////////////////////////////////////////////////////////
  //
  //
  // Implementation of the Constant-Optimised Output Ports should follow the same basic 
  // concepts as General Output Ports but remember that only the lower 4-bits of 'port_id'
  // are used and that 'k_write_strobe' is used as the qualifier.
  //

    always_ff @ (posedge clk_i)
    begin
      // 'k_write_strobe_o' is used to qualify all writes to constant output ports.
      if (k_write_strobe_o == 1'b1) begin
        // Write to output_port_k at port address 01 hex
        if (port_id_o[0] == 1'b1) begin //one-hot kwdikopoihsh
          out_portk0_o <= out_port;
        end
        // Write to output_port_c at port address 02 hex
        else if (port_id_o[1] == 1'b1) begin
          out_portk1_o <= out_port;
        end
        /*else begin
            out_portk0_o<=out_portk0_o;
            out_portk1_o<=out_portk1_o;
        end*/
      end
    end
    
        always_ff @ (posedge clk_i) //gia to portw,x,y,z
            begin
            if(write_strobe_o==1)begin  //edw pairnw thn pulh AND write_strobe kai port_id bit
                case(port_id_o)
                    8'b0001:    out_portw_o<=out_port;
                    8'b0010:    out_portx_o<=out_port;
                    8'b0100:    out_porty_o<=out_port;
                    8'b1000:    out_portz_o<=out_port;
                endcase
            end
        end
        
    always_ff @ (posedge clk_i) //gia to porta,b,c,d
        begin
            case(port_id_o)
                8'b0001 : in_port<=in_porta_i;
                8'b0010 : in_port<=in_portb_i;
                8'b0100 : in_port<=in_portc_i;
                8'b1000 : in_port<=in_portd_i;
                default : in_port<=in_port;
            endcase 
        end   
  //
  /////////////////////////////////////////////////////////////////////////////////////////
  // Recommended 'closed loop' interrupt interface (when required).
  /////////////////////////////////////////////////////////////////////////////////////////
  //
  // Interrupt becomes active when 'int_request' is observed and then remains active until 
  // acknowledged by KCPSM6. Please see description and waveforms in documentation.
  //

  always_ff @ (posedge clk_i, posedge cpu_rst_i)
  begin
      if (cpu_rst_i)
        interrupt <= 1'b0;
      else if (interrupt_ack_o == 1'b1) begin
         interrupt <= 1'b0;
      end
      else if (interrupt_req_i == 1'b1) begin
          interrupt <= 1'b1;
      end
      else begin
          interrupt <= interrupt;   //SOS!!!!!!!!!!!!!!!!
      end
  end
  
endmodule : picoblaze_top

