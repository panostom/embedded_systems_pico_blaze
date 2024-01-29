module ultra_top_tb;

timeunit 1ns;
timeprecision 100ps;

logic [15:0] data_i;
logic data_av_ai;
logic [7:0] avg_o;
logic avg_o_en;
logic clk=0;
logic rstn=0;

clk_rst_intrfc interface_of();
    
assign interface_of.clk=clk;
assign interface_of.rstn=rstn;

ultra_top ultra_top_inst(
    .data_i(data_i),
    .data_av_ai(data_av_ai),
    .avg_o(avg_o),
    .avg_o_en(avg_o_en),
    .interfc(interface_of)
);

`define PERIOD 10

always
    #(`PERIOD/2) clk = ~clk;
    
    // Monitor Results
initial begin
   $timeformat ( -9, 1, " ns", 9 );
   $monitor ( "time=%t data_av_ai=%b rstn=%b data_i=%d avg_o=%d",
	        $time,   data_av_ai,  rstn,   data_i,   avg_o );
   #(`PERIOD * 250)
   $display ( "REGISTER TEST TIMEOUT" );
   $finish;
end

// Verify Results

logic [3:0] counter=0;
logic [31:0] result=32'b0;
task check_avg; //se mia metablhth tha krataw to apotelesma
    @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            counter=0;
            result=32'b0;
        end
        else begin
            if(ultra_top_inst.median_en)begin
                result=result+ultra_top.median;
                counter=counter+1;
                $display("bazw median=%d, counter=%d",ultra_top.median,counter);
                if(counter==8)begin //mia fora o upologismos tou result
                    result=result>>3;
                    $display("result=%d",result);
                end
            end
            /*if(avg_o_en)begin //kanw ton elegxo mia fora sto telos tou tb
                $display("task_average=%d, module_average=%d", result, ultra_top.avg_o);
                case(result==avg_o)
                    1:$display("Average from your unit is right");
                    0:$display("Average from your unit is not right");
                endcase
            end */ 
        end
    end
endtask

always check_avg();    //gia na trexoun sunexws kai na elegxoun

logic [31:0] acc_result=0;

always      //se ena always block ftiaxnw to athroisma twn 8 arithmwn
    begin : AVERAGE_CHECK
    @(posedge clk) begin
        if(ultra_top_inst.median_en)begin
            acc_result=acc_result+ultra_top_inst.median;
            $display("acc_result=%d",acc_result);
        end  
    end
 end : AVERAGE_CHECK

//endedeigmenos tropos dhmiourgias task (xwris clock), klhsh san sunarthsh
task compare_res(input logic [7:0] average, input [31:0] result_of);
    result_of=result_of>>3;
    $display("average=%d, result_of=%d",average, result_of);
    case(result_of==average)
        1:$display("Average from your unit is right(version 2 of task)");
        0:$display("Average from your unit is not right(version 2 of task)");
    endcase
endtask : compare_res

//assertion pou bgazei mhnuma otan exoume interrupt
always @(posedge clk or negedge rstn) begin
    if(rstn==1)begin
        INTERRUPTION_INFO: assert((ultra_top_inst.picoblaze_top_inst.interrupt_req_i==0))
            else begin
                $display("NOW I GOT INTERRUPT FROM FSM_RD");
            end
    end
end


initial begin
    @(negedge clk) rstn=0; @(negedge clk); rstn=1; @(negedge clk);
    @(posedge clk) #1 data_i=8'd150; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD); //dinoume ta dedomena kapws pio asugxrona
    @(posedge clk) #1 data_i=8'd100; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD);
    @(posedge clk) #1 data_i=8'd10; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD);
    @(posedge clk) #1 data_i=8'd40; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD);
    @(posedge clk) #1 data_i=8'd250; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD);
    @(posedge clk) #1 data_i=8'd110; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD);
    @(posedge clk) #1 data_i=8'd35; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD);
    @(posedge clk) #1 data_i=8'd200; data_av_ai=1; @(posedge clk) #1 data_av_ai=0; #(`PERIOD);
    #(`PERIOD*200);  
      //elegxos tou average sto telos ths ekteleshs
    $display("task_average=%d, module_average=%d", result, avg_o); //elegxos tou average tou task me to avg_o
    case(result==avg_o)
        1:$display("Average from your unit is right(version 1 of task)");
        0:$display("Average from your unit is not right(version 1 of task)");
    endcase
    
    compare_res(avg_o,acc_result); //klhsh tou task sa function
    
$display ( "REGISTER TEST PASSED" );
$finish;
end  
endmodule