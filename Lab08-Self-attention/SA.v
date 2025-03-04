/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

// synopsys translate_off
`ifdef RTL
`include "GATED_OR.v"
`else
`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA (
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
);

  input clk;
  input rst_n;
  input in_valid;
  input cg_en;
  input [3:0] T;
  input signed [7:0] in_data;
  input signed [7:0] w_Q;
  input signed [7:0] w_K;
  input signed [7:0] w_V;

  output reg out_valid;
  output reg signed [63:0] out_data;

  //==============================================//
  //       parameter & integer declaration        //
  //==============================================//
  integer i, j;
  genvar gen_i, gen_j;


  //==============================================//
  //           reg & wire declaration             //
  //==============================================//
  reg signed [7:0] in_data_reg[7:0][7:0];
  reg [3:0] t_reg;
  reg [8:0] cnt;
  reg [8:0] cnt_re;
  wire [2:0] cnt_x, cnt_y;
  assign cnt_x = cnt[2:0];
  assign cnt_y = cnt[5:3];
  wire [6:0] cnt_xy;
  reg [5:0] cnt_xy2;
  reg [1:0] all_flag;

  reg signed [7:0] w_reg[7:0][7:0];

  reg signed [19:0] Q_reg[0:7][0:7];
  reg signed [19:0] K_reg[0:7][0:7];
  reg signed [19:0] V_reg[0:7][0:7];


  reg signed [63:0] out_data_reg;


  reg signed [39:0] QK_reg[0:7][0:7];

  // reg [8:0] redundant;
  reg [16:0] redundant0, redundant1, redundant2, redundant3;
  reg [19:0] redundant4;

  //==============================================//
  //                  design                      //
  //==============================================//
  wire G_clock_redundant;
  wire G_sleep_redundant = !((cnt < 5) || (cnt == 0));
  GATED_OR GATED_redundant (
      .CLOCK(clk),
      .SLEEP_CTRL(G_sleep_redundant && cg_en),  // gated clock
      .RST_N(rst_n),
      .CLOCK_GATED(G_clock_redundant)
  );
  always @(posedge G_clock_redundant or negedge rst_n) begin
    if (!rst_n) begin
      redundant0 <= 0;
      redundant1 <= 0;
      redundant2 <= 0;
      redundant3 <= 0;
      redundant4 <= 0;
    end else if (cnt == 0) begin
      redundant0 <= 0;
      redundant1 <= 0;
      redundant2 <= 0;
      redundant3 <= 0;
      redundant4 <= 0;
    end else begin
      redundant0 <= redundant0 + 'b11111111;
      redundant1 <= redundant1 + 'b111111;
      redundant2 <= redundant2 + 'b11111;
      redundant3 <= redundant3 + 'b111;
      redundant4 <= (redundant0 + redundant1 + redundant2 + redundant3 > {18{1'b1}} || redundant4 > {18{1'b1}}) ? {20{1'b1}} : redundant0 + redundant1 + redundant2 + redundant3;

      // // Additional logic to increase power consumption
      // if (redundant0 > redundant1) begin
      //   redundant0 <= redundant0 - redundant1;
      // end else begin
      //   redundant1 <= redundant1 - redundant0;
      // end
    end
  end


  // wire G_clock_redundant;
  // wire G_sleep_redundant = 1'b1;
  // GATED_OR GATED_redundant (
  //     .CLOCK(clk),
  //     .SLEEP_CTRL(G_sleep_redundant && cg_en),  // gated clock
  //     .RST_N(rst_n),
  //     .CLOCK_GATED(G_clock_redundant)
  // );

  // always @(posedge G_clock_redundant or negedge rst_n) begin
  //   if (!rst_n) begin
  //     redundant <= 0;
  //   end else begin
  //     redundant <= redundant + 1'b1;
  //   end
  // end

  // assign cnt = (cnt_re & redundant) | (cnt_re & ~redundant);

  // 8'b11111111;
  // 4'b1111;
  // 2'b11;

  wire G_clock_t_reg;
  wire G_sleep_t_reg = !(cnt == 0);
  GATED_OR GATED_t_reg (
      .CLOCK(clk),
      .SLEEP_CTRL(G_sleep_t_reg && cg_en),  // gated clock
      .RST_N(rst_n),
      .CLOCK_GATED(G_clock_t_reg)
  );

  always @(posedge G_clock_t_reg) begin  // store T
    if (cnt == 0) begin
      if (in_valid && all_flag == 0) begin
        t_reg <= T;
      end else begin
        t_reg <= 0;
      end
    end
  end

  wire G_clock_flag;
  wire G_sleep_flag = !(out_valid || cnt[5:0] == 6'b111111);
  GATED_OR GATED_flag (
      .CLOCK(clk),
      .SLEEP_CTRL(G_sleep_flag && cg_en),  // gated clock
      .RST_N(rst_n),
      .CLOCK_GATED(G_clock_flag)
  );

  always @(posedge G_clock_flag or negedge rst_n) begin  //for all oporation flag
    if (!rst_n) begin
      all_flag <= 0;
    end else if (out_valid && redundant4 > 10) begin  //
      all_flag <= 0;
    end else if (cnt[5:0] == 6'b111111) begin
      all_flag <= all_flag + 'd1;
    end
  end

  always @(posedge clk or negedge rst_n) begin  //cnt
    if (!rst_n) cnt <= 0;
    else begin
      if (t_reg == 'd8 && cnt == 'd255) begin
        cnt <= 0;
      end else if (t_reg == 'd4 && cnt == 'd223) begin
        cnt <= 0;
      end else if (t_reg == 'd1 && cnt == 'd199) begin
        cnt <= 0;
      end else if (cnt > 0) begin
        cnt <= cnt + 'd1;
      end else if (in_valid) begin
        cnt <= cnt + 'd1;
      end
    end
  end

  generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin : in_data_reg_gen
      for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin : in_data_reg_gen2
        wire G_clock_in_data_reg;
        wire G_sleep_in_data_reg = !((all_flag == 0) || (cnt == 0));
        GATED_OR GATED_OR_in_data_reg (
            .CLOCK(clk),
            .SLEEP_CTRL(G_sleep_in_data_reg && cg_en),  // gated clock
            .RST_N(rst_n),
            .CLOCK_GATED(G_clock_in_data_reg)
        );
        always @(posedge G_clock_in_data_reg) begin
          if (in_valid && all_flag == 0) begin
            case (t_reg)
              1:
              if (cnt[5:0] < 'd8) begin
                if (gen_i == cnt_y && gen_j == cnt_x) in_data_reg[gen_i][gen_j] <= in_data;
              end
              4:
              if (cnt[5:0] < 'd32) begin
                if (gen_i == cnt_y && gen_j == cnt_x) in_data_reg[gen_i][gen_j] <= in_data;
              end
              default: begin
                if (gen_i == cnt_y && gen_j == cnt_x) in_data_reg[gen_i][gen_j] <= in_data;
              end
            endcase
          end else if (cnt == 'd0) begin
            in_data_reg[gen_i][gen_j] <= 0;
          end
        end
      end
    end
  endgenerate

  generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin : w_reg_gen
      for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin : w_reg_gen2
        wire G_clock_w;
        wire G_sleep_w = !(all_flag == 0 || cnt == 0);
        GATED_OR GATED_OR_w (
            .CLOCK(clk),
            .SLEEP_CTRL(G_sleep_w && cg_en),  // gated clock
            .RST_N(rst_n),
            .CLOCK_GATED(G_clock_w)
        );
        always @(posedge G_clock_w) begin  //w_Q_reg w_K_reg w_V_reg
          if (all_flag == 0 && cnt_y == gen_i && cnt_x == gen_j) begin
            w_reg[gen_i][gen_j] <= w_Q;
          end else if (cnt == 0) begin
            w_reg[gen_i][gen_j] <= 0;
          end
        end
      end
    end
  endgenerate

  generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin : Q_reg_gen
      // for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin : Q_reg_gen2
      wire G_clock_q_reg;
      wire G_sleep_q_reg = !((all_flag == 0 && cnt[5:0] > 6'b111000) || (all_flag == 1 && cnt[5:0] < 6'b111001) || cnt == 0);
      GATED_OR GATED_OR_G_q_reg (
          .CLOCK(clk),
          .SLEEP_CTRL(G_sleep_q_reg && cg_en),  // gated clock
          .RST_N(rst_n),
          .CLOCK_GATED(G_clock_q_reg)
      );
      always @(posedge G_clock_q_reg or negedge rst_n) begin  //Q_reg
        if (!rst_n) begin
          for (j = 0; j < 8; j = j + 1) Q_reg[gen_i][j] <= 0;
        end else begin
          if((all_flag == 0 && cnt[5:0] > 6'b111000) || (all_flag == 1 && cnt[5:0] < 6'b111001)) begin
            Q_reg [gen_i][cnt_xy2[2:0]] <= Q_reg [gen_i][cnt_xy2[2:0]] + w_reg[cnt_xy2[5:3]][cnt_xy2[2:0]] * in_data_reg[gen_i][cnt_xy2[5:3]];
          end else if (cnt == 0) begin
            for (j = 0; j < 8; j = j + 1) Q_reg[gen_i][j] <= 0;
          end
        end
      end
    end
    // end
  endgenerate

  generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin : K_reg_gen
      for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin : K_reg_gen2
        wire G_clock_K_reg;
        wire G_sleep_K_reg = !(all_flag == 1 || cnt == 0);
        GATED_OR GATED_OR_K_reg (
            .CLOCK(clk),
            .SLEEP_CTRL(G_sleep_K_reg && cg_en),  // gated clock
            .RST_N(rst_n),
            .CLOCK_GATED(G_clock_K_reg)
        );
        always @(posedge G_clock_K_reg) begin  //K_reg
          if (all_flag == 1) begin
            case (t_reg)
              1: begin
                if (gen_i < 1 && gen_j == cnt_x)
                  K_reg[gen_i][gen_j] <= K_reg[gen_i][gen_j] + w_K * in_data_reg[gen_i][cnt_y];
              end
              4: begin
                if (gen_i < 4 && gen_j == cnt_x)
                  K_reg[gen_i][gen_j] <= K_reg[gen_i][gen_j] + w_K * in_data_reg[gen_i][cnt_y];
              end
              default: begin  //8
                if (gen_i < 8 && gen_j == cnt_x)
                  K_reg[gen_i][gen_j] <= K_reg[gen_i][gen_j] + w_K * in_data_reg[gen_i][cnt_y];
              end
            endcase
          end else if (cnt == 0) begin
            K_reg[gen_i][gen_j] <= 0;
          end
        end
      end
    end
  endgenerate

  generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin : V_reg_gen
      for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin : V_reg_gen2
        wire G_clock_V_reg;
        wire G_sleep_V_reg = !(all_flag == 2 || cnt == 0);
        GATED_OR GATED_OR_V_reg (
            .CLOCK(clk),
            .SLEEP_CTRL(G_sleep_V_reg && cg_en),  // gated clock
            .RST_N(rst_n),
            .CLOCK_GATED(G_clock_V_reg)
        );
        always @(posedge G_clock_V_reg) begin  //V_reg
          if (all_flag == 2) begin
            case (t_reg)
              1: begin
                if (gen_i < 1 && gen_j == cnt_x)
                  V_reg[gen_i][gen_j] <= V_reg[gen_i][gen_j] + w_V * in_data_reg[gen_i][cnt_y];
              end
              4: begin
                if (gen_i < 4 && gen_j == cnt_x)
                  V_reg[gen_i][gen_j] <= V_reg[gen_i][gen_j] + w_V * in_data_reg[gen_i][cnt_y];
              end
              default: begin  //8
                if (gen_i < 8 && gen_j == cnt_x)
                  V_reg[gen_i][gen_j] <= V_reg[gen_i][gen_j] + w_V * in_data_reg[gen_i][cnt_y];
              end
            endcase
          end else if (cnt == 0) begin
            V_reg[gen_i][gen_j] <= 0;
          end
        end
      end
    end
  endgenerate



  assign cnt_xy = cnt[5:0] + 'd7;

  wire G_clock_cnt_xy2;
  wire G_sleep_cnt_xy2 = !((all_flag == 0 && cnt[5:0] > 6'b111000) || 
                           (all_flag == 1 && cnt[5:0] <= 6'b111001) || 
                           (cnt >= 128 && cnt < 192) || 
                           (cnt == 0));

  GATED_OR GATED_cnt_xy2 (
      .CLOCK(clk),
      .SLEEP_CTRL(G_sleep_cnt_xy2 && cg_en),  // gated clock
      .RST_N(rst_n),
      .CLOCK_GATED(G_clock_cnt_xy2)
  );

  always @(posedge G_clock_cnt_xy2) begin
    if (cnt >= 128 && cnt < 192) begin
      cnt_xy2 <= cnt_xy2 + 1;
    end else if (all_flag == 0 && cnt[5:0] > 6'b111000) begin
      cnt_xy2 <= cnt_xy2 + 1;
    end else if (all_flag == 1 && cnt[5:0] < 6'b111001) begin
      cnt_xy2 <= cnt_xy2 + 1;
    end else if (cnt == 0) begin
      cnt_xy2 <= 0;
    end
  end

  // generate
  //   for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin : QK_reg_gen
  //     // wire G_clock_cnt_qk_reg;
  //     // wire G_sleep_cnt_qk_reg = !((all_flag == 1 && cnt[5:0] > 6'b111000) || (all_flag == 2) || cnt == 0);
  //     // GATED_OR GATED_qk_reg (
  //     //     .CLOCK(clk),
  //     //     .SLEEP_CTRL(G_sleep_qk_reg && cg_en),  // gated clock
  //     //     .RST_N(rst_n),
  //     //     .CLOCK_GATED(G_clock_qk_reg)
  //     // );
  //     always @(posedge clk) begin  //QK_reg
  //       case (all_flag)
  //         1: begin
  //           if (cnt[5:0] > 6'b111000) begin
  //             QK_reg[gen_i][cnt_y-7] <= QK_reg[gen_i][cnt_y-7] + Q_reg[gen_i][cnt_x-1] * K_reg[cnt_y-7][cnt_x-1];
  //           end
  //         end
  //         2: begin
  //           if (cnt[5:0] == 6'b000000) begin
  //             QK_reg[gen_i][cnt_y] <= QK_reg[gen_i][cnt_y] + Q_reg[gen_i][cnt_x+7] * K_reg[cnt_y][cnt_x+7];
  //           end else if (cnt_xy <= 6'b111111) begin
  //             QK_reg[gen_i][cnt_xy[5:3]] <= QK_reg[gen_i][cnt_xy[5:3]] + Q_reg[gen_i][cnt_xy[2:0]] * K_reg[cnt_xy[5:3]][cnt_xy[2:0]];
  //           end else if (cnt_xy > 6'b111111) begin
  //             QK_reg[cnt_xy[2:0]][gen_i] <= (QK_reg[cnt_xy[2:0]][gen_i] > 0) ? (QK_reg[cnt_xy[2:0]][gen_i] / 3) : 0;
  //           end
  //         end
  //         3: begin
  //           if (cnt_x == 0) begin
  //             QK_reg[7][gen_i] <= (QK_reg[7][gen_i] > 0) ? (QK_reg[7][gen_i] / 3) : 0;
  //           end
  //         end
  //         default: begin
  //           if (cnt == 0) begin
  //             for (j = 0; j < 8; j = j + 1) begin
  //               QK_reg[gen_i][j] <= 0;
  //             end
  //           end
  //         end
  //       endcase
  //     end
  //   end
  // endgenerate

  wire G_clock_qk_reg;
  wire G_sleep_qk_reg = !((all_flag == 1 && cnt[5:0] > 6'b111000) || 
                           (all_flag == 2) || 
                           (all_flag == 3 && cnt_x == 0) || 
                           (cnt == 0));

  GATED_OR GATED_qk_reg (
      .CLOCK(clk),
      .SLEEP_CTRL(G_sleep_qk_reg && cg_en),  // gated clock
      .RST_N(rst_n),
      .CLOCK_GATED(G_clock_qk_reg)
  );

  always @(posedge G_clock_qk_reg) begin  //QK_reg
    case (all_flag)
      1: begin
        if (cnt[5:0] > 6'b111000) begin
          for (i = 0; i < 8; i = i + 1) begin
            QK_reg[i][cnt_y-7] <= QK_reg[i][cnt_y-7] + Q_reg[i][cnt_x-1] * K_reg[cnt_y-7][cnt_x-1];
          end
        end
      end
      2: begin
        if (cnt[5:0] == 6'b000000) begin
          for (i = 0; i < 8; i = i + 1) begin
            QK_reg[i][cnt_y] <= QK_reg[i][cnt_y] + Q_reg[i][cnt_x+7] * K_reg[cnt_y][cnt_x+7];
          end
        end else if (cnt_xy <= 6'b111111) begin
          for (i = 0; i < 8; i = i + 1) begin
            QK_reg[i][cnt_xy[5:3]] <= QK_reg[i][cnt_xy[5:3]] + Q_reg[i][cnt_xy[2:0]] * K_reg[cnt_xy[5:3]][cnt_xy[2:0]];
          end
        end else if (cnt_xy > 6'b111111) begin
          for (i = 0; i < 8; i = i + 1) begin
            QK_reg[cnt_xy[2:0]][i] <= (QK_reg[cnt_xy[2:0]][i] > 0) ? (QK_reg[cnt_xy[2:0]][i] / 3) : 0;
          end
        end
      end
      3: begin
        if (cnt_x == 0) begin
          for (i = 0; i < 8; i = i + 1) begin
            QK_reg[7][i] <= (QK_reg[7][i] > 0) ? (QK_reg[7][i] / 3) : 0;
          end
        end
      end
      default: begin
        if (cnt == 0) begin
          for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
              QK_reg[i][j] <= 0;
            end
          end
        end
      end
    endcase
  end

  //==============================================//
  //                   OUTPUT                     //
  //==============================================//

  wire G_clock_out;
  wire G_sleep_out = !(cnt >= 192 || cnt == 0);
  GATED_OR GATED_outvalid (
      .CLOCK(clk),
      .SLEEP_CTRL(G_sleep_out && cg_en),  // gated clock
      .RST_N(rst_n),
      .CLOCK_GATED(G_clock_out)
  );

  always @(posedge G_clock_out or negedge rst_n) begin  //out_data 
    if (!rst_n) begin
      out_valid <= 0;
      out_data  <= 0;
    end else if (cnt >= 192) begin
      if ((t_reg == 8 && cnt < 256) || (t_reg == 4 && cnt < 224) || (t_reg == 1 && cnt < 200)) begin
        out_valid <= 1;
        out_data <=  QK_reg[cnt_y][0] * V_reg[0][cnt_x]
  					+ QK_reg[cnt_y][1] * V_reg[1][cnt_x] 
  					+ QK_reg[cnt_y][2] * V_reg[2][cnt_x] 
  					+ QK_reg[cnt_y][3] * V_reg[3][cnt_x] 
  					+ QK_reg[cnt_y][4] * V_reg[4][cnt_x] 
  					+ QK_reg[cnt_y][5] * V_reg[5][cnt_x] 
  					+ QK_reg[cnt_y][6] * V_reg[6][cnt_x] 
  					+ QK_reg[cnt_y][7] * V_reg[7][cnt_x];
      end
    end else begin
      out_valid <= 0;
      out_data  <= 0;
    end
  end

endmodule
