/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2024 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Apr-2024)
Author : Jui-Huang Tsai (erictsai.ee12@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PAT_NUM = 3600;
integer total_latency, latency;
integer i_pat, rand_t;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box

//================================================================
// class random
//================================================================
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Make_drink,Supply,Check_Valid_Date};
    }
endclass
class random_bev_type;
    randc Bev_Type bev_type_id;
    constraint range{
        bev_type_id inside{Black_Tea,Milk_Tea,Extra_Milk_Tea,Green_Tea,Green_Milk_Tea,Pineapple_Juice,Super_Pineapple_Tea,Super_Pineapple_Milk_Tea};
    }
endclass
class random_bev_size;
    randc Bev_Size bev_size_id;
    constraint range{
        bev_size_id inside{L,M,S};
    }
endclass
class random_date;
    randc Date date_id;
    constraint range{
        date_id.M inside{[1:12]};
        if(date_id.M == 2) date_id.D inside{[1:28]};
        else if(date_id.M == 1 || date_id.M == 3 || date_id.M == 5 || date_id.M == 7 || date_id.M == 8 || date_id.M == 10 || date_id.M == 12) date_id.D inside{[1:31]};
        else if(date_id.M == 4 || date_id.M == 6 || date_id.M == 9 || date_id.M == 11) date_id.D inside{[1:30]};
    }
endclass
class random_box_no;
    randc Barrel_No box_no_id;
    constraint range{
        box_no_id inside{[1:255]};
    }
endclass
class random_box_sup;
    randc ING box_sup_id;
    constraint range{
        box_sup_id inside{[0:4095]};
    }
endclass
//================================================================
// initial
//================================================================
random_act act_in;
random_bev_type type_in;
random_bev_size size_in;
random_date date_in;
random_box_no box_no_in;
random_box_sup box_sup_in;

logic [63:0] dram_r_data;

logic [7:0]  golden_ex_date;
logic [11:0] golden_pineapple_juice_vol;
logic [11:0] golden_milk_vol;
logic [7:0]  golden_ex_month;
logic [11:0] golden_green_tea_vol;
logic [11:0] golden_black_tea_vol;

logic [9:0]  consume_pineapple_juice;
logic [9:0]  consume_milk;
logic [9:0]  consume_green_tea;
logic [9:0]  consume_black_tea;

logic [11:0] add_pineapple_juice;
logic [11:0] add_milk;
logic [11:0] add_green_tea;
logic [11:0] add_black_tea;

logic [12:0] add_out_pineapple_juice;
logic [12:0] add_out_milk;
logic [12:0] add_out_green_tea;
logic [12:0] add_out_black_tea;

Error_Msg golden_err;
logic golden_complete;

integer count;

initial begin
    $readmemh(DRAM_p_r, golden_DRAM);
    act_in = new();
    type_in = new();
    size_in = new();
    date_in = new();
    box_no_in = new();
    box_sup_in = new();
    reset_signal_task;

    count = 0;

    i_pat = 0;
    total_latency = 0;
    for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        input_act_task;
        case(act_in.act_id)
            Make_drink:begin
                make_input_task;
                make_cal_task;
            end
            Supply:begin
                sup_input_task;
                sup_cal_task;
            end
            Check_Valid_Date:begin
                check_input_task;
                check_cal_task;
            end
        endcase
        wait_out_valid_task;
        check_ans_task;
        total_latency = total_latency + latency;
        $display("PASS PATTERN NO.%4d", i_pat);
    end

    YOU_PASS_task;
end
//================================================================
// task
//================================================================
task reset_signal_task; begin
    inf.rst_n = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.type_valid = 1'b0;
    inf.size_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.box_no_valid = 1'b0;
    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;

    force clk = 1'b0;
    #(10); inf.rst_n = 0;
    #(10); inf.rst_n = 1;
    if((inf.out_valid !== 0)||(inf.err_msg !== 0)||(inf.complete !== 0))begin
        $display("///////////////////////////////////////");
        $display("All out signal should be reset after the reset is asserted");
        $display("///////////////////////////////////////");
        repeat(3) @(negedge clk);
        $finish;
    end
    #(15); release clk;
end endtask

task input_act_task; begin
    // rand_t = $urandom_range(1,4);
    repeat(1) @(negedge clk);
    inf.sel_action_valid = 1'b1;
    if(i_pat < 1800)begin
        case(i_pat % 9)//for spec 5
            0:act_in.act_id = Make_drink;
            1:act_in.act_id = Make_drink;// make to make
            2:act_in.act_id = Supply;//make to sup
            3:act_in.act_id = Supply;//sup to sup
            4:act_in.act_id = Check_Valid_Date;//sup to check
            5:act_in.act_id = Check_Valid_Date;//check to check
            6:act_in.act_id = Make_drink;//check to sup
            7:act_in.act_id = Check_Valid_Date;//sup to make
            8:act_in.act_id = Supply;//make to check
        endcase
    end
    else begin//for spec 3
        act_in.act_id = Make_drink;
    end
    inf.D = act_in.act_id;
    @(negedge clk);

    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
end endtask

task make_input_task; begin
    //================================================================
    // type in
    //================================================================
    inf.type_valid = 1'b1;
        case(i_pat % 8)
            0:type_in.bev_type_id = Black_Tea      	        ;
            1:type_in.bev_type_id = Milk_Tea	            ;
            2:type_in.bev_type_id = Extra_Milk_Tea          ;
            3:type_in.bev_type_id = Green_Tea 	            ;
            4:type_in.bev_type_id = Green_Milk_Tea          ;
            5:type_in.bev_type_id = Pineapple_Juice         ;
            6:type_in.bev_type_id = Super_Pineapple_Tea     ;
            7:type_in.bev_type_id = Super_Pineapple_Milk_Tea;
        endcase

    inf.D.d_type[0] = type_in.bev_type_id;
    @(negedge clk);

    inf.type_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // size in for spec 3
    //================================================================
    inf.size_valid = 1'b1;
    if(i_pat < 1800)begin
        case(i_pat % 9)//which is make drink
            0:size_in.bev_size_id = L;
            1:size_in.bev_size_id = M;
            6:size_in.bev_size_id = S;
        endcase
    end
    else begin
        case(i_pat % 24)
            0,  1, 2, 3, 4, 5, 6, 7: size_in.bev_size_id = L;
            8,  9,10,11,12,13,14,15: size_in.bev_size_id = M;
            16,17,18,19,20,21,22,23: size_in.bev_size_id = S;
        endcase
    end
    inf.D.d_size[0] = size_in.bev_size_id;
    @(negedge clk);

    inf.size_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // date in
    //================================================================
    inf.date_valid = 1'b1;
    // date_in.randomize();
    // inf.D.d_date[0] = date_in.date_id;
    date_in.date_id.M = 12;
    date_in.date_id.D = 31;
    inf.D.d_date[0] = date_in.date_id;
    @(negedge clk);

    inf.date_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // box no in
    //================================================================
    inf.box_no_valid = 1'b1;
    if(count < 20)begin
        box_no_in.box_no_id = 0;
        count = count + 1;
    end
    else begin
        box_no_in.randomize();
    end
    inf.D.d_box_no[0] = box_no_in.box_no_id;
    @(negedge clk);

    inf.box_no_valid = 1'b0;
    inf.D = 'bx;
end endtask

task sup_input_task; begin
    //================================================================
    // date in
    //================================================================
    inf.date_valid = 1'b1;
    date_in.randomize();
    inf.D = date_in.date_id;
    @(negedge clk);

    inf.date_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // box no in
    //================================================================
    inf.box_no_valid = 1'b1;
    box_no_in.randomize();
    inf.D = box_no_in.box_no_id;
    @(negedge clk);

    inf.box_no_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // sup black in
    //================================================================
    inf.box_sup_valid = 1'b1;
    box_sup_in.randomize();
    add_black_tea = box_sup_in.box_sup_id;
    inf.D = add_black_tea;
    @(negedge clk);

    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // sup green in
    //================================================================
    inf.box_sup_valid = 1'b1;
    box_sup_in.randomize();
    add_green_tea = box_sup_in.box_sup_id;
    inf.D = add_green_tea;
    @(negedge clk);

    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // sup milk in
    //================================================================
    inf.box_sup_valid = 1'b1;
    box_sup_in.randomize();
    add_milk = box_sup_in.box_sup_id;
    inf.D = add_milk;
    @(negedge clk);

    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // sup pine in
    //================================================================
    inf.box_sup_valid = 1'b1;
    box_sup_in.randomize();
    add_pineapple_juice = box_sup_in.box_sup_id;
    inf.D = add_pineapple_juice;
    @(negedge clk);

    inf.box_sup_valid = 1'b0;
    inf.D = 'bx;
end endtask

task check_input_task; begin
    //================================================================
    // date in
    //================================================================
    inf.date_valid = 1'b1;
    date_in.randomize();
    inf.D = date_in.date_id;
    @(negedge clk);

    inf.date_valid = 1'b0;
    inf.D = 'bx;

    // rand_t = $urandom_range(0,3);
    // repeat(rand_t) @(negedge clk);
    //================================================================
    // box no in
    //================================================================
    inf.box_no_valid = 1'b1;
    box_no_in.randomize();
    inf.D = box_no_in.box_no_id;
    @(negedge clk);

    inf.box_no_valid = 1'b0;
    inf.D = 'bx;


end endtask

task make_cal_task; begin
    dram_r_data = {golden_DRAM[65536 + box_no_in.box_no_id*8 + 7],golden_DRAM[65536 + box_no_in.box_no_id*8 + 6],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 5],golden_DRAM[65536 + box_no_in.box_no_id*8 + 4],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 3],golden_DRAM[65536 + box_no_in.box_no_id*8 + 2],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 1],golden_DRAM[65536 + box_no_in.box_no_id*8 + 0]
                  };
    golden_ex_date = dram_r_data[7:0];
    golden_pineapple_juice_vol = dram_r_data[19:8];
    golden_milk_vol = dram_r_data[31:20];
    golden_ex_month = dram_r_data[39:32];
    golden_green_tea_vol = dram_r_data[51:40];
    golden_black_tea_vol = dram_r_data[63:52];
    consume_pineapple_juice = 0;
    consume_milk            = 0;
    consume_green_tea       = 0;
    consume_black_tea       = 0;
    case(type_in.bev_type_id)
        Black_Tea:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_black_tea = 960;
                end
                M:begin
                    consume_black_tea = 720;
                end
                S:begin
                    consume_black_tea = 480;
                end
            endcase
        end
        Milk_Tea:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_milk = 240;
                    consume_black_tea = 720;
                end
                M:begin
                    consume_milk = 180;
                    consume_black_tea = 540;
                end
                S:begin
                    consume_milk = 120;
                    consume_black_tea = 360;
                end
            endcase
        end
        Extra_Milk_Tea:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_milk = 480;
                    consume_black_tea = 480;
                end
                M:begin
                    consume_milk = 360;
                    consume_black_tea = 360;
                end
                S:begin
                    consume_milk = 240;
                    consume_black_tea = 240;
                end
            endcase
        end
        Green_Tea:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_green_tea = 960;
                end
                M:begin
                    consume_green_tea = 720;
                end
                S:begin
                    consume_green_tea = 480;
                end
            endcase
        end
        Green_Milk_Tea:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_milk = 480;
                    consume_green_tea = 480;
                end
                M:begin
                    consume_milk = 360;
                    consume_green_tea = 360;
                end
                S:begin
                    consume_milk = 240;
                    consume_green_tea = 240;
                end
            endcase
        end
        Pineapple_Juice:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_pineapple_juice = 960;
                end
                M:begin
                    consume_pineapple_juice = 720;
                end
                S:begin
                    consume_pineapple_juice = 480;
                end
            endcase
        end
        Super_Pineapple_Tea:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_pineapple_juice = 480;
                    consume_black_tea = 480;
                end
                M:begin
                    consume_pineapple_juice = 360;
                    consume_black_tea = 360;
                end
                S:begin
                    consume_pineapple_juice = 240;
                    consume_black_tea = 240;
                end
            endcase
        end
        Super_Pineapple_Milk_Tea:begin
            case(size_in.bev_size_id)
                L:begin
                    consume_pineapple_juice = 240;
                    consume_milk = 240;
                    consume_black_tea = 480;
                end
                M:begin
                    consume_pineapple_juice = 180;
                    consume_milk = 180;
                    consume_black_tea = 360;
                end
                S:begin
                    consume_pineapple_juice = 120;
                    consume_milk = 120;
                    consume_black_tea = 240;
                end
            endcase
        end
    endcase
    if((date_in.date_id.M > golden_ex_month) || ((date_in.date_id.M == golden_ex_month)&&(date_in.date_id.D > golden_ex_date)))begin
        golden_err = No_Exp;
        golden_complete = 0;

    end
    else if((consume_pineapple_juice>golden_pineapple_juice_vol) || (consume_milk>golden_milk_vol) || (consume_green_tea>golden_green_tea_vol) || (consume_black_tea>golden_black_tea_vol))begin
        golden_err = No_Ing;
        golden_complete = 0;
    end
    else begin
        golden_err = No_Err;
        golden_complete = 1;
    end
    if(golden_err == No_Err)begin
        {golden_DRAM[65536 + box_no_in.box_no_id*8 + 7],golden_DRAM[65536 + box_no_in.box_no_id*8 + 6][7:4]} = golden_black_tea_vol-consume_black_tea;
        {golden_DRAM[65536 + box_no_in.box_no_id*8 + 6][3:0],golden_DRAM[65536 + box_no_in.box_no_id*8 + 5]} = golden_green_tea_vol-consume_green_tea;
        {golden_DRAM[65536 + box_no_in.box_no_id*8 + 3],golden_DRAM[65536 + box_no_in.box_no_id*8 + 2][7:4]} = golden_milk_vol-consume_milk;
        {golden_DRAM[65536 + box_no_in.box_no_id*8 + 2][3:0],golden_DRAM[65536 + box_no_in.box_no_id*8 + 1]} = golden_pineapple_juice_vol-consume_pineapple_juice;
    end
end endtask

task sup_cal_task; begin
    dram_r_data = {golden_DRAM[65536 + box_no_in.box_no_id*8 + 7],golden_DRAM[65536 + box_no_in.box_no_id*8 + 6],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 5],golden_DRAM[65536 + box_no_in.box_no_id*8 + 4],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 3],golden_DRAM[65536 + box_no_in.box_no_id*8 + 2],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 1],golden_DRAM[65536 + box_no_in.box_no_id*8 + 0]
                  };
    golden_ex_date = dram_r_data[7:0];
    golden_pineapple_juice_vol = dram_r_data[19:8];
    golden_milk_vol = dram_r_data[31:20];
    golden_ex_month = dram_r_data[39:32];
    golden_green_tea_vol = dram_r_data[51:40];
    golden_black_tea_vol = dram_r_data[63:52];
    add_out_pineapple_juice = 0;
    add_out_milk            = 0;
    add_out_green_tea       = 0;
    add_out_black_tea       = 0;
    add_out_pineapple_juice = add_pineapple_juice + golden_pineapple_juice_vol;
    add_out_milk = add_milk + golden_milk_vol;
    add_out_green_tea = add_green_tea + golden_green_tea_vol;
    add_out_black_tea = add_black_tea + golden_black_tea_vol;
    if(add_out_pineapple_juice>4095 || add_out_milk>4095 || add_out_green_tea>4095 || add_out_black_tea>4095)begin
        golden_err = Ing_OF;
        golden_complete = 0;
    end
    else begin
        golden_err = No_Err;
        golden_complete = 1;
    end
    {golden_DRAM[65536 + box_no_in.box_no_id*8 + 7],golden_DRAM[65536 + box_no_in.box_no_id*8 + 6][7:4]} = (add_out_black_tea>4095)? 4095:add_out_black_tea;
    {golden_DRAM[65536 + box_no_in.box_no_id*8 + 6][3:0],golden_DRAM[65536 + box_no_in.box_no_id*8 + 5]} = (add_out_green_tea>4095)? 4095:add_out_green_tea;
    {golden_DRAM[65536 + box_no_in.box_no_id*8 + 3],golden_DRAM[65536 + box_no_in.box_no_id*8 + 2][7:4]} = (add_out_milk>4095)? 4095:add_out_milk;
    {golden_DRAM[65536 + box_no_in.box_no_id*8 + 2][3:0],golden_DRAM[65536 + box_no_in.box_no_id*8 + 1]} = (add_out_pineapple_juice>4095)? 4095:add_out_pineapple_juice;
    golden_DRAM[65536 + box_no_in.box_no_id*8 + 4] = date_in.date_id.M;
    golden_DRAM[65536 + box_no_in.box_no_id*8 + 0] = date_in.date_id.D;
end endtask

task check_cal_task; begin
    dram_r_data = {golden_DRAM[65536 + box_no_in.box_no_id*8 + 7],golden_DRAM[65536 + box_no_in.box_no_id*8 + 6],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 5],golden_DRAM[65536 + box_no_in.box_no_id*8 + 4],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 3],golden_DRAM[65536 + box_no_in.box_no_id*8 + 2],
                   golden_DRAM[65536 + box_no_in.box_no_id*8 + 1],golden_DRAM[65536 + box_no_in.box_no_id*8 + 0]
                  };
    golden_ex_date = dram_r_data[7:0];
    golden_pineapple_juice_vol = dram_r_data[19:8];
    golden_milk_vol = dram_r_data[31:20];
    golden_ex_month = dram_r_data[39:32];
    golden_green_tea_vol = dram_r_data[51:40];
    golden_black_tea_vol = dram_r_data[63:52];
    if((date_in.date_id.M > golden_ex_month) || ((date_in.date_id.M == golden_ex_month)&&(date_in.date_id.D > golden_ex_date)))begin
        golden_err = No_Exp;
        golden_complete = 0;
    end
    else begin
        golden_err = No_Err;
        golden_complete = 1;
    end
end endtask

task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid !== 1'b1)begin
        if(latency == 1000)begin
            $display("///////////////////////////////////////");
            $display("Pat No. %d  latency is over 1000 cycle",i_pat);
            $display("///////////////////////////////////////");
            $finish;
        end
        latency = latency + 1;
        @(negedge clk);
    end
end endtask

task check_ans_task; begin
    if(inf.err_msg !== golden_err)begin
        $display("///////////////////////////////////////");
        $display("Pat No. %d  err is Wrong Answer",i_pat);
        $display("///////////////////////////////////////");
        $display("Golden err is %d",golden_err);
        $display("Your err is %d",inf.err_msg);
        $display("mode is %d",act_in.act_id);
        $finish;
    end
    else begin
        if(inf.complete !== golden_complete)begin
            $display("///////////////////////////////////////");
            $display("Pat No. %d  complete is Wrong Answer",i_pat);
            $display("///////////////////////////////////////");
            $display("Golden complete is %d",golden_complete);
            $display("Your complete is %d",inf.complete);
            $display("mode is %d",act_in.act_id);
            $finish;
        end
    end
end endtask

//////////////////////////////////


//////////////////////////////////////////////////////////////////////


task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask
endprogram
