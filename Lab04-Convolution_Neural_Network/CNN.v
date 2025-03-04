//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;
/////////////////////////////FSM
reg [4:0] current_state, next_state;
parameter IDLE = 0;
parameter COMP = 1;
parameter DONE = 2;
reg [7:0]counter;
// reg done_flag;
/////////////////////////////INPUT
integer i;

reg [1:0] opt_reg;

reg [inst_sig_width+inst_exp_width:0] image_reg [0:15];

reg [inst_sig_width+inst_exp_width:0] kernel_reg_1 [0:8];
reg [inst_sig_width+inst_exp_width:0] kernel_reg_2 [0:8];
reg [inst_sig_width+inst_exp_width:0] kernel_reg_3 [0:8];

reg [inst_sig_width+inst_exp_width:0] weight_reg [0:3];
//CONV
reg [1:0] ofm_row, ofm_col;
reg [inst_sig_width+inst_exp_width:0] input_feature_map [0:35];
reg [inst_sig_width+inst_exp_width:0] dp3_in_1 [0:2];
reg [inst_sig_width+inst_exp_width:0] dp3_in_2 [0:2];
reg [inst_sig_width+inst_exp_width:0] dp3_in_3 [0:2];

reg [inst_sig_width+inst_exp_width:0] dp3_kernel [0:8];

wire [inst_sig_width+inst_exp_width : 0] mul_out_1[0:2];
wire [inst_sig_width+inst_exp_width : 0] mul_out_2[0:2];
wire [inst_sig_width+inst_exp_width : 0] mul_out_3[0:2];
wire [inst_sig_width+inst_exp_width : 0] add_out_1[0:2];

wire [inst_sig_width+inst_exp_width:0] dp3_out [0:2];
reg  [inst_sig_width+inst_exp_width:0] dp3_out_reg [0:2];

wire [inst_sig_width+inst_exp_width:0] sum_out;

reg [inst_sig_width+inst_exp_width:0] ofm_reg [0:15];
// reg [inst_sig_width+inst_exp_width:0] ofm [0:15];

reg [inst_sig_width+inst_exp_width:0] adder_a;
wire [inst_sig_width+inst_exp_width:0] adder_b;
wire [inst_sig_width+inst_exp_width:0] adder_o;

wire [inst_sig_width+inst_exp_width:0] cmp_result [0:7];
wire [inst_sig_width+inst_exp_width:0] max_pool_out [0:3];
// reg [inst_sig_width+inst_exp_width:0] max_pool_out_reg [0:3];
wire [inst_sig_width+inst_exp_width:0] dp_result [0:7];
wire [inst_sig_width+inst_exp_width:0] fc_out [0:3];
// reg [inst_sig_width+inst_exp_width:0] fc_out_reg [0:3];

wire [inst_sig_width+inst_exp_width:0] min [0:3];
wire [inst_sig_width+inst_exp_width:0] max [0:3];
wire [inst_sig_width+inst_exp_width:0] min_max;
reg [inst_sig_width+inst_exp_width:0] min_max_reg;
wire [inst_sig_width+inst_exp_width:0] numerator[0:3];
reg [inst_sig_width+inst_exp_width:0] div_numerator;
reg [inst_sig_width+inst_exp_width:0] min_max_out_reg;
wire [inst_sig_width+inst_exp_width:0] min_max_out;


reg [inst_sig_width+inst_exp_width:0] exp_in;
wire [inst_sig_width+inst_exp_width:0] exp_out_pos;
wire [inst_sig_width+inst_exp_width:0] exp_out_neg;
reg [inst_sig_width+inst_exp_width:0] exp_out_pos_reg;
reg [inst_sig_width+inst_exp_width:0] exp_out_neg_reg;

wire [inst_sig_width+inst_exp_width:0] exp_plus_one;
wire [inst_sig_width+inst_exp_width:0] exp_plus_one_p;
wire [inst_sig_width+inst_exp_width:0] exp_plus_exp;
wire [inst_sig_width+inst_exp_width:0] exp_minus_exp;
reg [inst_sig_width+inst_exp_width:0] exp_plus_one_reg;
reg [inst_sig_width+inst_exp_width:0] exp_plus_one_p_reg;
reg [inst_sig_width+inst_exp_width:0] exp_plus_exp_reg;
reg [inst_sig_width+inst_exp_width:0] exp_minus_exp_reg;

wire [inst_sig_width+inst_exp_width:0] ln_out;
//reg [inst_sig_width+inst_exp_width:0] ln_out_reg;
reg [inst_sig_width+inst_exp_width:0] div_num;
reg [inst_sig_width+inst_exp_width:0] div_den;
wire [inst_sig_width+inst_exp_width:0] final_out;

//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
reg flag;
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end
always@(*)begin
    case(current_state)
        IDLE:begin
            if(in_valid)begin
                next_state = COMP;
            end
            else begin
                next_state = IDLE;
            end
        end
        COMP:begin
            // if(done_flag)begin
            if(flag)begin
                next_state = DONE;
            end
            else begin
                next_state = COMP;
            end
        end
        DONE:begin
            next_state = IDLE;
        end
        default:begin
            next_state = IDLE;
        end
    endcase
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        counter <= 0;
    end
    else begin
        if(in_valid || current_state == COMP)begin
            counter <= counter + 1;
        end
        else begin
            counter <= 0;
        end
    end
end
//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
//OPTION
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        opt_reg <= 0;
    end
    else begin
        if(in_valid && counter == 0)begin
            opt_reg <= Opt;
        end
    end
end
//Image
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 16; i = i + 1)begin
            image_reg[i] <= 0;
        end
    end
    else begin
        if(in_valid && counter[3:0] < 16)begin
            image_reg[counter[3:0]] <= Img;
        end
        //add
        else if(counter == 59)begin
            for(i = 0; i < 4; i = i + 1)begin
                image_reg[i] <= max_pool_out[i];
            end
        end
        else if(counter ==60)begin
            for(i = 0; i < 4; i = i + 1)begin
                image_reg[i] <= fc_out[i];
            end
        end
    end
end
//Kernel
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 9; i = i + 1)begin
            kernel_reg_1[i] <= 0;
        end
    end
    else begin
        if(in_valid && counter < 9)begin
            kernel_reg_1[8] <= Kernel;
            for(i = 0; i < 8; i = i + 1)begin
                kernel_reg_1[i] <= kernel_reg_1[i + 1];
            end
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 9; i = i + 1)begin
            kernel_reg_2[i] <= 0;
        end
    end
    else begin
        if(in_valid && counter >= 9 && counter < 18)begin
            kernel_reg_2[8] <= Kernel;
            for(i = 0; i < 8; i = i + 1)begin
                kernel_reg_2[i] <= kernel_reg_2[i + 1];
            end
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 9; i = i + 1)begin
            kernel_reg_3[i] <= 0;
        end
    end
    else begin
        if(in_valid && counter >= 18 && counter < 27)begin
            kernel_reg_3[8] <= Kernel;
            for(i = 0; i < 8; i = i + 1)begin
                kernel_reg_3[i] <= kernel_reg_3[i + 1];
            end
        end
    end
end
//Weight
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 4; i = i + 1)begin
            weight_reg[i] <= 0;
        end
    end
    else begin
        if(in_valid && counter < 4)begin
            weight_reg[3] <= Weight;
            for(i = 0; i < 3; i = i + 1)begin
                weight_reg[i] <= weight_reg[i + 1];
            end
        end
    end
end
//---------------------------------------------------------------------
//   CONV
//---------------------------------------------------------------------
//record OFM pixel
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        ofm_col <= 0;
    end
    else begin
        if(counter > 8)begin
            ofm_col <= ofm_col + 1;
        end
        else begin
            ofm_col <= 0;
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        ofm_row <= 0;
    end
    else begin
        if(counter > 8)begin
            if(ofm_col == 3)
                ofm_row <= ofm_row + 1;
        end
        else begin
            ofm_row <= 0;
        end
    end
end
always@(*)begin
    //Image to IFM
    input_feature_map[7]  = image_reg[0];
    input_feature_map[8]  = image_reg[1];
    input_feature_map[9]  = image_reg[2];
    input_feature_map[10] = image_reg[3];
    input_feature_map[13] = image_reg[4];
    input_feature_map[14] = image_reg[5];
    input_feature_map[15] = image_reg[6];
    input_feature_map[16] = image_reg[7];
    input_feature_map[19] = image_reg[8];
    input_feature_map[20] = image_reg[9];
    input_feature_map[21] = image_reg[10];
    input_feature_map[22] = image_reg[11];
    input_feature_map[25] = image_reg[12];
    input_feature_map[26] = image_reg[13];
    input_feature_map[27] = image_reg[14];
    input_feature_map[28] = image_reg[15];
    if(~opt_reg[1])begin
        //Zero padding
        for(i = 0; i < 6; i = i + 1)begin
            input_feature_map[i] = 0;
        end
        for(i = 6; i < 25; i = i + 6)begin
            input_feature_map[i] = 0;
        end
        for(i = 11; i < 30; i = i + 6)begin
            input_feature_map[i] = 0;
        end
        for(i = 30; i < 36; i = i + 1)begin
            input_feature_map[i] = 0;
        end
    end
    else if(opt_reg[1])begin
        //Replication padding
        //top left
        input_feature_map[0] = image_reg[0];
        input_feature_map[1] = image_reg[0];
        input_feature_map[6] = image_reg[0];
        //top right
        input_feature_map[4]  = image_reg[3];
        input_feature_map[5]  = image_reg[3];
        input_feature_map[11] = image_reg[3];
        //down left
        input_feature_map[24] = image_reg[12];
        input_feature_map[30] = image_reg[12];
        input_feature_map[31] = image_reg[12];
        //down right
        input_feature_map[29] = image_reg[15];
        input_feature_map[34] = image_reg[15];
        input_feature_map[35] = image_reg[15];
        //else
        input_feature_map[2]  = image_reg[1];
        input_feature_map[3]  = image_reg[2];
        input_feature_map[12] = image_reg[4];
        input_feature_map[18] = image_reg[8];
        input_feature_map[17] = image_reg[7];
        input_feature_map[23] = image_reg[11];
        input_feature_map[32] = image_reg[13];
        input_feature_map[33] = image_reg[14];
    end 
    else begin
        input_feature_map[0]  = 0;
        input_feature_map[1]  = 0;
        input_feature_map[6]  = 0;
        input_feature_map[4]  = 0;
        input_feature_map[5]  = 0;
        input_feature_map[11] = 0;
        input_feature_map[24] = 0;
        input_feature_map[30] = 0;
        input_feature_map[31] = 0;
        input_feature_map[29] = 0;
        input_feature_map[34] = 0;
        input_feature_map[35] = 0;
        input_feature_map[2]  = 0;
        input_feature_map[3]  = 0;
        input_feature_map[12] = 0;
        input_feature_map[18] = 0;
        input_feature_map[17] = 0;
        input_feature_map[23] = 0;
        input_feature_map[32] = 0;
        input_feature_map[33] = 0;
    end
end
wire [4:0]map_address;
assign map_address = ofm_col + 6*ofm_row;
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 3; i = i + 1)begin
            dp3_in_1[i] <= 0;
        end
    end
    else begin
        if(counter > 8)begin
            dp3_in_1 [0] <= input_feature_map[map_address];
            dp3_in_1 [1] <= input_feature_map[map_address + 1];
            dp3_in_1 [2] <= input_feature_map[map_address + 2];
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 3; i = i + 1)begin
            dp3_in_2[i] <= 0;
        end
    end
    else begin
        if(counter > 8)begin
            dp3_in_2 [0] <= input_feature_map[map_address + 6];
            dp3_in_2 [1] <= input_feature_map[map_address + 7];
            dp3_in_2 [2] <= input_feature_map[map_address + 8];
            // dp3_in_2 [0] <= input_feature_map[ofm_col + 6*(ofm_row + 1)];
            // dp3_in_2 [1] <= input_feature_map[ofm_col + 6*(ofm_row + 1) + 1];
            // dp3_in_2 [2] <= input_feature_map[ofm_col + 6*(ofm_row + 1) + 2];
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 3; i = i + 1)begin
            dp3_in_3[i] <= 0;
        end
    end
    else begin
        if(counter > 8)begin
            dp3_in_3 [0] <= input_feature_map[map_address + 12];
            dp3_in_3 [1] <= input_feature_map[map_address + 13];
            dp3_in_3 [2] <= input_feature_map[map_address + 14];
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 9; i = i + 1)begin
                dp3_kernel[i] <= 0;
            end
    end
    else begin
        if(counter < 25)begin
            for(i = 0; i < 9; i = i + 1)begin
                dp3_kernel[i] <= kernel_reg_1[i];
            end
        end
        else if(counter < 41)begin
            for(i = 0; i < 9; i = i + 1)begin
                dp3_kernel[i] <= kernel_reg_2[i];
            end
        end
        else if(counter < 57)begin
            for(i = 0; i < 9; i = i + 1)begin
                dp3_kernel[i] <= kernel_reg_3[i];
            end
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 3; i = i + 1)begin
            dp3_out_reg[i] <= 0;
        end
    end
    else begin
        for(i = 0; i < 3; i = i + 1)begin
            dp3_out_reg[i] <= dp3_out[i];
        end
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for(i = 0; i < 16; i = i + 1)begin
            ofm_reg[i] <= 0;
        end
    end
    else begin
        if(~out_valid)begin
            case(counter)
                11,27,43:begin
                    ofm_reg[0] <= adder_o;
                end
                12,28,44:begin
                    ofm_reg[1] <= adder_o;
                end
                13,29,45:begin
                    ofm_reg[2] <= adder_o;
                end
                14,30,46:begin
                    ofm_reg[3] <= adder_o;
                end
                15,31,47:begin
                    ofm_reg[4] <= adder_o;
                end
                16,32,48:begin
                    ofm_reg[5] <= adder_o;
                end
                17,33,49:begin
                    ofm_reg[6] <= adder_o;
                end
                18,34,50:begin
                    ofm_reg[7] <= adder_o;
                end
                19,35,51:begin
                    ofm_reg[8] <= adder_o;
                end
                20,36,52:begin
                    ofm_reg[9] <= adder_o;
                end
                21,37,53:begin
                    ofm_reg[10] <= adder_o;
                end
                22,38,54:begin
                    ofm_reg[11] <= adder_o;
                end
                23,39,55:begin
                    ofm_reg[12] <= adder_o;
                end
                24,40,56:begin
                    ofm_reg[13] <= adder_o;
                end
                25,41,57:begin
                    ofm_reg[14] <= adder_o;
                end
                26,42,58:begin
                    ofm_reg[15] <= adder_o;
                end
            endcase
        end
        else begin
            for(i = 0; i < 16; i = i + 1)begin
                ofm_reg[i] <= 0;
            end
        end
    end
end
always@(*)begin
    case(counter)
        11,27,43:begin
            adder_a = ofm_reg[0];
        end
        12,28,44:begin
            adder_a = ofm_reg[1];
        end
        13,29,45:begin
            adder_a = ofm_reg[2];
        end
        14,30,46:begin
            adder_a = ofm_reg[3];
        end
        15,31,47:begin
            adder_a = ofm_reg[4];
        end
        16,32,48:begin
            adder_a = ofm_reg[5];
        end
        17,33,49:begin
            adder_a = ofm_reg[6];
        end
        18,34,50:begin
            adder_a = ofm_reg[7];
        end
        19,35,51:begin
            adder_a = ofm_reg[8];
        end
        20,36,52:begin
            adder_a = ofm_reg[9];
        end
        21,37,53:begin
            adder_a = ofm_reg[10];
        end
        22,38,54:begin
            adder_a = ofm_reg[11];
        end
        23,39,55:begin
            adder_a = ofm_reg[12];
        end
        24,40,56:begin
            adder_a = ofm_reg[13];
        end
        25,41,57:begin
            adder_a = ofm_reg[14];
        end
        26,42,58:begin
            adder_a = ofm_reg[15];
        end
        default:begin
            adder_a = 0;
        end

    endcase
end
//---------------------------------------------------------------------
//   MAX POOLING & FC
//---------------------------------------------------------------------
// always@(posedge clk or negedge rst_n)begin
//     if(~rst_n)begin
//         for(i = 0; i < 4; i = i + 1)begin
//             max_pool_out_reg[i] <= 0;
//         end
//     end
//     else begin
//         if(counter == 59)begin
            // for(i = 0; i < 4; i = i + 1)begin
            //     max_pool_out_reg[i] <= max_pool_out[i];
            // end
//         end
//     end
// end
// always@(posedge clk or negedge rst_n)begin
//     if(~rst_n)begin
//         for(i = 0; i < 4; i = i + 1)begin
//             fc_out_reg[i] <= 0;
//         end
//     end
//     else begin
//         if(counter == 60)begin
            // for(i = 0; i < 4; i = i + 1)begin
            //     fc_out_reg[i] <= fc_out[i];
            // end
//         end
//     end
// end
//---------------------------------------------------------------------
//   NORM
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        div_numerator <= 0;
    end
    else begin
        case(counter)
            61:begin
                div_numerator <= numerator[0];
            end
            62:begin
                div_numerator <= numerator[1];
            end
            63:begin
                div_numerator <= numerator[2];
            end
            64:begin
                div_numerator <= numerator[3];
            end
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        min_max_reg <= 0;
    end
    else begin
        min_max_reg <= min_max;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        min_max_out_reg <= 0;
    end
    else begin
        min_max_out_reg <= min_max_out;
    end
end
//---------------------------------------------------------------------
//   ACTIVATION
//---------------------------------------------------------------------
// always@(*)begin
//     case(counter)
//         63,64,65,66:begin
//             exp_in = min_max_out_reg;
//         end
//         default:begin
//             exp_in = 0;
//         end
//     endcase
// end
assign exp_in = min_max_out_reg;
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        exp_out_pos_reg <= 0;
    end
    else begin
        exp_out_pos_reg <= exp_out_pos;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        exp_out_neg_reg <= 0;
    end
    else begin
        exp_out_neg_reg <= exp_out_neg;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        exp_plus_one_reg <= 0;
    end
    else begin
        exp_plus_one_reg <= exp_plus_one;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        exp_plus_one_p_reg <= 0;
    end
    else begin
        exp_plus_one_p_reg <= exp_plus_one_p;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        exp_plus_exp_reg <= 0;
    end
    else begin
        exp_plus_exp_reg <= exp_plus_exp;
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        exp_minus_exp_reg <= 0;
    end
    else begin
        exp_minus_exp_reg <= exp_minus_exp;
    end
end
//changed
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        div_num <= 0;
    end
    else begin
        case(opt_reg)
            1:begin
                div_num <= exp_minus_exp_reg;
            end
            default:begin
                div_num <= 32'b0_01111111_00000000000000000000000;
            end
            // default:begin
            //     div_num = 32'b0_01111111_00000000000000000000000;
            // end
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        div_den <= 0;
    end
    else begin
        case(opt_reg)
            1:begin
                div_den <= exp_plus_exp_reg;
            end
            default:begin
                div_den <= exp_plus_one_reg;
            end
            // default:begin
            //     div_den = 32'b0_01111111_00000000000000000000000;
            // end
        endcase
    end
end
//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        flag <= 0;
    end
    else begin
        case(opt_reg)
            0:begin
                if(counter == 65)begin
                    flag <= 1;
                end
                else begin
                    flag <= 0;
                end
            end
            1,2:begin
                if(counter == 69)begin
                    flag <= 1;
                end
                else begin
                    flag <= 0;
                end
            end
            3:begin
                if(counter == 68)begin
                    flag <= 1;
                end
                else begin
                    flag <= 0;
                end
            end
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        out_valid <= 0;
    end
    else begin
        case(opt_reg)
            0:begin
                case(counter)
                    62,63,64,65:begin
                        out_valid <= 1;
                    end
                    default:begin
                        out_valid <= 0;
                    end
                endcase
            end
            1,2:begin
                case(counter)
                    66,67,68,69:begin
                        out_valid <= 1;
                    end
                    default:begin
                        out_valid <= 0;
                    end
                endcase
            end
            3:begin
                case(counter)
                    65,66,67,68:begin
                        out_valid <= 1;
                    end
                    default:begin
                        out_valid <= 0;
                    end
                endcase
            end
        endcase
    end
end
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        out <= 0;
    end
    else begin
        case(opt_reg)
            0:begin
                case(counter)
                    62,63,64,65:begin
                        if(min_max_out[31])begin
                            out <= 0;
                        end
                        else begin
                            out <= min_max_out;
                        end
                    end
                    default:begin
                        out <= 0;
                    end
                endcase
            end
            1,2:begin
                case(counter)
                    66,67,68,69:begin//changed
                        out <= final_out;
                    end
                    default:begin
                        out <= 0;
                    end
                endcase
            end
            3:begin
                case(counter)
                    65,66,67,68:begin
                        out <= ln_out;
                    end
                    default:begin
                        out <= 0;
                    end
                endcase
            end
        endcase
    end
end
//---------------------------------------------------------------------
//   IP INOUT CONTROL (FOR SHARING ADDER)
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0]add_1_in_a,add_1_in_b,add_1_out;
reg [inst_sig_width+inst_exp_width:0]add_2_in_a,add_2_in_b,add_2_out;
reg [inst_sig_width+inst_exp_width:0]add_3_in_a,add_3_in_b,add_3_out;
reg [inst_sig_width+inst_exp_width:0]add_4_in_a,add_4_in_b,add_4_out;
reg [inst_sig_width+inst_exp_width:0]add_5_in_a,add_5_in_b,add_5_out;
reg [inst_sig_width+inst_exp_width:0]add_6_in_a,add_6_in_b,add_6_out;
reg [inst_sig_width+inst_exp_width:0]add_7_in_a,add_7_in_b,add_7_out;
reg [inst_sig_width+inst_exp_width:0]add_8_in_a,add_8_in_b,add_8_out;
reg [inst_sig_width+inst_exp_width:0]add_9_in_a,add_9_in_b,add_9_out;
always@(*)begin
    if(counter < 60)begin
        add_1_in_a = mul_out_1[0];
        add_1_in_b = mul_out_2[0];
    end
    else if (counter == 60)begin
        add_1_in_a = dp_result[0];
        add_1_in_b = dp_result[1];
    end
    else begin
        add_1_in_a = image_reg[0];
        // add_1_in_a = fc_out_reg[0];
        add_1_in_b = {~min[3][31],min[3][30:0]};
    end
end
always@(*)begin
    if(counter < 60)begin
        add_2_in_a = add_1_out;
        add_2_in_b = mul_out_3[0];
    end
    else if (counter == 60) begin
        add_2_in_a = dp_result[2];
        add_2_in_b = dp_result[3];
    end
    else begin
        add_2_in_a = image_reg[1];
        // add_2_in_a = fc_out_reg[1];
        add_2_in_b = {~min[3][31],min[3][30:0]};
    end
end
always@(*)begin
    if(counter < 60)begin
        add_3_in_a = mul_out_1[1];
        add_3_in_b = mul_out_2[1];
    end
    else if (counter == 60) begin
        add_3_in_a = dp_result[4];
        add_3_in_b = dp_result[5];
    end
    else begin
        add_3_in_a = image_reg[2];
        // add_3_in_a = fc_out_reg[2];
        add_3_in_b = {~min[3][31],min[3][30:0]};
    end
end
always@(*)begin
    if(counter < 60)begin
        add_4_in_a = add_3_out;
        add_4_in_b = mul_out_3[1];
    end
    else if (counter == 60) begin
        add_4_in_a = dp_result[6];
        add_4_in_b = dp_result[7];
    end
    else begin
        add_4_in_a = image_reg[3];
        // add_4_in_a = fc_out_reg[3];
        add_4_in_b = {~min[3][31],min[3][30:0]};
    end
end
always@(*)begin
    if(counter < 60)begin
        add_5_in_a = mul_out_1[2];
        add_5_in_b = mul_out_2[2];
    end
    else begin
        add_5_in_a = 32'b0_01111111_00000000000000000000000;
        add_5_in_b = exp_out_neg_reg;
    end
end
always@(*)begin
    if(counter < 60)begin
        add_6_in_a = add_5_out;
        add_6_in_b = mul_out_3[2];
    end
    else begin
        add_6_in_a = exp_out_pos_reg;
        add_6_in_b = exp_out_neg_reg;
    end
end
always@(*)begin
    if(counter < 60)begin
        add_7_in_a = dp3_out_reg[0];
        add_7_in_b = dp3_out_reg[1];
    end
    else begin
        add_7_in_a = 32'b0_01111111_00000000000000000000000;
        add_7_in_b = exp_out_pos_reg;
    end
end
always@(*)begin
    if(counter < 60)begin
        add_8_in_a = add_7_out;
        add_8_in_b = dp3_out_reg[2];
    end
    else begin
        add_8_in_a = exp_out_pos_reg;
        add_8_in_b = {~exp_out_neg_reg[31],exp_out_neg_reg[30:0]};
    end
end
always@(*)begin
    if(counter < 60)begin
        add_9_in_a = adder_a;
        add_9_in_b = adder_b;
    end
    else begin
        add_9_in_a = max[2];
        add_9_in_b = {~min[3][31],min[3][30:0]};
    end
end
//---------------------------------------------------------------------
//   IP INOUT CONTROL (FOR SHARING MULTIPLIER)
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0]mul_1_in_a,mul_1_in_b,mul_1_out;
reg [inst_sig_width+inst_exp_width:0]mul_2_in_a,mul_2_in_b,mul_2_out;
reg [inst_sig_width+inst_exp_width:0]mul_3_in_a,mul_3_in_b,mul_3_out;
reg [inst_sig_width+inst_exp_width:0]mul_4_in_a,mul_4_in_b,mul_4_out;
reg [inst_sig_width+inst_exp_width:0]mul_5_in_a,mul_5_in_b,mul_5_out;
reg [inst_sig_width+inst_exp_width:0]mul_6_in_a,mul_6_in_b,mul_6_out;
reg [inst_sig_width+inst_exp_width:0]mul_7_in_a,mul_7_in_b,mul_7_out;
reg [inst_sig_width+inst_exp_width:0]mul_8_in_a,mul_8_in_b,mul_8_out;

always@(*)begin
    if(counter == 60)begin
        mul_1_in_a = image_reg[0];
        // mul_1_in_a = max_pool_out_reg[0];
        mul_1_in_b = weight_reg[1];
    end
    else begin
        mul_1_in_a = dp3_in_1[0];
        mul_1_in_b = dp3_kernel[0];
    end
end
always@(*)begin
    if(counter == 60)begin
        mul_2_in_a = image_reg[1];
        // mul_2_in_a = max_pool_out_reg[1];
        mul_2_in_b = weight_reg[3];
    end
    else begin
        mul_2_in_a = dp3_in_1[1];
        mul_2_in_b = dp3_kernel[1];
    end
end
always@(*)begin
    if(counter == 60)begin
        mul_3_in_a = image_reg[2];
        // mul_3_in_a = max_pool_out_reg[2];
        mul_3_in_b = weight_reg[0];
    end
    else begin
        mul_3_in_a = dp3_in_1[2];
        mul_3_in_b = dp3_kernel[2];
    end
end
always@(*)begin
    if(counter == 60)begin
        mul_4_in_a = image_reg[3];
        // mul_4_in_a = max_pool_out_reg[3];
        mul_4_in_b = weight_reg[2];
    end
    else begin
        mul_4_in_a = dp3_in_2[0];
        mul_4_in_b = dp3_kernel[3];
    end
end
always@(*)begin
    if(counter == 60)begin
        mul_5_in_a = image_reg[2];
        // mul_5_in_a = max_pool_out_reg[2];
        mul_5_in_b = weight_reg[1];
    end
    else begin
        mul_5_in_a = dp3_in_2[1];
        mul_5_in_b = dp3_kernel[4];
    end
end
always@(*)begin
    if(counter == 60)begin
        mul_6_in_a = image_reg[3];
        // mul_6_in_a = max_pool_out_reg[3];
        mul_6_in_b = weight_reg[3];
    end
    else begin
        mul_6_in_a = dp3_in_2[2];
        mul_6_in_b = dp3_kernel[5];
    end
end
always@(*)begin
    if(counter == 60)begin
        mul_7_in_a = image_reg[0];
        // mul_7_in_a = max_pool_out_reg[0];
        mul_7_in_b = weight_reg[0];
    end
    else begin
        mul_7_in_a = dp3_in_3[0];
        mul_7_in_b = dp3_kernel[6];
    end
end
always@(*)begin
    if(counter == 60)begin
        mul_8_in_a = image_reg[1];
        // mul_8_in_a = max_pool_out_reg[1];
        mul_8_in_b = weight_reg[2];
    end
    else begin
        mul_8_in_a = dp3_in_3[1];
        mul_8_in_b = dp3_kernel[7];
    end
end
//---------------------------------------------------------------------
//   IP INOUT CONTROL (FOR SHARING COMPARATOR)
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0]cmp_1_in_a,cmp_1_in_b,cmp_1_z0,cmp_1_z1;
reg [inst_sig_width+inst_exp_width:0]cmp_2_in_a,cmp_2_in_b,cmp_2_z0,cmp_2_z1;
reg [inst_sig_width+inst_exp_width:0]cmp_3_in_a,cmp_3_in_b,cmp_3_z0,cmp_3_z1;
reg [inst_sig_width+inst_exp_width:0]cmp_4_in_a,cmp_4_in_b,cmp_4_z0,cmp_4_z1;
always@(*)begin
    if(counter < 60)begin
        cmp_1_in_a = ofm_reg[0];
        cmp_1_in_b = ofm_reg[1];
    end
    else begin
        cmp_1_in_a = image_reg[0];
        // cmp_1_in_a = fc_out_reg[0];
        cmp_1_in_b = image_reg[1];
        // cmp_1_in_b = fc_out_reg[1];
    end
end
always@(*)begin
    if(counter < 60)begin
        cmp_2_in_a = ofm_reg[4];
        cmp_2_in_b = ofm_reg[5];
    end
    else begin
        cmp_2_in_a = image_reg[2];
        // cmp_2_in_a = fc_out_reg[2];
        cmp_2_in_b = image_reg[3];
        // cmp_2_in_b = fc_out_reg[3];
    end
end
always@(*)begin
    if(counter < 60)begin
        cmp_3_in_a = cmp_result[0];
        cmp_3_in_b = cmp_result[1];
    end
    else begin
        cmp_3_in_a = max[0];
        cmp_3_in_b = max[1];
    end
end
always@(*)begin
    if(counter < 60)begin
        cmp_4_in_a = ofm_reg[2];
        cmp_4_in_b = ofm_reg[3];
    end
    else begin
        cmp_4_in_a = min[0];
        cmp_4_in_b = min[1];
    end
end
//---------------------------------------------------------------------
//   IP INOUT CONTROL (FOR SHARING DIVIDER)
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width:0]div_1_in_a,div_1_in_b,div_1_out;
always@(*)begin
    if(counter < 66)begin
        div_1_in_a = div_numerator;
        div_1_in_b = min_max_reg;
    end
    else begin
        div_1_in_a = div_num;
        // mul_1_in_a = max_pool_out_reg[0];
        div_1_in_b = div_den;
    end
end
//---------------------------------------------------------------------
//   Designware IP
//---------------------------------------------------------------------
//dp3_1
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_1 ( .a(mul_1_in_a), .b(mul_1_in_b), .rnd(3'b000), .z(mul_1_out));
assign mul_out_1[0] = mul_1_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_1 ( .a(dp3_in_1[0]), .b(dp3_kernel[0]), .rnd(3'b000), .z(mul_out_1[0]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_2 ( .a(mul_2_in_a), .b(mul_2_in_b), .rnd(3'b000), .z(mul_2_out));
assign mul_out_2[0] = mul_2_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_2 ( .a(dp3_in_1[1]), .b(dp3_kernel[1]), .rnd(3'b000), .z(mul_out_2[0]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_3 ( .a(mul_3_in_a), .b(mul_3_in_b), .rnd(3'b000), .z(mul_3_out));
assign mul_out_3[0] = mul_3_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_3 ( .a(dp3_in_1[2]), .b(dp3_kernel[2]), .rnd(3'b000), .z(mul_out_3[0]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_1 ( .a(add_1_in_a), .b(add_1_in_b), .rnd(3'b000), .z(add_1_out));
//assign add_out_1[0] = add_1_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_1 ( .a(mul_out_1[0]), .b(mul_out_2[0]), .rnd(3'b000), .z(add_out_1[0]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_2 ( .a(add_2_in_a), .b(add_2_in_b), .rnd(3'b000), .z(add_2_out));
assign dp3_out[0] = add_2_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_2 ( .a(add_out_1[0]), .b(mul_out_3[0]), .rnd(3'b000), .z(dp3_out[0]));
//dp3_2
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_4 ( .a(mul_4_in_a), .b(mul_4_in_b), .rnd(3'b000), .z(mul_4_out));
assign mul_out_1[1] = mul_4_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_4 ( .a(dp3_in_2[0]), .b(dp3_kernel[3]), .rnd(3'b000), .z(mul_out_1[1]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_5 ( .a(mul_5_in_a), .b(mul_5_in_b), .rnd(3'b000), .z(mul_5_out));
assign mul_out_2[1] = mul_5_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_5 ( .a(dp3_in_2[1]), .b(dp3_kernel[4]), .rnd(3'b000), .z(mul_out_2[1]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_6 ( .a(mul_6_in_a), .b(mul_6_in_b), .rnd(3'b000), .z(mul_6_out));
assign mul_out_3[1] = mul_6_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_6 ( .a(dp3_in_2[2]), .b(dp3_kernel[5]), .rnd(3'b000), .z(mul_out_3[1]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_3 ( .a(add_3_in_a), .b(add_3_in_b), .rnd(3'b000), .z(add_3_out));
//assign add_out_1[1] = add_3_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_3 ( .a(mul_out_1[1]), .b(mul_out_2[1]), .rnd(3'b000), .z(add_out_1[1]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_4 ( .a(add_4_in_a), .b(add_4_in_b), .rnd(3'b000), .z(add_4_out));
assign dp3_out[1] = add_4_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_4 ( .a(add_out_1[1]), .b(mul_out_3[1]), .rnd(3'b000), .z(dp3_out[1]));
//dp3_3
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_7 ( .a(mul_7_in_a), .b(mul_7_in_b), .rnd(3'b000), .z(mul_7_out));
assign mul_out_1[2] = mul_7_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_7 ( .a(dp3_in_3[0]), .b(dp3_kernel[6]), .rnd(3'b000), .z(mul_out_1[2]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_8 ( .a(mul_8_in_a), .b(mul_8_in_b), .rnd(3'b000), .z(mul_8_out));
assign mul_out_2[2] = mul_8_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_8 ( .a(dp3_in_3[1]), .b(dp3_kernel[7]), .rnd(3'b000), .z(mul_out_2[2]));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
mul_9 ( .a(dp3_in_3[2]), .b(dp3_kernel[8]), .rnd(3'b000), .z(mul_out_3[2]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_5 ( .a(add_5_in_a), .b(add_5_in_b), .rnd(3'b000), .z(add_5_out));
//assign add_out_1[2] = add_5_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_5 ( .a(mul_out_1[2]), .b(mul_out_2[2]), .rnd(3'b000), .z(add_out_1[2]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_6 ( .a(add_6_in_a), .b(add_6_in_b), .rnd(3'b000), .z(add_6_out));
assign dp3_out[2] = add_6_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_6 ( .a(add_out_1[2]), .b(mul_out_3[2]), .rnd(3'b000), .z(dp3_out[2]));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_7 ( .a(add_7_in_a), .b(add_7_in_b), .rnd(3'b000), .z(add_7_out));
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_7 ( .a(dp3_out_reg[0]), .b(dp3_out_reg[1]), .rnd(3'b000), .z(add_7_out));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_8 ( .a(add_8_in_a), .b(add_8_in_b), .rnd(3'b000), .z(add_8_out));
assign sum_out = add_8_out; 
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_8 ( .a(add_7_out), .b(dp3_out_reg[2]), .rnd(3'b000), .z(sum_out));
//Conv
// DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
// sum3_1 (
// .a(dp3_out_reg[0]),
// .b(dp3_out_reg[1]),
// .c(dp3_out_reg[2]),
// .rnd(3'b000),
// .z(sum_out));
assign adder_b = sum_out;
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
add_9 ( .a(add_9_in_a), .b(add_9_in_b), .rnd(3'b000), .z(add_9_out));
assign adder_o = add_9_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// add_9 ( .a(adder_a), .b(adder_b), .rnd(3'b000), .z(adder_o));


//Max pool
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c1 ( .a(cmp_1_in_a), .b(cmp_1_in_b), .zctr(1'b0),.z0(cmp_1_z0) ,  .z1(cmp_1_z1));
assign cmp_result[0] = cmp_1_z1;
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// c1 ( .a(ofm_reg[0]), .b(ofm_reg[1]), .zctr(1'b0),  .z1(cmp_result[0]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c2 ( .a(cmp_2_in_a), .b(cmp_2_in_b), .zctr(1'b0),.z0(cmp_2_z0),  .z1(cmp_2_z1));
assign cmp_result[1] = cmp_2_z1;
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// c2 ( .a(ofm_reg[4]), .b(ofm_reg[5]), .zctr(1'b0),  .z1(cmp_result[1]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c3 ( .a(cmp_3_in_a), .b(cmp_3_in_b), .zctr(1'b0),.z0(cmp_3_z0),  .z1(cmp_3_z1));
assign max_pool_out[0] = cmp_3_z1;
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// c3 ( .a(cmp_result[0]), .b(cmp_result[1]), .zctr(1'b0),  .z1(max_pool_out[0]));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c4 ( .a(cmp_4_in_a), .b(cmp_4_in_b), .zctr(1'b0),.z0(cmp_4_z0),  .z1(cmp_4_z1));
assign cmp_result[2] = cmp_4_z1;
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// c4 ( .a(ofm_reg[2]), .b(ofm_reg[3]), .zctr(1'b0),  .z1(cmp_result[2]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c5 ( .a(ofm_reg[6]), .b(ofm_reg[7]), .zctr(1'b0),  .z1(cmp_result[3]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c6 ( .a(cmp_result[2]), .b(cmp_result[3]), .zctr(1'b0),  .z1(max_pool_out[1]));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c7 ( .a(ofm_reg[8]), .b(ofm_reg[9]), .zctr(1'b0),  .z1(cmp_result[4]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c8 ( .a(ofm_reg[12]), .b(ofm_reg[13]), .zctr(1'b0),  .z1(cmp_result[5]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c9 ( .a(cmp_result[4]), .b(cmp_result[5]), .zctr(1'b0),  .z1(max_pool_out[2]));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c10 ( .a(ofm_reg[10]), .b(ofm_reg[11]), .zctr(1'b0),  .z1(cmp_result[6]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c11 ( .a(ofm_reg[14]), .b(ofm_reg[15]), .zctr(1'b0),  .z1(cmp_result[7]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
c12 ( .a(cmp_result[6]), .b(cmp_result[7]), .zctr(1'b0),  .z1(max_pool_out[3]));
//cut
//FC Layer
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f1 ( .a(max_pool_out_reg[0]), .b(weight_reg[0]), .rnd(3'b000), .z(dp_result[0]));
assign dp_result[0] = mul_7_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f2 ( .a(max_pool_out_reg[1]), .b(weight_reg[2]), .rnd(3'b000), .z(dp_result[1]));
assign dp_result[1] = mul_8_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f3 ( .a(dp_result[0]), .b(dp_result[1]), .rnd(3'b000), .z(fc_out[0]));
assign fc_out[0] = add_1_out;

// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f4 ( .a(max_pool_out_reg[0]), .b(weight_reg[1]), .rnd(3'b000), .z(dp_result[2]));
assign dp_result[2] = mul_1_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f5 ( .a(max_pool_out_reg[1]), .b(weight_reg[3]), .rnd(3'b000), .z(dp_result[3]));
assign dp_result[3] = mul_2_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f6 ( .a(dp_result[2]), .b(dp_result[3]), .rnd(3'b000), .z(fc_out[1]));
assign fc_out[1] = add_2_out;

// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f7 ( .a(max_pool_out_reg[2]), .b(weight_reg[0]), .rnd(3'b000), .z(dp_result[4]));
assign dp_result[4] = mul_3_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f8 ( .a(max_pool_out_reg[3]), .b(weight_reg[2]), .rnd(3'b000), .z(dp_result[5]));
assign dp_result[5] = mul_4_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f9 ( .a(dp_result[4]), .b(dp_result[5]), .rnd(3'b000), .z(fc_out[2]));
assign fc_out[2] = add_3_out;

// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f10 ( .a(max_pool_out_reg[2]), .b(weight_reg[1]), .rnd(3'b000), .z(dp_result[6]));
assign dp_result[6] = mul_5_out;
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f11 ( .a(max_pool_out_reg[3]), .b(weight_reg[3]), .rnd(3'b000), .z(dp_result[7]));
assign dp_result[7] = mul_6_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// f12 ( .a(dp_result[6]), .b(dp_result[7]), .rnd(3'b000), .z(fc_out[3]));
assign fc_out[3] = add_4_out;

//min - MAX
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U1 ( .a(fc_out_reg[0]), .b(fc_out_reg[1]), .zctr(1'b0), .z0(min[0]), .z1(max[0]));
assign min[0] = cmp_1_z0;
assign max[0] = cmp_1_z1;
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U2 ( .a(fc_out_reg[2]), .b(fc_out_reg[3]), .zctr(1'b0), .z0(min[1]), .z1(max[1]));
assign min[1] = cmp_2_z0;
assign max[1] = cmp_2_z1;
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U3 ( .a(max[0]), .b(max[1]), .zctr(1'b0), .z0(min[2]), .z1(max[2]));
assign min[2] = cmp_3_z0;
assign max[2] = cmp_3_z1;
// DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U4 ( .a(min[0]), .b(min[1]), .zctr(1'b0), .z0(min[3]), .z1(max[3]));
assign min[3] = cmp_4_z0;
assign max[3] = cmp_4_z1;

// DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U5 ( .a(max[2]), .b(min[3]), .rnd(3'b000), .z(min_max));
assign min_max = add_9_out;
// DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U6 ( .a(fc_out_reg[0]), .b(min[3]), .rnd(3'b000), .z(numerator[0]));
assign numerator[0] = add_1_out;
// DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U7 ( .a(fc_out_reg[1]), .b(min[3]), .rnd(3'b000), .z(numerator[1]));
assign numerator[1] = add_2_out;
// DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U8 ( .a(fc_out_reg[2]), .b(min[3]), .rnd(3'b000), .z(numerator[2]));
assign numerator[2] = add_3_out;
// DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// U9 ( .a(fc_out_reg[3]), .b(min[3]), .rnd(3'b000), .z(numerator[3]));
assign numerator[3] = add_4_out;
//cut
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) U10
( .a(div_1_in_a), .b(div_1_in_b), .rnd(3'b000), .z(div_1_out));
assign min_max_out = div_1_out;
// DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) U10
// ( .a(div_numerator), .b(min_max_reg), .rnd(3'b000), .z(min_max_out));

//activation
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp_for_pos (
.a(exp_in),
.z(exp_out_pos));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) exp_for_neg (
.a({~exp_in[31], exp_in[30:0]}),
.z(exp_out_neg));

// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// act1 ( .a(32'b0_01111111_00000000000000000000000), .b(exp_out_neg_reg), .rnd(3'b000), .z(exp_plus_one));
assign exp_plus_one = add_5_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// act2 ( .a(exp_out_pos_reg), .b(exp_out_neg_reg), .rnd(3'b000), .z(exp_plus_exp));
assign exp_plus_exp = add_6_out;
// DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// act3 ( .a(exp_out_pos_reg), .b(exp_out_neg_reg), .rnd(3'b000), .z(exp_minus_exp));
assign exp_minus_exp = add_8_out;
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// act4 ( .a(32'b0_01111111_00000000000000000000000), .b(exp_out_pos_reg), .rnd(3'b000), .z(exp_plus_one_p));
assign exp_plus_one_p = add_7_out;

DW_fp_ln #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0,
inst_arch) ln_1 (
.a(exp_plus_one_p_reg),
.z(ln_out));

// DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) div_1
// ( .a(div_num), .b(div_den), .rnd(3'b000), .z(final_out));
assign final_out = div_1_out;
endmodule
// module fp_dp3( a, b, c, d, e,
// f, rnd, z);
// parameter inst_sig_width = 23;
// parameter inst_exp_width = 8;
// parameter inst_ieee_compliance = 0;
// parameter inst_arch_type = 0;
// input [inst_sig_width+inst_exp_width : 0] a;
// input [inst_sig_width+inst_exp_width : 0] b;
// input [inst_sig_width+inst_exp_width : 0] c;
// input [inst_sig_width+inst_exp_width : 0] d;
// input [inst_sig_width+inst_exp_width : 0] e;
// input [inst_sig_width+inst_exp_width : 0] f;
// input [2 : 0] rnd;
// output [inst_sig_width+inst_exp_width : 0] z;
// //output [7 : 0] status_inst;
// wire [inst_sig_width+inst_exp_width : 0] mul_out_1;
// wire [inst_sig_width+inst_exp_width : 0] mul_out_2;
// wire [inst_sig_width+inst_exp_width : 0] mul_out_3;
// // Instance of DW_fp_dp3
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_1 ( .a(a), .b(b), .rnd(rnd), .z(mul_out_1));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_2 ( .a(c), .b(d), .rnd(rnd), .z(mul_out_2));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// mul_3 ( .a(e), .b(f), .rnd(rnd), .z(mul_out_3));
// DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
// s1 (
// .a(mul_out_1),
// .b(mul_out_2),
// .c(mul_out_3),
// .rnd(rnd),
// .z(z));
// endmodule