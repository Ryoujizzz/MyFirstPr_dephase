`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/05 13:38:27
// Design Name: 
// Module Name: NewdephaseV1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module NewdephaseV1(
    input                               sys_clk                    ,
    input                               sys_rstn                   ,
    input                               GRI_DATA_Valid             ,
    input              [  15:0]         Cor_Peak_Index             ,
    input                               Cor_Peak_Valid             ,
    input                               GRI_MXY                    ,// 0 为主台  1为副台
  //input              [   1:0]         GRI_Cycle                  ,//GRI A/B周期标识 A：00 B：11     input                               Cor_Peak_Valid             
    output             [   1:0]         phase_out                  ,
    output                              phase_valid                 
 );

    localparam                              static_num = 10             ;//5个GRI更新一次相位结果

//检测上升沿 （1）启动状态机 （2）GRI计数
    reg                                     GRI_DATA_Valid_d1          ;
    reg                                     GRI_DATA_Valid_d2          ;
    wire                                    GRI_START                  ;
    always @(posedge sys_clk) begin
        if(!sys_rstn) begin
            GRI_DATA_Valid_d1 <= 'd0 ;
            GRI_DATA_Valid_d2 <= 'd0 ;
        end
        else begin
            GRI_DATA_Valid_d1 <= GRI_DATA_Valid    ;
            GRI_DATA_Valid_d2 <= GRI_DATA_Valid_d1 ;
        end
    end
    assign  GRI_START = GRI_DATA_Valid_d1 & (~GRI_DATA_Valid_d2);


    (*mark_debug="true"*)reg                    [   7:0]         state                      ;
    (*mark_debug="true"*)reg      signed        [  15:0]         peak_std                   ; //记录第一个峰值基准
    (*mark_debug="true"*)reg      signed        [  15:0]         peak_sum                   ;
    (*mark_debug="true"*)reg                                     peak_sum_valid             ;

    always @(posedge sys_clk) begin
        if(!sys_rstn) begin
            state          <= 'd0 ;
            peak_std       <= 'd0 ;
            peak_sum       <= 'd0 ;
            peak_sum_valid <= 'd0 ;
        end
        else begin
            case (state)
                'd0 : begin
                    peak_sum_valid <= 'd0 ;
                    if(GRI_START) begin
                        state <= 'd1      ;
                    end
                    else begin
                        state <= state    ;
                    end
                end
                'd1 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd2            ;
                        peak_std <= Cor_Peak_Index ;                    
                    end
                    else begin
                        state    <= state    ;
                        peak_std <= peak_std ;
                    end
                end
                'd2 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd3                                           ; 
                        peak_sum <= Cor_Peak_Index  - 1000 - peak_std             ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end
                end
                'd3 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd4                                           ; 
                        peak_sum <= peak_sum + Cor_Peak_Index  - 2000 - peak_std  ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end                
                end
                'd4 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd5                                           ; 
                        peak_sum <= peak_sum + Cor_Peak_Index  - 3000 - peak_std  ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end                
                end      
                'd5 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd6                                           ; 
                        peak_sum <= peak_sum + Cor_Peak_Index  - 4000 - peak_std  ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end                
                end      
                'd6 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd7                                           ; 
                        peak_sum <= peak_sum + Cor_Peak_Index  - 5000 - peak_std  ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end                
                end  
                'd7 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd8                                           ; 
                        peak_sum <= peak_sum + Cor_Peak_Index  - 6000 - peak_std  ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end                
                end      
                'd8 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= (GRI_MXY)?'d10:'d9                            ; 
                        peak_sum <= peak_sum + Cor_Peak_Index  - 7000 - peak_std  ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end                
                end 
                'd9 : begin
                    if(Cor_Peak_Valid) begin
                        state    <= 'd10                                          ; 
                        peak_sum <= peak_sum + Cor_Peak_Index  - 9000 - peak_std  ;
                    end
                    else begin
                        state    <= state    ;
                        peak_sum <= peak_sum ;
                    end                
                end    
                'd10 : begin
                    peak_sum_valid <= 1'd1 ;
                    state          <=  'd0 ;
                end                                               
            endcase
        end
    end

    (*mark_debug="true"*)reg                    [   1:0]         phase_out_r                ;
    (*mark_debug="true"*)reg                                     phase_valid_r              ;

    (*mark_debug="true"*)reg                    [   7:0]         pos_result_cnt             ;
    (*mark_debug="true"*)reg                    [   7:0]         neg_result_cnt             ;


    (*mark_debug="true"*)reg                    [   7:0]         phase_sta                  ;
    //(*mark_debug="true"*)reg      signed        [  15:0]         peak_sta_sum               ;
    (*mark_debug="true"*)reg                    [   7:0]         gri_cnt                    ;

    always @(posedge sys_clk) begin
        if(!sys_rstn) begin
            gri_cnt        <= 'd0  ;
            phase_sta      <= 'd0  ;
            phase_out_r    <= 'b10 ;
            phase_valid_r  <= 'd0  ;
            pos_result_cnt <= 'd0  ;
            neg_result_cnt <= 'd0  ;
        end
        else begin
            case (phase_sta) 
                'd0 : begin
                    phase_valid_r    <= 1'd0                        ;
                    if(peak_sum_valid) begin
                        if(peak_sum <= 16'd23 && peak_sum >= 16'd12 ) begin
                            pos_result_cnt <= pos_result_cnt + 1'd1 ;
                        end
                        else if(peak_sum <= -16'd12 && peak_sum >= -16'd23 ) begin
                            neg_result_cnt <= neg_result_cnt + 1'd1 ;
                        end
                        else begin
                            pos_result_cnt <= pos_result_cnt ;
                            neg_result_cnt <= neg_result_cnt ;
                        end
                        gri_cnt      <= gri_cnt + 1'd1          ;
                    end
                    else begin
                        phase_valid_r <= (gri_cnt == static_num -1)?'d1 : 'd0       ;
                        gri_cnt       <= (gri_cnt == static_num -1)?'d0 : gri_cnt   ;
                        phase_sta     <= (gri_cnt == static_num -1)?'d1 : phase_sta ;
                    end
                end
                'd1 : begin
                    neg_result_cnt  <= 'd0   ;
                    pos_result_cnt  <= 'd0   ;
                    phase_valid_r   <= 1'd0  ;
                    phase_sta       <= 'd0   ;
                    if( neg_result_cnt >= pos_result_cnt ) begin
                        phase_out_r <= 2'b01 ;
                    end
                    else begin
                        phase_out_r <= 2'b10 ;
                    end
                end
                
            endcase
        end
    end

assign  phase_out   = phase_out_r   ;
assign  phase_valid = phase_valid_r ;
endmodule