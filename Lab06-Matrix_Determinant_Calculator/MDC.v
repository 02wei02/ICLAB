//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC (
    // Input signals
    clk,
    rst_n,
    in_valid,
    in_data,
    in_mode,
    // Output signals
    out_valid,
    out_data
);

  // ===============================================================
  // Input & Output Declaration
  // ===============================================================
  input clk, rst_n, in_valid;
  input [8:0] in_mode;
  input [14:0] in_data;

  output reg out_valid;
  output reg [206:0] out_data;

  // ===============================================================
  // PARAMETER
  // ===============================================================

  parameter M2 = 2'b00;
  parameter M3 = 2'b01;
  parameter M4 = 2'b10;
  integer i, j, k;

  // ===============================================================
  // REG
  // ===============================================================

  reg [14:0] in_data_reg;
  reg [8:0] in_mode_reg;

  reg [4:0] cnt_in_valid;
  // reg out_valid_cs;
  reg [10:0] out_ham11;
  reg [4:0] out_ham5;
  reg signed [10:0] out_in_reg[0:15];  // corrected data
  reg [4:0] out_mode;  // corrected mode

  reg signed [22:0] out_matrix2x2[0:12];
  reg signed [50:0] out_matrix3x3[0:3];
  reg signed [206:0] out_matrix4x4;

  reg [1:0] mode;  // matrix mode 0, 1, 2
  reg signed [10:0] in_matrix[0:3];  // 11 bits
  reg signed [22:0] out_matrix;  // 23 bits
  reg [3:0] cnt2;  // counter for 2x2 matrix
  reg [1:0] cnt3;  // counter for 3x3 matrix
  reg [1:0] cnt_mat3;  // counter for 3x3 matrix TO PUT INFO
  reg [3:0] cnt_det3;  // counter for 3x3 matrix TO DETERMINANT

  reg [3:0] cnt_coeff3;  // counter for coefficient calculation
  wire [3:0] cnt_det;  // counter for 2x2 determinant calculation
  reg signed [22:0] choose_coef;  // choose coefficient for 3x3 matrix


  // ===============================================================
  // OUTPUT
  // ===============================================================

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
    end else begin
      case (mode)
        M2: out_valid <= (cnt_in_valid == 17) ? 1'b1 : 1'b0;
        M3: out_valid <= (cnt_in_valid == 20) ? 1'b1 : 1'b0;
        M4: out_valid <= (cnt_in_valid == 20) ? 1'b1 : 1'b0;
      endcase
    end
  end

  always @(*) begin
    if (out_valid) begin
      case (mode)
        M2: begin
          out_data = {
            out_matrix2x2[0],
            out_matrix2x2[1],
            out_matrix2x2[2],
            out_matrix2x2[5],
            out_matrix2x2[6],
            out_matrix2x2[7],
            out_matrix2x2[10],
            out_matrix2x2[11],
            out_matrix2x2[12]
          };
        end
        M3: begin
          out_data = {
            {3{1'b0}}, out_matrix3x3[0], out_matrix3x3[1], out_matrix3x3[2], out_matrix3x3[3]
          };
        end
        M4: begin
          out_data = (out_matrix3x3[0]*out_in_reg[15]) - out_matrix3x3[1]* out_in_reg[12] + (out_matrix3x3[2]* out_in_reg[13]) - (out_matrix3x3[3]* out_in_reg[14]);
        end
        default: begin
          out_data = 207'b0;
        end
      endcase
    end else begin
      out_data = 207'b0;
    end
  end

  // ===============================================================
  // INPUT
  // ===============================================================

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      cnt_in_valid <= 0;
    end else begin
      if (in_valid) cnt_in_valid <= cnt_in_valid + 1'b1;
      else if (out_valid == 1) cnt_in_valid <= 0;
      else if (cnt_in_valid >= 16 && cnt_in_valid <= 20) begin
        cnt_in_valid <= cnt_in_valid + 1'b1;
      end
    end
  end

  always @(posedge clk) begin
    if (in_valid) begin
      if (cnt_in_valid == 0) begin
        out_in_reg[cnt_in_valid] <= $signed(out_ham11);
        out_mode <= out_ham5;
      end else begin
        out_in_reg[cnt_in_valid] <= $signed(out_ham11);
      end
    end else if (out_valid) begin
      for (i = 0; i < 16; i++) begin
        out_in_reg[i] <= 0;
      end
      out_mode <= 0;
    end
  end

  // ===============================================================
  // MATRIX MODE
  // ===============================================================

  always @(posedge clk) begin
    if (in_valid) begin
      case (out_mode)
        5'b00100: mode <= M2;
        5'b00110: mode <= M3;
        5'b10110: mode <= M4;
        default:  mode <= M4;
      endcase
    end
  end


  matrix2x2 u1_matrix2x2 (
      .in (in_matrix),  // 11 bits
      .out(out_matrix)  // 23 bits
  );


  always @(posedge clk) begin
    if (cnt_in_valid == 0) begin
      cnt2 <= 0;
    end else if (cnt_in_valid == 7) begin
      cnt2 <= 0;
    end else if (cnt_in_valid == 12) begin
      cnt2 <= 4;
    end else if (cnt_in_valid == 9) begin
      cnt2 <= cnt2 + 2'd3;
    end else if (cnt_in_valid == 14) begin
      cnt2 <= (mode == M4) ? 0 : cnt2 + 2'd3;
    end else if (cnt_in_valid >= 5 && cnt_in_valid <= 16) begin
      cnt2 <= cnt2 + 1'b1;
    end
  end


  assign cnt_det = (cnt_in_valid >= 5) ? (cnt_in_valid - 5) : 0;

  always @(*) begin
    for (i = 0; i < 4; i++) begin
      in_matrix[i] = 0;
    end
    if (cnt_in_valid == 5 || cnt_in_valid == 6 || cnt_in_valid == 7) begin
      in_matrix[0] = out_in_reg[cnt2];
      in_matrix[1] = out_in_reg[cnt2+1];
      in_matrix[2] = out_in_reg[cnt2+4];
      in_matrix[3] = $signed(out_ham11);
    end
    else if(cnt_in_valid == 8 || cnt_in_valid == 9 || cnt_in_valid == 13 || cnt_in_valid == 14)
    begin
      in_matrix[0] = out_in_reg[cnt2];
      in_matrix[1] = out_in_reg[cnt2+2];
      in_matrix[2] = out_in_reg[cnt2+4];
      in_matrix[3] = out_in_reg[cnt2+6];
    end else if (cnt_in_valid == 15 && mode == M4) begin
      in_matrix[0] = out_in_reg[cnt2];
      in_matrix[1] = out_in_reg[cnt2+3];
      in_matrix[2] = out_in_reg[cnt2+4];
      in_matrix[3] = out_in_reg[cnt2+7];
    end else if (cnt_in_valid >= 5 && cnt_in_valid <= 17) begin
      in_matrix[0] = out_in_reg[cnt2];
      in_matrix[1] = out_in_reg[cnt2+1];
      in_matrix[2] = out_in_reg[cnt2+4];
      in_matrix[3] = out_in_reg[cnt2+5];
    end
  end

  always @(posedge clk) begin
    case (mode)
      M2, M3: if (cnt_in_valid >= 5 && cnt_in_valid <= 17) out_matrix2x2[cnt_det] <= out_matrix;
      M4: if (cnt_in_valid >= 5 && cnt_in_valid <= 15) out_matrix2x2[cnt_det] <= out_matrix;
    endcase
  end


  always @(posedge clk) begin
    if (cnt_in_valid == 0) begin
      cnt3 <= 0;
    end else if (cnt3 == 2) begin
      cnt3 <= 0;
    end else if (cnt_in_valid > 7) begin
      cnt3 <= cnt3 + 1'b1;
    end
  end

  always@(posedge clk) // out_data matrix number
  begin
    if (cnt_in_valid == 0) begin
      cnt_mat3 <= 0;
    end else if (cnt3 == 2) begin
      cnt_mat3 <= cnt_mat3 + 1'b1;
    end
  end


  always@(posedge clk) // left
  begin
    if (cnt_in_valid == 10) begin
      cnt_coeff3 <= 9;
    end else if (cnt_in_valid == 16) begin
      cnt_coeff3 <= (mode == M3) ? 13 : 8;
    end else if (mode == M4) begin
      if (cnt_in_valid == 13) cnt_coeff3 <= 8;
      else if (cnt_in_valid == 14) begin
        cnt_coeff3 <= 11;
      end else if (cnt_in_valid == 15) begin
        cnt_coeff3 <= 10;
      end else if (cnt_in_valid == 18) begin
        cnt_coeff3 <= 11;
      end else begin
        cnt_coeff3 <= cnt_coeff3 + 1'b1;
      end
    end else begin
      cnt_coeff3 <= cnt_coeff3 + 1'b1;
    end
  end

  always@(posedge clk) // right
  begin
    if (cnt_in_valid == 7) begin
      cnt_det3 <= 1;
    end else if (cnt_in_valid == 10) begin
      cnt_det3 <= 2;
    end else if (cnt_in_valid == 13) begin
      cnt_det3 <= (mode == M3) ? 6 : 2;
    end else if (cnt_in_valid == 16) begin
      cnt_det3 <= (mode == M3) ? 7 : 4;
    end else if (mode == M4) begin
      if (cnt_in_valid == 14) begin
        cnt_det3 <= 3;
      end else if (cnt_in_valid == 15) begin
        cnt_det3 <= 10;
      end else if (cnt_in_valid == 17) begin
        cnt_det3 <= 10;
      end else if (cnt_in_valid == 18) begin
        cnt_det3 <= 0;
      end else if (cnt3 == 0) begin
        cnt_det3 <= cnt_det3 + 2'd2;
      end else if (cnt3 == 1) begin
        cnt_det3 <= cnt_det3 - 2'd3;
      end
    end else if (cnt3 == 0) begin
      cnt_det3 <= cnt_det3 + 2'd2;
    end else if (cnt3 == 1) begin
      cnt_det3 <= cnt_det3 - 2'd3;
    end
  end



  always @(*) begin
    if (cnt_in_valid == 15 && mode == M4) begin
      choose_coef = out_in_reg[cnt_coeff3];
    end else if (cnt_in_valid == 16 && mode == M4) begin
      choose_coef = -out_in_reg[cnt_coeff3];
    end else if (cnt3 == 1) begin
      choose_coef = (cnt_in_valid >= 8 && cnt_in_valid <= 10) ? -$signed(out_ham11) :
          -out_in_reg[cnt_coeff3];
    end else begin
      choose_coef = (cnt_in_valid >= 8 && cnt_in_valid <= 10) ? $signed(out_ham11) :
          out_in_reg[cnt_coeff3];
    end
  end

  always @(posedge clk) begin
    if (cnt_in_valid == 0) begin
      for (i = 0; i < 4; i++) begin
        out_matrix3x3[i] <= 0;
      end
    end else begin
      if (cnt_in_valid >= 8 && cnt_in_valid <= 19)
        out_matrix3x3[cnt_mat3] <= out_matrix3x3[cnt_mat3] + choose_coef * out_matrix2x2[cnt_det3]; // not_yet
    end
  end


  // ===============================================================
  // HAMMING_IP
  // ===============================================================

  // always @(*) begin
  //   if (in_valid) begin
  //     in_data_reg = in_data;
  //     if (cnt_in_valid == 0) in_mode_reg = in_mode;
  //     else in_mode_reg = 0;
  //   end else begin
  //     in_data_reg = 0;
  //     in_mode_reg = 0;
  //   end
  // end

  HAMMING_IP #(
      .IP_BIT(11)
  ) u1_HAMMING_IP (
      // Input signals
      .IN_code (in_data),
      // Output signals
      .OUT_code(out_ham11)
  );

  HAMMING_IP #(
      .IP_BIT(5)
  ) u2_HAMMING_IP (
      // Input signals
      .IN_code (in_mode),
      // Output signals
      .OUT_code(out_ham5)
  );


endmodule


module matrix2x2 (
    input signed [10:0] in[0:3],  // 11 bits
    output signed [22:0] out  // 23 bits
);

  reg signed [22:0] out_reg;

  always @(*) begin
    out_reg = in[0] * in[3] - in[1] * in[2];
  end

  assign out = out_reg;

endmodule

