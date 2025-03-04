module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
  input clk;
  input rst_n;
  input in_valid;
  input [17:0] in_row;
  input [11:0] in_kernel;
  input out_idle;
  output reg handshake_sready;
  output reg [29:0] handshake_din;
  // You can use the the custom flag ports for your design
  input flag_handshake_to_clk1;
  output flag_clk1_to_handshake;

  input fifo_empty;
  input [7:0] fifo_rdata;
  output fifo_rinc;
  output reg out_valid;
  output reg [7:0] out_data;
  // You can use the the custom flag ports for your design
  output flag_clk1_to_fifo;
  input flag_fifo_to_clk1;

  //------------------------------------------//
  //                 Parameter           		  		   
  //-----------------------------------------//


  integer i, j, k;


  //------------------------------------------//
  //               Reg and Wire           		  		   
  //-----------------------------------------//

  reg [2:0] cnt;
  reg [3:0] in_cnt;
  reg [7:0] out_cnt;
  reg [17:0] in_row_reg[0:5];
  reg [11:0] in_kernel_reg[0:5];

  reg d_flag1, d_flag2, d_flag3;
  reg out_ok_lag1;
  reg out_ok_lag2;
  reg out_valid_q;

  reg finish_flag;


  //------------------------------------------//
  //                  Design           		  		   
  //-----------------------------------------//


  //------------------------------------------//
  //                  INPUT           		  		   
  //-----------------------------------------//
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt <= 0;
    end else begin
      if (out_cnt == 149) begin
        cnt <= 0;
      end else if (cnt == 5) begin
        cnt <= cnt;
      end else if (in_valid) begin
        cnt <= cnt + 1'b1;
      end
    end
  end

  // collect input row
  // collect input kernel
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 6; i = i + 1) begin
        in_row_reg[i] <= 0;
        in_kernel_reg[i] <= 0;
      end
    end else begin
      if (in_valid) begin
        in_row_reg[cnt] <= in_row;
        in_kernel_reg[cnt] <= in_kernel;
      end
    end
  end


  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      handshake_din <= 0;
    end else begin
      if (cnt != 0 && out_idle) begin
        handshake_din <= {in_row_reg[in_cnt], in_kernel_reg[in_cnt]};
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_cnt <= 0;
    end else begin
      if (out_cnt == 149) begin
        in_cnt <= 0;
      end else if (in_cnt == 5) begin
        in_cnt <= in_cnt;
      end else if (cnt != 0 && out_idle) begin
        in_cnt <= in_cnt + 1'b1;
      end
    end
  end


  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      d_flag1 <= 1'b0;
    end else begin
      if (out_cnt == 149) begin
        d_flag1 <= 1'b0;
      end else if (in_cnt == 5 && out_idle) begin
        d_flag1 <= 1'b1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      d_flag2 <= 1'b0;
    end else begin
      if (out_cnt == 149) begin
        d_flag2 <= 1'b0;
      end else if (d_flag1 && out_idle) begin
        d_flag2 <= 1'b1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      d_flag3 <= 1'b0;
    end else begin
      if (out_cnt == 149) begin
        d_flag3 <= 1'b0;
      end else if (d_flag2 && out_idle) begin
        d_flag3 <= 1'b1;
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      handshake_sready <= 1'b0;
    end else begin
      if (d_flag3) begin
        handshake_sready <= 1'b0;
      end else if (cnt != 0 && out_idle && !d_flag2) begin
        handshake_sready <= 1'b1;
      end
    end
  end

  //------------------------------------------//
  //                   OUTPUT           		  		   
  //-----------------------------------------//

  always @(*) begin
    out_valid_q = (fifo_empty) ? 1'b0 : 1'b1;
  end
  assign fifo_rinc = out_valid_q;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      out_ok_lag1 <= 1'b0;
    end else begin
      out_ok_lag1 <= out_valid_q;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      out_ok_lag2 <= 1'b0;
    end else begin
      out_ok_lag2 <= out_ok_lag1;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      out_data  <= 0;
    end else begin
      if (out_valid && finish_flag) begin
        out_valid <= 1'b0;
        out_data  <= 0;
      end else if (out_ok_lag2) begin
        out_valid <= 1'b1;
        out_data  <= fifo_rdata;
      end else begin
        out_valid <= 1'b0;
        out_data  <= 0;
      end
    end
  end

  // always @(posedge clk, negedge rst_n) begin
  //   if (!rst_n) begin
  //     out_valid <= 1'b0;
  //   end else begin
  //     if (out_valid && finish_flag) begin
  //       out_valid <= 1'b0;
  //     end else begin
  //       out_valid <= out_ok_lag2;
  //     end
  //   end
  // end

  // reg [7:0] fifo_rdata_reg;

  // always @(posedge clk, negedge rst_n) begin
  //   if (!rst_n) begin
  //     fifo_rdata_reg <= 0;
  //   end else begin
  //     fifo_rdata_reg <= fifo_rdata;
  //   end
  // end

  // always @(*) begin
  //   if (out_valid) begin
  //     out_data = fifo_rdata_reg;
  //   end else begin
  //     out_data = 0;
  //   end
  // end


  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      finish_flag <= 1'b0;
    end else begin
      if (out_cnt == 149) begin
        finish_flag <= 1'b1;
      end else begin
        finish_flag <= 1'b0;
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      out_cnt <= 0;
    end else begin
      if (out_valid && finish_flag) begin
        out_cnt <= 0;
      end else if (out_cnt == 149) begin
        out_cnt <= out_cnt;
      end else if (out_ok_lag2) begin
        out_cnt <= out_cnt + 1'b1;
      end
    end
  end



endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

  input clk;
  input rst_n;
  input in_valid;
  input fifo_full;
  input [29:0] in_data;
  output reg out_valid;
  output reg [7:0] out_data;
  output reg busy;

  // You can use the the custom flag ports for your design
  input flag_handshake_to_clk2;
  output flag_clk2_to_handshake;

  input flag_fifo_to_clk2;
  output flag_clk2_to_fifo;


  //------------------------------------------//
  //                 Parameter           		  		   
  //-----------------------------------------//

  integer i, j, k;

  //------------------------------------------//
  //               Reg and Wire           		  		   
  //-----------------------------------------//

  reg [17:0] in_row_reg[0:5];
  reg [11:0] in_kernel_reg[0:5];
  reg [2:0] in_cnt;
  reg [7:0] out_cnt;

  reg in_flag;  // in_data_valid_clk2
  reg out_flag;

  reg ok_flag1;
  reg ok_flag2;

  reg start_out_flag;


  reg [2:0] kernel_cnt;
  reg [4:0] k_cnt;
  reg [2:0] r_xcnt;
  reg [2:0] r_ycnt;

  // reg [4:0] col_cnt;

  // reg [2:0] row_cnt;

  reg [2:0] m00, m01, m10, m11;

  //------------------------------------------//
  //                   Design          		  		   
  //-----------------------------------------//

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      in_flag <= 1'b0;
    end else begin
      in_flag <= (in_valid) ? 1'b1 : 1'b0;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      in_cnt <= 0;
    end else begin
      if (ok_flag2) begin
        in_cnt <= 0;
      end else if (in_cnt == 5) begin
        in_cnt <= in_cnt;
      end else if (!in_flag && in_valid) begin
        in_cnt <= in_cnt + 1'b1;
      end
    end
  end

  //------------------------------------------//
  //                   Input          		  		   
  //-----------------------------------------//

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 6; i = i + 1) begin
        in_row_reg[i] <= 0;
        in_kernel_reg[i] <= 0;
      end
    end else begin
      if (in_valid && !in_flag) begin
        in_row_reg[in_cnt] <= in_data[12+:18];
        in_kernel_reg[in_cnt] <= in_data[0+:12];
      end
    end
  end


  //------------------------------------------//
  //                   Output          		  		   
  //-----------------------------------------//

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      out_flag <= 1'b0;
    end else begin
      if (ok_flag2) begin
        out_flag <= 1'b0;
      end else if (in_cnt == 5 && busy) begin
        out_flag <= 1'b1;
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ok_flag1 <= 1'b0;
    end else begin
      if (ok_flag2) begin
        ok_flag1 <= 1'b0;
      end else if (!fifo_full && out_cnt == 149) begin
        ok_flag1 <= 1'b1;
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      ok_flag2 <= 1'b0;
    end else begin
      ok_flag2 <= (ok_flag1 && !fifo_full) ? 1'b1 : 1'b0;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      busy <= 1'b0;
    end else begin
      busy <= (in_valid && !in_flag) ? 1'b1 : 1'b0;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      start_out_flag <= 1'b0;
    end else begin
      if (ok_flag2) begin
        start_out_flag <= 1'b0;
      end else if (out_flag && busy) begin
        start_out_flag <= 1'b1;
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      out_cnt <= 0;
    end else begin
      if (ok_flag2) begin
        out_cnt <= 0;
      end else if (out_cnt == 149) begin
        out_cnt <= out_cnt;
      end else if (start_out_flag && !fifo_full) begin
        out_cnt <= out_cnt + 1'b1;
      end
    end
  end


  always @(*) begin
    out_valid = 1'b0;
    if (ok_flag1 && !fifo_full) begin
      out_valid = 1'b0;
    end else if (start_out_flag && !fifo_full) begin
      out_valid = 1'b1;
    end
  end

  always @(*) begin
    out_data = 0;
    if (start_out_flag && !fifo_full) begin
      out_data = (in_kernel_reg[kernel_cnt][0+:3] * m00) + 
									(in_kernel_reg[kernel_cnt][3+:3] * m01) + 
									(in_kernel_reg[kernel_cnt][6+:3] * m10) + 
									(in_kernel_reg[kernel_cnt][9+:3] * m11);
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      k_cnt <= 0;
      kernel_cnt <= 0;
    end else begin
      if (ok_flag2) begin
        k_cnt <= 0;
        kernel_cnt <= 0;
      end else if (start_out_flag && !fifo_full) begin
        if (k_cnt == 24) begin
          k_cnt <= 0;
          kernel_cnt <= kernel_cnt + 1'b1;
        end else begin
          k_cnt <= k_cnt + 1'b1;
        end
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      r_xcnt <= 0;
      r_ycnt <= 0;
    end else begin
      if (ok_flag2) begin
        r_xcnt <= 0;
        r_ycnt <= 0;
      end else if (start_out_flag && !fifo_full) begin
        if (r_ycnt == 4 && r_xcnt == 4) begin
          r_xcnt <= 0;
          r_ycnt <= 0;
        end else if (r_xcnt == 4) begin
          r_xcnt <= 0;
          r_ycnt <= r_ycnt + 1'b1;
        end else begin
          r_xcnt <= r_xcnt + 1'b1;
        end
      end
    end
  end

  always @(*) begin
    // col_cnt = r_xcnt * 3;
    m00 = in_row_reg[r_ycnt][(r_xcnt*3)+:3];
    m01 = in_row_reg[r_ycnt][((r_xcnt*3)+3)+:3];
    m10 = in_row_reg[r_ycnt+1][(r_xcnt*3)+:3];
    m11 = in_row_reg[r_ycnt+1][(r_xcnt*3+3)+:3];
  end

endmodule
