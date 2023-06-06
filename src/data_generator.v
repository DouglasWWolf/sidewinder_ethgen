//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 04-Oct-22  DWW  1000  Initial creation
//====================================================================================

module data_generator
(
    input clk, resetn,

    input[63:0] packet_count,
    input       start,

    //===============  AXI Stream interface for outputting data ================
    output [511:0] AXIS_TX_TDATA,
    output reg     AXIS_TX_TVALID,
    output         AXIS_TX_TLAST,
    input          AXIS_TX_TREADY
    //==========================================================================
 );




reg[1:0]  fsm_state;
reg[63:0] latched;
reg[63:0] packet_num;
reg[63:0] counter;
reg[63:0] packets_remaining;
reg       restart;

wire eop = (counter[1:0] == 2'b11);

assign AXIS_TX_TDATA[0   +: 64] = counter;
assign AXIS_TX_TDATA[64  +: 64] = packet_num;
assign AXIS_TX_TDATA[384 +: 64] = ~packet_num;
assign AXIS_TX_TDATA[448 +: 64] = ~counter;
assign AXIS_TX_TLAST            = eop;


always @(posedge clk) begin


    if (resetn == 0) begin
        counter        <= 0;
        packet_num     <= 0;
        AXIS_TX_TVALID <= 0;
        fsm_state      <= 0;
        restart        <= 0;
    end else begin    

        if (start) begin
            latched <= packet_count;
            restart <= 1;
        end


        case(fsm_state)

        0:  if (restart) begin
                restart           <= 0;
                packet_num        <= 0;
                counter           <= 0;
                packets_remaining <= latched;
                if (latched) begin
                    fsm_state      <= 1;
                    AXIS_TX_TVALID <= 1;
                end
            end 

        1:  if (AXIS_TX_TVALID & AXIS_TX_TREADY) begin
         
                if (eop) begin
                    if (restart || packets_remaining == 1) begin
                        AXIS_TX_TVALID <= 0;
                        fsm_state      <= 0;
                    end
                    packets_remaining  <= packets_remaining - 1;
                    packet_num         <= packet_num        + 1;
                end
                
                counter <= counter + 1;
            end
         
        endcase

    end


end


endmodule






