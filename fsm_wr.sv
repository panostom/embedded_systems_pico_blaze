module fsm_wr(
    input logic [15:0] median,
    input logic median_en,
    output logic [15:0] wr_data,
    output logic [2:0] address_wr,
    output logic wea,   //write enable gia th bram
    output logic read_en,
    clk_rst_intrfc interfc
    );
  
  
typedef enum logic[1:0] {IDLE, WRITE, PREPARE} state_t;
state_t fsm_state;  
logic [2:0] addr_count;

always_ff @(posedge interfc.clk or negedge interfc.rstn)begin
    if(!interfc.rstn)begin
        fsm_state<=IDLE;
        wea<=0;     //write enable
        read_en<=0; //gia to fsm_rd
        addr_count<=0;  //metrhths gia th dieuthunsh pou grafw
        wr_data<=16'b0;
        address_wr<=3'b0;
    end
    else begin
        case(fsm_state)
            IDLE: begin
                wea<=0;
                read_en<=0;
                if(median_en)begin
                    fsm_state<=WRITE;
                    wr_data<=median;
                end
                else begin
                    fsm_state<=IDLE;
                    wr_data<=0;
                end
            end
            WRITE:begin
                wea<=1;       //swsta to shma enable, to wr_data diathrei idia thn timh logw flip flop
                read_en<=0;
                address_wr<=addr_count;
                fsm_state<=PREPARE;
            end
            PREPARE:begin       //eisagwgh kai 3hs katastashs gia na allazei swsta kai kathara to addr_count
                wea<=0;     //energo mono gia 1 kuklo to write enable sto WRITE
                wr_data<=0;
                addr_count<=addr_count+1;
                if(addr_count==7) begin
                    addr_count<=0;
                    read_en<=1;
                end
                else begin
                    read_en<=0;
                end
                fsm_state<=IDLE;
            end
        endcase
    end   
end   
    
property MD_EN_CHK_NEXT;
    @(posedge interfc.clk) disable iff(!interfc.rstn)
        (median_en) |=> (fsm_state==WRITE);
endproperty
CHECK_WRITE:assert property (MD_EN_CHK_NEXT); 

property CHK_NXT_IDLE;
    @(posedge interfc.clk) disable iff(!interfc.rstn)
        (wea) |=> (fsm_state==IDLE);
endproperty
CHECK_IDLE:assert property (CHK_NXT_IDLE);    
    
endmodule : fsm_wr