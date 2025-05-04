
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

parameter MAX_CYCLE= 1000;
parameter PAT_NUM  = 5900;
integer random_cycle;
integer latency;
integer i_pat;

logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  

integer i,j,k;

integer base_addr;

class ACT;
    randc Action act_id;
    constraint range{
        act_id inside{Index_Check,
                    Update,
                    Check_Valid_Date};
    }
endclass

class random_Date_no;
    randc Data_No date_no_id;
    constraint range{
        date_no_id inside{[1:255]};
    }
endclass

class Formula;
    randc Formula_Type formula_type_id;
    constraint range{
        formula_type_id inside{Formula_A,
                               Formula_B,
                               Formula_C,
                               Formula_D,
                               Formula_E,
                               Formula_F,
                               Formula_G,
                               Formula_H};
    }
endclass

class random_Mode;
    randc Mode mode_id;

    constraint range{
        mode_id inside{Insensitive,
                       Normal,
                       Sensitive};
    }
endclass


class random_date;
    randc Date date_id;

    constraint range {
        date_id.M inside {[1:12]};
        if (date_id.M == 1 || date_id.M == 3 || date_id.M == 5 || date_id.M == 7 || date_id.M == 8 || date_id.M == 10 || date_id.M == 12) {
            date_id.D inside {[1:31]};
        } else if (date_id.M == 4 || date_id.M == 6 || date_id.M == 9 || date_id.M == 11) {
            date_id.D inside {[1:30]};
        } else if (date_id.M == 2) {
            date_id.D inside {[1:28]};
        }
    }
endclass





class random_Index;
    randc Index index_id;
    constraint range{
        index_id inside{[0:4095]};
    }
endclass
//////////////////////////////////////////////////////////////////
//////////////////*********reg*********///////////////////////
/////////////////////////////////////////////////////////////////

logic [63:0] dram_r_data;
integer          counter;
ACT              act_input;
Formula          formula_type_in;
random_Mode      mode_input;
random_date      date_input;
random_Date_no   date_no_input;
random_Index     index_input;
Warn_Msg         Golden_warn;
logic            Golden_cmplete;


task Reset_task;
  begin
    inf.rst_n            = 1'b1;
    inf.data_no_valid    = 1'b0;
    inf.mode_valid       = 1'b0;
    inf.index_valid      = 1'b0;
    inf.sel_action_valid = 1'b0;
    inf.date_valid       = 1'b0;
    inf.formula_valid    = 1'b0;
    inf.D                =  'bx;

    force clk = 1'b0;

    #(10); 
    inf.rst_n = 1'b0; 
    #(15); 
    inf.rst_n = 1'b1; 


    if ((inf.complete !== 0) || (inf.out_valid !== 0) || (inf.warn_msg !== 0)) begin
      $display("\033[1;33m output signals must reset \033[0m");
      repeat(3) @(negedge clk);
      $finish;
    end

    #(10); 
    release clk;
  end
endtask



//////////////////////////////////////////////////////////////////
//////////////////*********initial task*********//////////////////
/////////////////////////////////////////////////////////////////
initial begin
    $readmemh(DRAM_p_r, golden_DRAM);
    act_input       = new();
    formula_type_in = new();
    mode_input      = new();
    date_input      = new();
    date_no_input   = new();
    index_input     = new();


    Reset_task;
    counter         = 0;
    i_pat           = 0;



    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        input_act_task;

        if (act_input.act_id == Index_Check) begin
            Index_input_task;    
            Index_cal_task;      
        end else if (act_input.act_id == Update) begin
            update_input;        
            update_input_cal;    
        end else if (act_input.act_id == Check_Valid_Date) begin
            check_input_task;    
            check_cal_task;      
        end

        wait_out_valid_task;
        check_ans_task;
        $display("\033[32m  PASS PATTERN NO.%4d\033[0m"   , i_pat);
    end
    PASS_task;
end






task input_act_task; begin
    inf.D = 'bx;
    random_cycle = $urandom_range(1,4);
    repeat(random_cycle) @(negedge clk);
    inf.sel_action_valid = 1'b1;

    if(i_pat < 2701)begin

        if ((i_pat % 9 == 0) || (i_pat % 9 == 1) || (i_pat % 9 == 6)) begin
            act_input.act_id = Index_Check;
        end else if ((i_pat % 9 == 2) || (i_pat % 9 == 3) || (i_pat % 9 == 8)) begin
            act_input.act_id = Update;
        end else if ((i_pat % 9 == 4) || (i_pat % 9 == 5) || (i_pat % 9 == 7)) begin
            act_input.act_id = Check_Valid_Date;
        end else begin
            act_input.act_id = Index_Check; 
        end

    end else begin
        act_input.act_id = Index_Check;
    end


    inf.D.d_act[0] = act_input.act_id;
    @(negedge clk);

    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
 

end endtask
//////////////////////////////////////////////////////////////////
//////////////////*********input task*********///////////////////
/////////////////////////////////////////////////////////////////

logic [4:0] MM,DD;
logic[11:0] A_INPUT,B_INPUT,C_INPUT,D_INPUT;
logic[11:0] M,D;

task Index_input_task; begin
    
    A_INPUT=0;
    B_INPUT=0;
    C_INPUT=0;
    D_INPUT=0;
    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
    inf.formula_valid = 1'b1;



        if (i_pat % 8 == 0) begin

            formula_type_in.formula_type_id = Formula_A;

        end else if (i_pat % 8 == 1) begin

            formula_type_in.formula_type_id = Formula_B;

        end else if (i_pat % 8 == 2) begin

            formula_type_in.formula_type_id = Formula_C;

        end else if (i_pat % 8 == 3) begin

            formula_type_in.formula_type_id = Formula_D;

        end else if (i_pat % 8 == 4) begin

            formula_type_in.formula_type_id = Formula_E;

        end else if (i_pat % 8 == 5) begin

            formula_type_in.formula_type_id = Formula_F;

        end else if (i_pat % 8 == 6) begin

            formula_type_in.formula_type_id = Formula_G;

        end else if (i_pat % 8 == 7) begin

            formula_type_in.formula_type_id = Formula_H;

        end else begin

            formula_type_in.formula_type_id = Formula_A;

        end



    inf.D.d_formula[0] = formula_type_in.formula_type_id;
    @(negedge clk);
    inf.formula_valid = 1'b0;
    inf.D = 'bx;
    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);

    inf.mode_valid = 1'b1;
    if (i_pat < 1351) begin
        case (i_pat % 9)
            0: begin
                mode_input.mode_id = Insensitive;
            end
            1: begin
                mode_input.mode_id = Normal;
            end
            6: begin
                mode_input.mode_id = Sensitive;
            end
            default: begin
                mode_input.mode_id = Insensitive; 
            end
        endcase


    end else begin

    if (i_pat % 24 >= 0 && i_pat % 24 <= 7) begin

        mode_input.mode_id = Insensitive;

    end else if (i_pat % 24 >= 8 && i_pat % 24 <= 15) begin

        mode_input.mode_id = Normal;

    end else if (i_pat % 24 >= 16 && i_pat % 24 <= 23) begin

        mode_input.mode_id = Sensitive;

    end else begin

        mode_input.mode_id = Insensitive;

    end

    end

    inf.D.d_mode[0] = mode_input.mode_id;
    @(negedge clk);

    inf.mode_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
    inf.date_valid = 1'b1;
    // if(i_pat < 51)begin
        date_input.date_id.M = 12;
        date_input.date_id.D = 31;
    // end
    // else begin
    //     date_input.date_id.M = 12;
    //     date_input.date_id.D = 31;
    // end

    MM=date_input.date_id.M;
    DD=date_input.date_id.D;

    inf.D.d_date[0] = date_input.date_id;
    @(negedge clk);

    inf.date_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

    inf.data_no_valid = 1'b1;
    // date_no_input.randomize();
    // if(i_pat < 150)begin
    //     date_no_input.date_no_id = 90;
    // end
    // else begin
        date_no_input.randomize();
    // end
    inf.D.d_data_no[0] = date_no_input.date_no_id;
    @(negedge clk);

    inf.data_no_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    // index_input.randomize();
    // if(i_pat < 500)begin
    //     index_input.index_id = 2000;
    // end
    // else begin
        index_input.index_id = 4000;
    // end

    A_INPUT=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);

    inf.index_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    // index_input.randomize();
    // if(i_pat < 500)begin
    //     index_input.index_id = 2000;
    // end
    // else begin
    //     index_input.index_id = 0;
    // end
    index_input.index_id = 4000;
    B_INPUT=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);

    inf.index_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    // index_input.randomize();
    // if(i_pat < 500)begin
    //     index_input.index_id = 2000;
    // end
    // else begin
    //     index_input.index_id = 0;
    // end
    index_input.index_id = 4000;
    C_INPUT=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);

    inf.index_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    // index_input.randomize();
    // if(i_pat < 500)begin
    //     index_input.index_id = 2000;
    // end
    // else begin
    //     index_input.index_id = 0;
    // end
    index_input.index_id = 4000;
    D_INPUT=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);

    inf.index_valid = 1'b0;
    inf.D = 'bx;
end endtask


logic [15:0] Result;    
logic [11:0] threshold;  
logic [11:0]  GA;
logic [11:0]  GB;
logic [11:0]  GC;
logic [11:0]  GD;
logic [35:0]  assend;
logic [11:0] min_1;      
logic [11:0] min_2;     
logic [11:0] min_3;      
logic [11:0] min_4;   
logic [11:0] golden_index_A;
logic [11:0] golden_index_B;
logic [11:0] golden_index_C;
logic [11:0] golden_index_D;
logic [11:0] golden_Date_M;
logic [11:0] golden_Date_D;

 
   



task Index_cal_task; begin
    golden_Date_D  = 0;
    golden_Date_M  = 0;
    golden_index_A = 0;
    golden_index_B = 0;
    golden_index_C = 0;
    golden_index_D = 0;



base_addr = 65536 + date_no_input.date_no_id * 8;


for (k = 0; k < 8; k = k + 1) begin
    dram_r_data[k*8 +: 8] = golden_DRAM[base_addr + k];
end


    golden_Date_D  = dram_r_data[7:0];

    golden_Date_M  = dram_r_data[39:32];




    golden_index_A = dram_r_data[63:52];
    GA = (golden_index_A > A_INPUT) ? 
         (golden_index_A - A_INPUT) : 
         (A_INPUT - golden_index_A);



    golden_index_B = dram_r_data[51:40];
    GB = (golden_index_B > B_INPUT) ? 
         (golden_index_B - B_INPUT) : 
         (B_INPUT - golden_index_B);



    golden_index_C = dram_r_data[31:20];
    GC = (golden_index_C > C_INPUT) ? 
         (golden_index_C - C_INPUT) : 
         (C_INPUT - golden_index_C);



    golden_index_D = dram_r_data[19:8];
    GD = (golden_index_D > D_INPUT) ? 
         (golden_index_D - D_INPUT) : 
         (D_INPUT - golden_index_D);


    threshold               = 0;

    case(formula_type_in.formula_type_id)
        Formula_A:begin
            Result = (golden_index_A + golden_index_B + golden_index_C + golden_index_D)/4;

            if (mode_input.mode_id == Insensitive) 
            begin

                threshold = 2047;

            end else if (mode_input.mode_id == Normal) 
            begin

                threshold = 1023;

            end else if (mode_input.mode_id == Sensitive) 
            begin

                threshold = 511;
                
            end

        end


        Formula_B:begin
            Result = max_minus_min(golden_index_A, golden_index_B, golden_index_C, golden_index_D);
            if (mode_input.mode_id == Insensitive) 
            begin
                threshold = 800;

            end else if (mode_input.mode_id == Normal) 
            begin
                threshold = 400;

            end else if (mode_input.mode_id == Sensitive) 
            begin
                threshold = 200;
            end

        end
        Formula_C:begin
            Result = find_min(golden_index_A, golden_index_B, golden_index_C, golden_index_D);
            if (mode_input.mode_id == Insensitive) 
            begin
                threshold = 2047;

            end else if (mode_input.mode_id == Normal) 
            begin
                threshold = 1023;

            end else if (mode_input.mode_id == Sensitive) 
            begin
                threshold = 511;
            end
        end
        Formula_D:begin
            Result = (golden_index_A>=2047) + (golden_index_B>=2047) + (golden_index_C>=2047) +(golden_index_D>=2047);
            if (mode_input.mode_id == Insensitive) 
            begin
                threshold = 3;

            end else if (mode_input.mode_id == Normal) 
            begin
                threshold = 2;

            end else if (mode_input.mode_id == Sensitive) 
            begin
                threshold = 1;

            end

        end
        Formula_E:begin
            Result = (golden_index_A>=A_INPUT) + (golden_index_B>=B_INPUT) + (golden_index_C>=C_INPUT) +(golden_index_D>=D_INPUT);
            if (mode_input.mode_id == Insensitive) 
            begin
                threshold = 3;

            end else if (mode_input.mode_id == Normal) 
            begin
                threshold = 2;

            end else if (mode_input.mode_id == Sensitive) 
            begin
                threshold = 1;
            end

        end
        Formula_F:begin
            Result = ((GA + GB + GC + GD) - find_max(GA, GB, GC, GD))/3;
            if (mode_input.mode_id == Insensitive) 
            begin
                threshold = 800;

            end else if (mode_input.mode_id == Normal) 
            begin
                threshold = 400;

            end else if (mode_input.mode_id == Sensitive) 
            begin
                threshold = 200;

            end

        end
        Formula_G:begin
            
            assend = find_min3(GA, GB, GC, GD);
            Result =  (assend[35:24]/2) + (assend[23:12]/4)  + (assend[11:0]/4);
            if (mode_input.mode_id == Insensitive) 
            begin

                threshold = 800;
            end else if (mode_input.mode_id == Normal) 
            begin

                threshold = 400;
            end else if (mode_input.mode_id == Sensitive) 
            begin

                threshold = 200;
            end

        end
        Formula_H:begin
             Result =  (GA + GB  + GC + GD)/4;
            if (mode_input.mode_id == Insensitive) 
            begin
                threshold = 800;

            end else if (mode_input.mode_id == Normal) 
            begin
                threshold = 400;

            end else if (mode_input.mode_id == Sensitive) 
            begin

                threshold = 200;
            end

        end
    endcase



Golden_warn = ((golden_Date_M > MM) || ((golden_Date_M == MM) && (golden_Date_D > DD))) ? Date_Warn :
              (Result >= threshold) ? Risk_Warn : No_Warn;

Golden_cmplete = (Golden_warn == No_Warn) ? 1 : 0;
    
end endtask


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

logic signed[11:0] pattern_A_S,pattern_B_S,pattern_C_S,pattern_D_S;

logic [11:0] DATE_NO;
task update_input; begin
    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
    inf.date_valid = 1'b1;
    date_input.randomize();;

    MM=date_input.date_id.M;
    DD=date_input.date_id.D;

    inf.D = date_input.date_id;
    @(negedge clk);

    inf.date_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.data_no_valid = 1'b1;
    date_no_input.randomize();;


    DATE_NO = date_no_input.date_no_id;
    inf.D = date_no_input.date_no_id;
    @(negedge clk);

    inf.data_no_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);


//index_input
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    index_input.randomize();
    pattern_A_S=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    index_input.randomize();
    pattern_B_S=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    index_input.randomize();
    pattern_C_S=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;
    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    inf.index_valid = 1'b1;
    index_input.randomize();
    index_input.index_id=2030;
    pattern_D_S=index_input.index_id;
    inf.D.d_index[0] = index_input.index_id;
    @(negedge clk);
    inf.index_valid = 1'b0;
    inf.D = 'bx;


end endtask






logic signed [12:0] golden_index_A_S;
logic signed [13:0] ans_A_S;  
logic signed [12:0] golden_index_B_S;
logic signed [13:0] ans_B_S;  
logic signed [12:0] golden_index_C_S;
logic signed [13:0] ans_C_S;  
logic signed [12:0] golden_index_D_S;
logic signed [13:0] ans_D_S;  

task update_input_cal; begin
    base_addr = 65536 + DATE_NO * 8;


    for (j = 0; j < 8; j = j + 1) begin
        dram_r_data[j*8 +: 8] = golden_DRAM[base_addr + j];
    end


    golden_Date_D  = dram_r_data[7:0];
    golden_Date_M  = dram_r_data[39:32];
    golden_index_A_S = dram_r_data[63:52];
    golden_index_B_S = dram_r_data[51:40];
    golden_index_C_S = dram_r_data[31:20];
    golden_index_D_S = dram_r_data[19:8];


    ans_A_S = golden_index_A_S + pattern_A_S;
    ans_B_S = golden_index_B_S + pattern_B_S;
    ans_C_S = golden_index_C_S + pattern_C_S;
    ans_D_S = golden_index_D_S + pattern_D_S;




    if(ans_A_S>4095 || ans_B_S>4095 || ans_C_S>4095 || ans_D_S>4095   || ans_A_S<0|| ans_B_S<0 || ans_C_S<0 || ans_D_S<0)begin
        Golden_warn = Data_Warn;
        Golden_cmplete = 0;
    end else begin
        Golden_warn = No_Warn;
        Golden_cmplete = 1;
    end

    


{golden_DRAM[base_addr + 7], golden_DRAM[base_addr + 6][7:4]} = clamp_to_12bit(ans_A_S);
{golden_DRAM[base_addr + 6][3:0], golden_DRAM[base_addr + 5]} = clamp_to_12bit(ans_B_S);

{golden_DRAM[base_addr + 3], golden_DRAM[base_addr + 2][7:4]} = clamp_to_12bit(ans_C_S);
{golden_DRAM[base_addr + 2][3:0], golden_DRAM[base_addr + 1]} = clamp_to_12bit(ans_D_S);

golden_DRAM[base_addr + 4] = MM;
golden_DRAM[base_addr + 0] = DD;

end endtask






////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task check_input_task; begin
    
    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);
    inf.date_valid = 1'b1;
    date_input.date_id.M=1;
    date_input.date_id.D=1;
    inf.D = date_input.date_id;
    @(negedge clk);
    MM=date_input.date_id.M;
    DD=date_input.date_id.D;
    inf.date_valid = 1'b0;
    inf.D = 'bx;

    random_cycle = $urandom_range(0,3);
    repeat(random_cycle) @(negedge clk);



    inf.data_no_valid = 1'b1;
    date_no_input.randomize();
    DATE_NO = date_no_input.date_no_id;
    inf.D = date_no_input.date_no_id;
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;

end endtask


task check_cal_task; begin

    base_addr = 65536 + DATE_NO * 8;

    for (i = 0; i < 8; i = i + 1) begin
        dram_r_data[i*8 +: 8] = golden_DRAM[base_addr + i];
    end

    golden_Date_D  = dram_r_data[7:0];
    golden_Date_M  = dram_r_data[39:32];
    golden_index_A = dram_r_data[63:52];
    golden_index_B = dram_r_data[51:40];
    golden_index_C = dram_r_data[31:20];
    golden_index_D = dram_r_data[19:8];


    Golden_warn = No_Warn;
    Golden_cmplete = 1;


    if (golden_Date_M > MM) begin
        Golden_warn = Date_Warn;
        Golden_cmplete = 0;
    end else if ((golden_Date_M == MM) && (golden_Date_D > DD)) begin
        Golden_warn = Date_Warn;
        Golden_cmplete = 0;
    end



end endtask




task check_ans_task; begin
    if((inf.warn_msg !== Golden_warn)  ||   (inf.complete !== Golden_cmplete))begin
        $display("Pat No. %d  err is Wrong Answer",i_pat);
        $finish;
    end

end endtask




task wait_out_valid_task; begin
    latency = 0;

    while(inf.out_valid !== 1'b1)
    begin
        if(latency == MAX_CYCLE)
        begin
            $display("Pat No. %d  latency is over 1000 cycle",i_pat);
            $finish;
        end

        latency = latency + 1;
        @(negedge clk);
    end
end endtask



function [13:0] clamp_to_12bit(input signed [15:0] value);
    begin
        if (value > 4095)
            clamp_to_12bit = 4095;
        else if (value < 0)
            clamp_to_12bit = 0;
        else
            clamp_to_12bit = value[11:0];
    end
endfunction  


task PASS_task;
begin
    $display("***********************************************");
    $display("*              Congratulations!               *");
    $display("*   Your design has passed all test cases!    *");
    $display("***********************************************");
    $finish;
end
endtask





function [11:0] max_minus_min;
    input [11:0] a, b, c, d; 
    reg [11:0] max_value, min_value;

    begin

        max_value = a; 
        if (b > max_value) max_value = b;
        if (c > max_value) max_value = c;
        if (d > max_value) max_value = d;

        min_value = a; 
        if (b < min_value) min_value = b;
        if (c < min_value) min_value = c;
        if (d < min_value) min_value = d;


        max_minus_min = max_value - min_value;
    end
endfunction





function [11:0] find_min;
    input [11:0] a, b, c, d; 
    reg [11:0] min_value;

    begin
        min_value = a; 
        if (b < min_value) min_value = b;
        if (c < min_value) min_value = c;
        if (d < min_value) min_value = d;

        find_min = min_value;
    end
endfunction





function [11:0] find_max;
    input [11:0] a, b, c, d; 
    reg [11:0] max_value;

    begin
        
        max_value = a; 
        if (b > max_value) max_value = b;
        if (c > max_value) max_value = c;
        if (d > max_value) max_value = d;

        
        find_max = max_value;
    end
endfunction




function logic [35:0] find_min3(
        input logic [11:0] A, 
        input logic [11:0] B, 
        input logic [11:0] C, 
        input logic [11:0] D  
    );
        logic [11:0] temp [3:0];  
        logic [11:0] swap;         
        integer i, j;

        begin

            temp[0] = A;
            temp[1] = B;
            temp[2] = C;
            temp[3] = D;

            for (i = 0; i < 3; i++) begin
                for (j = 0; j < 3 - i; j++) begin
                    if (temp[j] > temp[j + 1]) begin
                        swap = temp[j];
                        temp[j] = temp[j + 1];
                        temp[j + 1] = swap;
                    end
                end
            end

            find_min3 = {temp[0], temp[1], temp[2]};
        end
    endfunction



  
endprogram