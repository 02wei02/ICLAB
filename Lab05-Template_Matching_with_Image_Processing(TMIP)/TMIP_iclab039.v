module TMIP (
    // input signals
    clk,
    rst_n,
    in_valid,
    in_valid2,

    image,
    template,
    image_size,
    action,

    // output signals
    out_valid,
    out_value
  );

  //---------------------------------------------------------------------
  //   INPUT AND OUTPUT DECLARATION
  //---------------------------------------------------------------------
  input clk, rst_n;
  input in_valid, in_valid2;

  input [7:0] image;
  input [7:0] template;
  input [1:0] image_size;
  input [2:0] action;

  output reg out_valid;
  output reg out_value;


  //---------------------------------------------------------------------
  //   PARAMETER
  //---------------------------------------------------------------------
  parameter IDLE = 0;
  parameter INPUT = 1;
  parameter GRAY = 2;
  parameter MAXP = 3;
  parameter NEG = 4;
  parameter HORI = 5;
  parameter IMGF = 6;
  parameter CROSSC = 7;
  parameter OUT = 8;
  integer i, j, k;

  //---------------------------------------------------------------------
  //   WIRE AND REG DECLARATION
  //---------------------------------------------------------------------


  reg [4:0] img_size_after, img_size_reg;

  reg flag2;
  reg [3:0] state_cs;
  reg [2:0] action_reg[0:7];

  reg [7:0] gray_max, gray_ave,gray_weighted, RcompG;

  // for memory comparison
  reg  [7:0] m_A;
  reg  [23:0] m_D,m_Q;
  reg m_Wen;
  reg  [8:0] cnt_mA; // count for memory address

  //   // template image
  //   reg [7:0] t_A;  // 9 bits ?????
  //   reg [7:0] t_D;
  //   reg [7:0] t_Q;
  //   reg t_Wen;


  //   reg [7:0]  gray_max_reg, gray_ave_reg ,  gray_weight_reg;
  reg  [19:0] gray_img       [0:15][0:15];
  reg [7:0] img_R, img_G,img_B;
  reg [7:0] in_cnt;





  reg  [9:0] cnt_in;
  reg  [4:0] cnt_in2;


  reg  [12:0] cnt_graycode;
  reg  [6:0] cnt_max;


  reg  [4:0] cnt_out;
  reg  [3:0] cnt_act;

  reg  [8:0] cnt_gray_x, cnt_gray_y, cnt_con_x, cnt_con_y, cnt_mod_x,cnt_mod_y;
  reg  [8:0] cnt_imgf; // count for image filter

  reg  [7:0] padding            [0:17][0:17]; // for max filtering

  reg  [20:0] cnt_cont_out, cnt_out20; // 20 cycles for output 20 bits
  reg  [20:0] cnt_hori;
  reg  [20:0] cnt_conv;



  reg [4:0] cnt_y, cnt_x, cnt_neg_y, cnt_neg_x;


  reg [7:0] temp[0:2][0:2];

  reg flag_imgfilter;

  reg [1:0] grayscale;


  reg [8:0] num_data;
  reg [3:0] num_data2;
  reg [6:0] num_data3;

  reg [7:0] max1_1, max2_1, max3_1, max1_2, max2_2, max3_2;

  reg [7:0] max00, max10, max01, max11;

  reg [9:0] pad_y;

  reg [5:0] pad_x,pad_xp1;


  reg [19:0] cnt_cont_out_x;

  always @(*)
  begin
    case (img_size_after)
      16:
      begin
        num_data3 <= 64;
        num_data2 <= 8;
        num_data  <= 256;
      end
      8:
      begin
        num_data3 <= 16;
        num_data2 <= 4;
        num_data  <= 64;
      end
      4:
      begin
        num_data3 <= 4;
        num_data2 <= 2;
        num_data  <= 16;
      end
      default:
      begin
        num_data3 <= 0;
        num_data2 <= 0;
        num_data  <= 0;
      end
    endcase
  end

  //---------------------------------------------------------------------
  //   SRAM
  // ---------------------------------------------------------------------
  SRAM_256X24 u1_sram256x24 (
                .A0  (m_A[0]),
                .A1  (m_A[1]),
                .A2  (m_A[2]),
                .A3  (m_A[3]),
                .A4  (m_A[4]),
                .A5  (m_A[5]),
                .A6  (m_A[6]),
                .A7  (m_A[7]),
                .DO0 (m_Q[0]),
                .DO1 (m_Q[1]),
                .DO2 (m_Q[2]),
                .DO3 (m_Q[3]),
                .DO4 (m_Q[4]),
                .DO5 (m_Q[5]),
                .DO6 (m_Q[6]),
                .DO7 (m_Q[7]),
                .DO8 (m_Q[8]),
                .DO9 (m_Q[9]),
                .DO10(m_Q[10]),
                .DO11(m_Q[11]),
                .DO12(m_Q[12]),
                .DO13(m_Q[13]),
                .DO14(m_Q[14]),
                .DO15(m_Q[15]),
                .DO16(m_Q[16]),
                .DO17(m_Q[17]),
                .DO18(m_Q[18]),
                .DO19(m_Q[19]),
                .DO20(m_Q[20]),
                .DO21(m_Q[21]),
                .DO22(m_Q[22]),
                .DO23(m_Q[23]),
                .DI0 (m_D[0]),
                .DI1 (m_D[1]),
                .DI2 (m_D[2]),
                .DI3 (m_D[3]),
                .DI4 (m_D[4]),
                .DI5 (m_D[5]),
                .DI6 (m_D[6]),
                .DI7 (m_D[7]),
                .DI8 (m_D[8]),
                .DI9 (m_D[9]),
                .DI10(m_D[10]),
                .DI11(m_D[11]),
                .DI12(m_D[12]),
                .DI13(m_D[13]),
                .DI14(m_D[14]),
                .DI15(m_D[15]),
                .DI16(m_D[16]),
                .DI17(m_D[17]),
                .DI18(m_D[18]),
                .DI19(m_D[19]),
                .DI20(m_D[20]),
                .DI21(m_D[21]),
                .DI22(m_D[22]),
                .DI23(m_D[23]),
                .CK  (clk),
                .WEB (m_Wen),
                .OE  (1'b1),
                .CS  (1'b1)
              );

  //   // Instantiate the SRAM_256X8 module // cycle time would be over 5000 when store img filter
  //   SRAM_256X8 u2_sram (
  //                .A0 (t_A[0]),
  //                .A1 (t_A[1]),
  //                .A2 (t_A[2]),
  //                .A3 (t_A[3]),
  //                .A4 (t_A[4]),
  //                .A5 (t_A[5]),
  //                .A6 (t_A[6]),
  //                .A7 (t_A[7]),
  //                .DO0(t_Q[0]),
  //                .DO1(t_Q[1]),
  //                .DO2(t_Q[2]),
  //                .DO3(t_Q[3]),
  //                .DO4(t_Q[4]),
  //                .DO5(t_Q[5]),
  //                .DO6(t_Q[6]),
  //                .DO7(t_Q[7]),
  //                .DI0(t_D[0]),
  //                .DI1(t_D[1]),
  //                .DI2(t_D[2]),
  //                .DI3(t_D[3]),
  //                .DI4(t_D[4]),
  //                .DI5(t_D[5]),
  //                .DI6(t_D[6]),
  //                .DI7(t_D[7]),
  //                .CK (clk),
  //                .WEB(t_Wen),
  //                .OE (1'b1),
  //                .CS (1'b1)
  //              );
  //---------------------------------------------------------------------
  //   FINITE STATE MACHINE
  // ---------------------------------------------------------------------

  always @(posedge clk, negedge rst_n)
  begin
    if(!rst_n)
    begin
      state_cs <= INPUT;
    end
    else
    case (state_cs)
      IDLE, MAXP, NEG, HORI:
      begin
        case (action_reg[cnt_act])
          MAXP:
          begin
            state_cs <= MAXP;
          end
          NEG:
          begin
            state_cs <= NEG;
          end
          HORI:
          begin
            state_cs <= HORI;
          end
          IMGF:
          begin
            state_cs <= IMGF;
          end
          CROSSC:
          begin
            state_cs <= CROSSC;
          end
          default:
          begin
            state_cs <= state_cs;
          end
        endcase
      end
      INPUT:
      begin
        state_cs <= (cnt_in2 > 0 && in_valid2 == 0)? GRAY: INPUT;
      end
      GRAY:
      begin
        if (cnt_graycode == num_data + 1)
        begin
          case (action_reg[1])
            MAXP:
            begin
              state_cs <= MAXP;
            end
            NEG:
            begin
              state_cs <= NEG;
            end
            HORI:
            begin
              state_cs <= HORI;
            end
            IMGF:
            begin
              state_cs <= IMGF;
            end
            CROSSC:
            begin
              state_cs <= CROSSC;
            end
            default:
            begin
              state_cs <= GRAY;
            end
          endcase
        end
        else
        begin
          state_cs <= GRAY;
        end
      end
      IMGF:
      begin
        if (flag2)
        begin
          state_cs <= IDLE;
        end
        else
        begin
          state_cs <= IMGF;
        end
      end
      CROSSC:
      begin
        if ((cnt_conv > 15) && !out_valid)
        begin
          state_cs <= INPUT;
        end
        else
        begin
          state_cs <= CROSSC;
        end
      end
      default:
      begin
        state_cs <= INPUT;
      end
    endcase
  end

  //==================================================================
  // GRAY TRANSFORMATION
  //==================================================================



  always @(*)
  begin
    RcompG <=(img_R >= img_G) ? img_R : img_G;
    gray_max <=(RcompG > img_B) ? RcompG : img_B;
    gray_ave <=(img_R + img_G + img_B) / 3;
    gray_weighted <=(img_R / 4) + (img_G / 2) + (img_B / 4);
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      img_R <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid && grayscale ==0)
            img_R <= image;
        end
        default:
        begin
          img_R <= 0;
        end
      endcase
    end
  end

  //   always @(posedge clk, negedge rst_n) begin
  //     if (!rst_n) begin
  //       gray_max_reg <= 0;
  //       gray_ave_reg <= 0;
  //       gray_weight_reg <= 0;
  //     end else begin
  //       gray_max_reg <= gray_max;
  //       gray_ave_reg <= gray_ave;
  //       gray_weight_reg <= gray_weighted;
  //     end
  //   end

  //   always @(*) begin
  //     gray_max = 0;
  //     gray_ave = 0;
  //     gray_weighted = 0;
  //     if (in_valid) begin

  //       // maximum method
  //       if (grayscale == 0) begin
  //         gray_max = image;
  //       end else gray_max = (gray_max_reg < image) ? image : gray_max_reg;

  //       // average method
  //       if (grayscale == 0) begin
  //         gray_ave = image;
  //       end else if (grayscale == 2) begin
  //         gray_ave = (gray_ave_reg + image) / 3;
  //       end else begin
  //         gray_ave = gray_ave_reg + image;
  //       end

  //       //weighted method
  //       if (grayscale == 0) begin
  //         gray_weighted = image / 4;
  //       end else if (grayscale == 1) begin
  //         gray_weighted = gray_weight_reg + image / 2;
  //       end else begin
  //         gray_weighted = gray_weight_reg + image / 4;
  //       end
  //     end
  //   end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      img_G <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid && grayscale == 1)
          begin
            img_G <= image;
          end
        end
        default:
        begin
          img_G <= 0;
        end
      endcase
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      img_B <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid && grayscale == 2)
          begin
            img_B <= image;
          end
        end
        default:
        begin
          img_B <= 0;
        end
      endcase
    end
  end



  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      temp[0][0] <=0;
      temp[0][1] <=0;
      temp[0][2] <=0;
      temp[1][0] <=0;
      temp[1][1] <=0;
      temp[1][2] <=0;
      temp[2][0] <=0;
      temp[2][1] <=0;
      temp[2][2] <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid)
          begin
            temp[cnt_in/3][cnt_in%3] <= template;
          end
        end
      endcase
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      img_size_after <= 0;
    end
    else
    begin
      if(state_cs == INPUT)
      begin
        img_size_after <= img_size_reg;
      end
      else if(state_cs == MAXP)
      begin
        if (img_size_after == 8)
        begin
          img_size_after <= (cnt_max == 15) ? 4 : img_size_after;
        end
        else
        begin
          img_size_after <= (cnt_max == 63) ? 8 : img_size_after;
        end
      end
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      img_size_reg <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid && cnt_in == 0)
          begin
            case (image_size)
              0:
                img_size_reg <= 4;
              1:
                img_size_reg <= 8;
              default:
                img_size_reg <= 16;
            endcase
          end
        end
      endcase
    end
  end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      action_reg[0] <= 0;
      action_reg[1] <= 0;
      action_reg[2] <=0;
      action_reg[3] <=0;
      action_reg[4] <=0;
      action_reg[5] <= 0;
      action_reg[6] <= 0;
      action_reg[7] <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid2)
          begin
            action_reg[cnt_in2] <= action;
          end
        end
        CROSSC:
        begin
          action_reg[0] <= 0;
          action_reg[1] <= 0;
          action_reg[2] <=0;
          action_reg[3] <=0;
          action_reg[4] <=0;
          action_reg[5] <= 0;
          action_reg[6] <= 0;
          action_reg[7] <= 0;
        end
      endcase
    end
  end



  //==============================================//
  // COMPARATOR BY SORTING NETWORKS
  //==============================================//


  always@(*)
  begin
    pad_y <=(cnt_max / num_data2) * 2;
    pad_x <=  cnt_max * 2 % img_size_after;
    pad_xp1 <= (pad_x + 1 == img_size_after) ? 0 : pad_x + 1;
    max00 <= gray_img[pad_y][pad_x];
    max10 <= gray_img[pad_y+1][pad_x];
    max01 <= gray_img[pad_y][pad_xp1];
    max11 <= gray_img[pad_y+1][pad_xp1];
  end

  always@(*)
  begin
    {max1_1,max1_2} <= (max00 > max10)? {max00,max10} : {max10,max00};
    {max2_1,max2_2} <= (max01 > max11)? {max01,max11} : {max11,max01};
    {max3_1,max3_2} <= (max1_1 > max2_1)? {max1_1,max2_1} : {max2_1,max1_1};
  end

  wire [7:0] lev2_0, lev2_1, lev2_2, lev2_3;
  wire [7:0] lev3_0, lev3_1, lev3_2,lev3_3;
  wire [7:0] lev4_0, lev4_1, lev4_2, lev4_3;
  wire [7:0] lev5_0,  lev5_1, lev5_2;
  wire [7:0] lev6_0, lev6_1, lev6_2, lev6_3;
  wire [7:0] lev7_0, lev7_1, lev7_2;
  wire [7:0] lev8_0;


  wire [7:0]   s2_3, s2_5, s2_7, s2_8,s3_4,s3_6,s3_7,s3_8,s4_2,s4_3,s4_5,s4_8,s5_4,s5_6,s5_7,s6_1,s6_4,s6_5,s6_8,s7_3,s7_5,s7_7,s8_4;

  reg [8:0] start_pad_y;

  reg [5:0] start_pad_x;

  always@(*)
  begin
    start_pad_y <= cnt_y;
    start_pad_x<= cnt_x;
  end

  // in1, in2, larger, smaller
  comp u1_comp (padding[start_pad_y][start_pad_x],padding[start_pad_y][start_pad_x+1],(lev2_0),(s2_3));
  comp u2_comp (padding[start_pad_y][start_pad_x+2],padding[start_pad_y+1][start_pad_x],(lev2_1),(s2_7));
  comp u3_comp ((padding[start_pad_y+1][start_pad_x+1]),(padding[start_pad_y+1][start_pad_x+2]),(lev2_2),(s2_5));
  comp u4_comp ((padding[start_pad_y+2][start_pad_x]),(padding[start_pad_y+2][start_pad_x+1]),(lev2_3),(s2_8));

  comp u5_comp ((lev2_0),(s2_7),(lev3_0),(s3_7));
  comp u6_comp ((lev2_2),(lev2_3),(lev3_1),(s3_4));
  comp u7_comp ((s2_3),(s2_8),(lev3_2),(s3_8));
  comp u8_comp ((s2_5),(padding[start_pad_y+2][start_pad_x+2]),(lev3_3),(s3_6));

  comp u9_comp ((lev3_0),(lev3_1),(lev4_0),(s4_2));
  comp u10_comp ((lev2_1),(lev3_2),(lev4_1),(s4_3));

  comp u11_comp ((s3_4),(lev3_3),(lev4_2),(s4_5));

  comp u12_comp ((s3_7),(s3_8),(lev4_3),(s4_8));

  comp u13_comp ((lev4_1),(lev4_2),(lev5_0),(s5_4));
  comp u14_comp ((s4_3),(s3_6),(lev5_1),(s5_6));
  comp u15_comp ((s4_5),(lev4_3),(lev5_2),(s5_7) );

  comp u16_comp ((lev4_0),(lev5_0),(lev6_0),(s6_1));
  comp u17_comp ((s4_2),(s5_4),(lev6_1),(s6_4) );
  comp u18_comp ( (lev5_1), (lev5_2), (lev6_2),(s6_5));
  comp u19_comp ((s5_6),(s4_8), (lev6_3),(s6_8));

  comp u20_comp ((lev6_1), (lev6_2), (lev7_0), (s7_3));
  comp u21_comp ((s6_4),(s6_5),(lev7_1),(s7_5));
  comp u22_comp ((lev6_3),(s5_7),(lev7_2),(s7_7));

  comp u23_comp ((s7_3),(lev7_1), (lev8_0),(s8_4));


  //==================================================================
  // DESIGN
  //==================================================================

  //==================================================================
  // IMAGE INPUT
  //==================================================================
  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      for (i = 0; i < 16; i++)
      begin
        for (j = 0; j < 16; j++)
        begin
          gray_img[i][j] <= 0;
        end
      end
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          for (i = 0; i < 16; i++)
          begin
            for (j = 0; j < 16; j++)
            begin
              gray_img[i][j] <= 0;
            end
          end
        end
        GRAY:
        begin
          if (action_reg[0] == INPUT && cnt_graycode > 0)
          begin
            gray_img[cnt_gray_y][cnt_gray_x] <= m_Q[15:8];
          end
          else if (action_reg[0] == GRAY && cnt_graycode > 0)
          begin
            gray_img[cnt_gray_y][cnt_gray_x] <= m_Q[7:0];
          end
          else if (cnt_graycode > 0)
          begin
            gray_img[cnt_gray_y][cnt_gray_x] <= m_Q[23:16];
          end
        end
        MAXP:
        begin
          if (img_size_after != 4)
          begin
            gray_img[cnt_max / num_data2][cnt_max % num_data2] <= max3_1;
          end
        end
        NEG:
        begin
          if (action_reg[cnt_act] == NEG)
          begin
            gray_img[cnt_neg_y][cnt_neg_x] <= ~gray_img[cnt_neg_y][cnt_neg_x];
          end
        end
        HORI:
        begin
          if (action_reg[cnt_act] == HORI)
          begin
            case (img_size_after)
              4:
              begin
                for (i = 0; i < 4; i++)
                begin
                  gray_img[i][0] <= gray_img[i][3];
                  gray_img[i][1] <= gray_img[i][2];
                  gray_img[i][2] <= gray_img[i][1];
                  gray_img[i][3] <= gray_img[i][0];
                end
              end
              8:
              begin
                for (i = 0; i < 8; i++)
                begin
                  for (j = 0; j < 8; j++)
                  begin
                    gray_img[i][j] <= gray_img[i][7 - j];
                  end
                end
              end
              16:
              begin
                for (i = 0; i < 16; i++)
                begin
                  for (j = 0; j < 16; j++)
                  begin
                    gray_img[i][j] <= gray_img[i][15 - j];
                  end
                end
              end
            endcase
          end
        end
        CROSSC:
        begin
          if (cnt_conv == 0)
          begin
            for (i = 0; i < img_size_after; i++)
            begin
              gray_img[0][i] <= 0;
              gray_img[1][i] <= 0;
            end
          end
          else
          begin
            if (cnt_conv > 0 && cnt_conv + 1 < img_size_after)
            begin
              for (i = 0; i < img_size_after; i++)
              begin
                gray_img[cnt_conv + 1][i] <= 0;
              end
            end
            if (cnt_con_y < img_size_after && cnt_con_x < img_size_after)
            begin
              gray_img[cnt_con_y][cnt_con_x] <= gray_img[cnt_con_y][cnt_con_x] +
              (padding[cnt_con_y + cnt_mod_y][cnt_con_x + cnt_mod_x] * temp[cnt_mod_y][cnt_mod_x]);
            end
          end
        end
        IMGF:
        begin
          gray_img[cnt_y][cnt_x] <= s8_4;
        end
      endcase
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      grayscale <= 0;
    end
    else
    begin
      if(state_cs == INPUT)
      begin
        if (in_valid)
        begin
          if (grayscale == 2)
          begin
            grayscale <= 0;
          end
          else
          begin
            grayscale <= grayscale + 1;
          end
        end
      end
      else
      begin
        grayscale <= 0;
      end
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_x <= 0;
    end
    else
    begin
      if(state_cs == IMGF && flag_imgfilter == 1)
      begin
        if (flag_imgfilter == 1)
        begin
          cnt_x <=(cnt_x + 1 == img_size_after)? 0 : cnt_x+1;
        end
      end
      else
      begin
        cnt_x <= 0;
      end
    end
  end

  always @(posedge clk)
  begin
    if (state_cs == IMGF && flag_imgfilter == 1)
    begin
      if (cnt_x + 1 == img_size_after)
      begin
        cnt_y <=(cnt_y + 1 == img_size_after)? 0: ( cnt_y + 1);
      end
    end
    else
    begin
      cnt_y <= 0;
    end
  end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      for (i = 0; i < 18; i++)
      begin
        for (j = 0; j < 18; j++)
        begin
          padding[i][j] <= 0;
        end
      end
    end
    else
    begin
      case (state_cs)
        GRAY:
        begin
          padding <= padding;
        end
        CROSSC:
        begin
          for (i =0; i < img_size_after; i++)
          begin
            if (cnt_conv == 0)
            begin
              padding[1][i+1] <= gray_img[0][i];
              padding[2][i+1] <= gray_img[1][i];
            end
            else if(cnt_conv + 1 < img_size_after)
            begin
              padding[cnt_conv+2][i+1] <= gray_img[cnt_conv+1][i];
            end
          end
        end
        IMGF:
        begin
          case (img_size_after)
            4:
            begin
              if (flag_imgfilter == 0)
              begin
                // Corners
                padding[5][0] <= gray_img[3][0];
                padding[5][5] <= gray_img[3][3];

                // Top and bottom rows
                for (j = 0; j < 6; j++)
                begin
                  if (j == 0 || j == 1)
                  begin
                    padding[0][j] <= gray_img[0][0];
                  end
                  else if (j == 4 || j == 5)
                  begin
                    padding[0][j] <= gray_img[0][3];
                  end
                  else
                  begin
                    padding[0][j] <= gray_img[0][j-1];
                  end
                end
                for (j = 1; j < 5; j++)
                begin
                  padding[5][j] <= gray_img[3][j-1];
                end
                // Left and right columns
                for (i = 1; i < 5; i++)
                begin
                  padding[i][0] <= gray_img[i-1][0];
                  padding[i][5] <= gray_img[i-1][3];
                end

                for (i = 0; i < img_size_after; i++)
                begin
                  padding[1][i+1] <= gray_img[0][i];
                  padding[2][i+1] <= gray_img[1][i];
                end
              end
              if (flag_imgfilter == 1)
              begin
                for (i = 0; i < img_size_after; i++)
                begin
                  if (flag_imgfilter == 1 && cnt_imgf + 1 < img_size_after)
                  begin
                    padding[cnt_imgf+2][i+1] <= gray_img[cnt_imgf+1][i];
                  end
                end
              end
            end
            8:
            begin
              if (flag_imgfilter == 0)
              begin
                // Top row
                for (j = 0; j < 10; j++)
                begin
                  if (j == 0 || j == 1)
                  begin
                    padding[0][j] <= gray_img[0][0];
                  end
                  else if (j == 8 || j == 9)
                  begin
                    padding[0][j] <= gray_img[0][7];
                  end
                  else
                  begin
                    padding[0][j] <= gray_img[0][j-1];
                  end
                end
                // Left column
                for (i = 1; i < 9; i++)
                begin
                  padding[i][0] <= gray_img[i-1][0];
                end
                padding[9][0] <= gray_img[7][0];
                // Right column
                for (i = 1; i < 9; i++)
                begin
                  padding[i][9] <= gray_img[i-1][7];
                end
                padding[9][9] <= gray_img[7][7];
                // Bottom row
                for (j = 1; j < 9; j++)
                begin
                  padding[9][j] <= gray_img[7][j-1];
                end
                for (i = 0; i < img_size_after; i++)
                begin
                  padding[1][i+1] <= gray_img[0][i];
                  padding[2][i+1] <= gray_img[1][i];
                end
              end
              if (flag_imgfilter == 1)
              begin
                for (i = 0; i < img_size_after; i++)
                begin
                  if (cnt_imgf + 1 < img_size_after)
                  begin
                    padding[cnt_imgf+2][i+1] <= gray_img[cnt_imgf+1][i];
                  end
                end
              end
            end
            16:
            begin
              if (flag_imgfilter == 0)
              begin
                // Top row
                for (j = 0; j < 18; j++)
                begin
                  if (j == 0 || j == 1)
                  begin
                    padding[0][j] <= gray_img[0][0];
                  end
                  else if (j == 16 || j == 17)
                  begin
                    padding[0][j] <= gray_img[0][15];
                  end
                  else
                  begin
                    padding[0][j] <= gray_img[0][j-1];
                  end
                end
                // Left column
                for (i = 1; i < 17; i++)
                begin
                  padding[i][0] <= gray_img[i-1][0];
                end
                padding[17][0] <= gray_img[15][0];
                // Right column
                for (i = 1; i < 17; i++)
                begin
                  padding[i][17] <= gray_img[i-1][15];
                end
                padding[17][17] <= gray_img[15][15];
                // Bottom row
                for (j = 1; j < 17; j++)
                begin
                  padding[17][j] <= gray_img[15][j-1];
                end
                for (i = 0; i < img_size_after; i++)
                begin
                  padding[1][i+1] <= gray_img[0][i];
                  padding[2][i+1] <= gray_img[1][i];
                end
              end
              if (flag_imgfilter == 1)
              begin
                for (i = 0; i < img_size_after; i++)
                begin
                  if (flag_imgfilter == 1 && cnt_imgf + 1 < img_size_after)
                  begin
                    padding[cnt_imgf+2][i+1] <= gray_img[cnt_imgf+1][i];
                  end
                end
              end
            end
          endcase
        end
        default:
        begin
          for (i = 0; i < 18; i++)
          begin
            for (j = 0; j < 18; j++)
            begin
              padding[i][j] <= 0;
            end
          end
        end
      endcase
    end
  end
  //==================================================================
  // ACTION REGISTER
  //==================================================================

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_act <= 0;
    end
    else
    begin
      case (state_cs)
        GRAY:
        begin
          if (cnt_graycode == num_data)
          begin
            cnt_act <= cnt_act + 1;
          end
        end
        NEG:
        begin
          if (cnt_neg_y == 15 && cnt_neg_x == 15)
          begin
            cnt_act <= cnt_act + 1;
          end
        end
        HORI:
        begin
          if (action_reg[cnt_act] == HORI)
          begin
            cnt_act <= cnt_act + 1;
          end
        end
        MAXP:
        begin
          if (img_size_after == 4 && action_reg[cnt_act] == MAXP)
          begin
            cnt_act <= cnt_act + 1;
          end
          else if (img_size_after == 8)
          begin
            if (cnt_max == 14)
            begin
              cnt_act <= cnt_act + 1;
            end
          end
          else
          begin
            if (cnt_max == 62)
            begin
              cnt_act <= cnt_act + 1;
            end
          end
        end
        IMGF:
        begin
          if (cnt_imgf + 1 == num_data)
          begin
            cnt_act <= cnt_act + 1;
          end
        end
        IDLE:
        begin
          cnt_act <= cnt_act;
        end
        default:
        begin
          cnt_act <= 0;
        end
      endcase
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_in <= 0;
    end
    else
    begin
      if (state_cs == INPUT && in_valid)
      begin
        cnt_in <= cnt_in + 1;
      end
      else
      begin
        cnt_in <= 0;
      end
    end
  end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_mod_y <= 0;
    end
    else
    begin
      if(state_cs == CROSSC)
      begin
        if (cnt_conv > 0)
        begin
          if (cnt_mod_x == 2)
          begin
            if(cnt_mod_y == 2)
              cnt_mod_y <= 0;
            else
            begin
              cnt_mod_y <= cnt_mod_y + 1;
            end
          end
        end
      end
      else
      begin
        cnt_mod_y <= 0;
      end
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_mod_x <= 0;
    end
    else
    begin
      case (state_cs)
        CROSSC:
        begin
          if (cnt_conv > 0 && cnt_mod_x == 2)
          begin
            cnt_mod_x <= 0;
          end
          else
          begin
            cnt_mod_x <= cnt_mod_x + 1;
          end
        end
        default:
        begin
          cnt_mod_x <= 0;
        end
      endcase
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_con_x <= 0;
    end
    else
    begin
      if (state_cs == CROSSC)
      begin
        if (cnt_conv > 0)
        begin
          if (cnt_mod_y == 2 && cnt_mod_x == 2)
          begin
            if(cnt_con_x + 1== img_size_after)
              cnt_con_x <= 0;
            else
              cnt_con_x <= cnt_con_x + 1;
          end
        end
      end
      else
      begin
        cnt_con_x <= 0;
      end
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_con_y <= 0;
    end
    else
    begin
      case (state_cs)
        CROSSC:
        begin
          if (cnt_conv > 0)
          begin
            if (cnt_con_x + 1== img_size_after && cnt_mod_y == 2 && cnt_mod_x == 2)
            begin
              cnt_con_y <= cnt_con_y + 1;
            end
          end
        end
        default:
        begin
          cnt_con_y <= 0;
        end
      endcase
    end
  end



  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_neg_x <= 0;
      cnt_neg_y <= 0;
    end
    else
    begin
      case(state_cs)
        NEG:
        begin
          if (cnt_neg_y == 15 && cnt_neg_x == 15)
          begin
            cnt_neg_y <= 0;
            cnt_neg_x <= cnt_neg_x + 1;
          end
          else if (cnt_neg_x == 15)
          begin
            cnt_neg_x <= 0;
            cnt_neg_y <= cnt_neg_y + 1;
          end
          else
          begin
            cnt_neg_x <= cnt_neg_x + 1;
          end
        end
        default:
        begin
          cnt_neg_x <= 0;
          cnt_neg_y <= 0;
        end
      endcase
    end
  end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_in2 <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid2)
          begin
            cnt_in2 <= cnt_in2 + 1;
          end
        end
        default:
        begin
          cnt_in2 <= 0;
        end
      endcase
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_graycode <= 0;
    end
    else
    begin
      if (state_cs == GRAY)
      begin
        cnt_graycode <= cnt_graycode + 1;
      end
      else
      begin
        cnt_graycode <= 0;
      end
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_max <= 0;
    end
    else
    begin
      if (state_cs == MAXP)
      begin
        if (cnt_max + 1 < num_data3)
        begin
          cnt_max <= cnt_max + 1;
        end
        else
        begin
          cnt_max <= 0;
        end
      end
      else
      begin
        cnt_max <= 0;
      end
    end
  end

  always @(posedge clk)
  begin
    case (state_cs)
      IMGF:
      begin
        flag_imgfilter <= 1;
      end
      default:
      begin
        flag_imgfilter <= 0;
      end
    endcase
  end


  always @(posedge clk)
  begin
    case (state_cs)
      IMGF:
      begin
        if (img_size_after == 4 && cnt_imgf == 15)
        begin
          flag2 <= 1;
        end
        else if (img_size_after == 8 && cnt_imgf == 63)
        begin
          flag2 <= 1;
        end
        else if (img_size_after == 16 && cnt_imgf == 255)
        begin
          flag2 <= 1;
        end
      end
      default:
      begin
        flag2 <= 0;
      end
    endcase
  end

  always @(posedge clk)
  begin
    cnt_imgf <= 0;
    case (state_cs)
      IMGF:
      begin
        if (flag_imgfilter == 1)
        begin
          cnt_imgf <= (cnt_imgf  + 1== num_data)? 0 : cnt_imgf + 1;
        end
      end
    endcase
  end

  always @(posedge clk)
  begin
    case (state_cs)
      CROSSC:
      begin
        cnt_conv <= cnt_conv + 1;
      end
      default:
      begin
        cnt_conv <= 0;
      end
    endcase
  end

  always @(posedge clk)
  begin
    cnt_out <= (state_cs == OUT) ? (cnt_out + 1):0;
  end

  always @(posedge clk)
  begin
    if (state_cs == CROSSC)
    begin
      case(1'b1)
        (cnt_cont_out >= 19):
        begin
          cnt_cont_out <= 0;
        end
        (cnt_conv > 1 && out_valid):
        begin
          cnt_cont_out <= cnt_cont_out + 1;
        end
      endcase
    end
    else
    begin
      cnt_cont_out <= 0;
    end
  end


  always @(posedge clk)
  begin
    case (state_cs)
      CROSSC:
      begin
        if (cnt_cont_out >= 19)
        begin
          cnt_out20 <= (cnt_out20 == num_data)? 0: (cnt_out20 + 1);
        end
      end
      default:
      begin
        cnt_out20 <= 0;
      end
    endcase
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_gray_x <= 0;
      cnt_gray_y <= 0;
    end
    else
    begin
      case (state_cs)
        INPUT:
        begin
          if (in_valid && grayscale == 0 && cnt_in > 0)
          begin
            cnt_gray_x <= (cnt_gray_x + 1 == img_size_after) ? 0 : cnt_gray_x + 1;
            if (cnt_gray_x + 1 == img_size_after)
            begin
              cnt_gray_y <= (cnt_gray_y + 1 == img_size_after) ? 0 : cnt_gray_y + 1;
            end
          end
        end
        GRAY:
        begin
          if (cnt_graycode > 1)
          begin
            cnt_gray_x <= (cnt_gray_x + 1 == img_size_after) ? 0 : cnt_gray_x + 1;
          end
          else
          begin
            cnt_gray_x <= 0;
          end
          if (cnt_gray_x + 1 == img_size_after)
          begin
            cnt_gray_y <= (cnt_gray_y + 1 == img_size_after) ? 0 : cnt_gray_y + 1;
          end
        end
        default:
        begin
          cnt_gray_x <= 0;
          cnt_gray_y <= 0;
        end
      endcase
    end
  end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      cnt_mA <= 0;
    end
    else
    begin
      if(state_cs == INPUT)
      begin
        if (grayscale == 0 && cnt_in > 0)
        begin
          cnt_mA <= cnt_mA + 1;
        end
      end
      else
      begin
        cnt_mA <= 0;
      end
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      m_A <= 0;
      m_Wen <= 1; // read
      m_D   <= 0;
    end
    else
    begin
      if(state_cs == INPUT)
      begin
        if (grayscale == 0 && cnt_in > 0 && cnt_mA < 256)
        begin
          m_A <= cnt_mA;
          m_Wen <= 0; // write
          m_D   <= {gray_max, gray_ave, gray_weighted};
        end
        else
        begin
          m_Wen <= 1;
        end
      end
      else if(state_cs == GRAY)
      begin
        case (img_size_after)
          4, 8, 16:
          begin
            m_A <= cnt_graycode;
            m_Wen <= 1;
          end
        endcase
      end
      else
      begin
        m_Wen <= 1;
      end
    end
  end


  //==================================================================
  // OUTPUT
  //==================================================================



  always@(*)
  begin
    cnt_cont_out_x <= (cnt_cont_out == 19) ? 19 : 18 - cnt_cont_out;
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      out_valid <= 0;
    end
    else
    begin
      case (state_cs)
        CROSSC:
        begin
          if (cnt_conv > num_data * 20 + 11)
          begin
            out_valid <= 0;
          end
          else if (cnt_conv > 11)
          begin
            out_valid <= 1;
          end
          else
          begin
            out_valid <= 0;
          end
        end
        OUT:
        begin
          out_valid <= 1;
        end
        default:
        begin
          out_valid <= 0;
        end
      endcase
    end
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      out_value <= 0;
    end
    else
    begin
      case (state_cs)
        CROSSC:
        begin
          if (cnt_conv > num_data * 20 + 11)
          begin
            out_value <= 0;
          end
          else if (cnt_conv > 11)
          begin
            out_value <= gray_img[cnt_out20/img_size_after][cnt_out20%img_size_after][cnt_cont_out_x];
          end
          else
          begin
            out_value <= 0;
          end
        end
        OUT:
        begin
          out_value <= padding[cnt_out][cnt_out];
        end
        default:
        begin
          out_value <= 0;
        end
      endcase
    end
  end

endmodule

module comp (
    in1,
    in2,
    outlarger,
    outsmall
  );
  input [7:0] in1, in2;
  output reg [7:0] outlarger, outsmall;  //small

  always @(*)
  begin
    {outlarger, outsmall} <=(in1 > in2) ? {in1, in2} : {in2, in1};
  end
endmodule

module sorting #(
    parameter BITS = 8,
    parameter NUM_COMP = 9
  ) (
    in,
    out
  );

  input [BITS*NUM_COMP-1:
         0] in;
  output reg [BITS*NUM_COMP-1:
              0] out;

  integer i, j;

  reg [BITS-1:
       0] temp;
  reg [BITS-1:
       0] array[1:
                NUM_COMP];

  always @(*)
  begin
    for (i = 0; i < NUM_COMP; i++)
    begin
      array[i+1] = in[i*BITS+:BITS];
    end

    for (i = NUM_COMP; i > 0; i = i - 1)
    begin
      for (j = 1; j < i; j++)
      begin
        if (array[j] < array[j+1])
        begin
          temp = array[j];
          array[j] = array[j+1];
          array[j+1] = temp;
        end
      end
    end

    for (i = 0; i < NUM_COMP; i++)
    begin
      out[i*BITS+:BITS] = array[i+1];
    end
  end

endmodule
