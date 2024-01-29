module ultra_top(
    input [15:0] data_i,
    input data_av_ai,
    output [7:0] avg_o,
    output avg_o_en,
    clk_rst_intrfc interfc
    );
                    //shmata gia diasundesh twn monadwn
logic data_av_sync;    
logic [15:0] median;
logic median_en;
logic [15:0] wr_data;
logic [2:0] address_wr;
logic wea;
logic read_en;
logic [15:0] rd_data;
logic [2:0] addr_rd;

logic [7:0] in_porta_i;
logic [7:0] in_portb_i;
logic [7:0] in_portc_i;
logic [7:0] in_portd_i;
logic       interrupt_ack_o;
logic       write_strobe_o;
logic       k_write_strobe_o;
logic       read_strobe_o;
logic [7:0] out_portw_o;
logic [7:0] out_porty_o;
logic [7:0] out_portz_o;	
logic [7:0] out_portk0_o;
logic [7:0] out_portk1_o;
logic [7:0] port_id_o;
    
sync_stage sync_stage_inst(
    .data_av_ai(data_av_ai),
    .data_av_sync(data_av_sync),
    .interfc(interfc)
    );
    
median_filter median_filter_inst(
    .data_i(data_i),
    .data_av_sync(data_av_sync),
    .median(median),
    .median_en(median_en),
    .inst_in(interfc)
    );

fsm_wr fsm_wr_inst(
    .median(median),
    .median_en(median_en),
    .wr_data(wr_data),
    .address_wr(address_wr),
    .wea(wea),   //write enable gia th bram
    .read_en(read_en),
    .interfc(interfc)
    );    
                
picoblaze_top picoblaze_top_inst (
    .cpu_rst_i(!interfc.rstn),
    .clk_i(interfc.clk),
    .interrupt_req_i(read_en),
    .in_porta_i(rd_data[7:0]), //dinw ta 8 LSB
    .in_portb_i(in_portb_i),
    .in_portc_i(in_portc_i),
    .in_portd_i(in_portd_i),
    .interrupt_ack_o(interrupt_ack_o),
    .write_strobe_o(write_strobe_o),
    .k_write_strobe_o(k_write_strobe_o),
    .read_strobe_o(read_strobe_o),
    .out_portw_o(out_portw_o),
    .out_portx_o(avg_o),
    .out_porty_o(out_porty_o),
    .out_portz_o(out_portz_o),	
    .out_portk0_o(out_portk0_o),
    .out_portk1_o(out_portk1_o),
    .port_id_o(port_id_o)
    );
    
    assign avg_o_en=out_portk0_o[0]; //krataw mono to LSB apo to output port, afou xerw oti eite 1 eite 0 tha einai, enable shma
    
    bram_mdl bram_mdl_inst(
    .clka(interfc.clk),
    .wea(wea), 
    .addra(address_wr), 
    .dina(wr_data),
    .clkb(interfc.clk), 
    .addrb(out_portw_o),
    .doutb(rd_data)
  );   
       
endmodule
