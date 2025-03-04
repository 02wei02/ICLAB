module Ramen (
    // Input Registers
    input clk,
    input rst_n,
    input in_valid,
    input selling,
    input portion,
    input [1:0] ramen_type,

    // Output Signals
    output reg out_valid_order,
    output reg success,

    output reg out_valid_tot,
    output reg [27:0] sold_num,
    output reg [14:0] total_gain
);


  //==============================================//
  //             Parameter and Integer            //
  //==============================================//

  // ramen_type
  parameter TONKOTSU = 0;
  parameter TONKOTSU_SOY = 1;
  parameter MISO = 2;
  parameter MISO_SOY = 3;

  // initial ingredient
  parameter NOODLE_INIT = 12000;
  parameter BROTH_INIT = 41000;
  parameter TONKOTSU_SOUP_INIT = 9000;
  parameter MISO_INIT = 1000;
  parameter SOY_SAUSE_INIT = 1500;

  parameter SMALL = 1'b0;
  parameter LARGE = 1'b1;


  //==============================================//
  //                 reg declaration              //
  //==============================================// 

  reg [1:0] cnt_invalid;
  reg [1:0] ramen_type_reg;
  reg portion_reg;

  reg [1:0] state_ns;
  reg [1:0] state_cs;

  parameter IDLE = 2'd0;
  parameter SELL = 2'd1;
  parameter OUT = 2'd2;
  parameter END = 2'd3;

  // number of sold
  reg [6:0] num_tonkotsu, num_tonkotsu_cs;
  reg [6:0] num_tonkotsu_soy, num_tonkotsu_soy_cs;
  reg [6:0] num_miso, num_miso_cs;
  reg [6:0] num_miso_soy, num_miso_soy_cs;

  reg [13:0] m_noodle, m_noodle_cs;
  reg [15:0] m_broth, m_broth_cs;
  reg [13:0] m_tonkotsu, m_tonkotsu_cs;
  reg [9:0] m_miso, m_miso_cs;
  reg [10:0] m_soy, m_soy_cs;

  reg [7:0] g_noodle;  // 150g
  reg [9:0] g_broth;  // 650g
  reg [7:0] g_tonkotsu;  //200g
  reg [5:0] g_soy;  // 50g;
  reg [5:0] g_miso;  // 50g

  reg is_out;

  reg can_sell;

  //==============================================//
  //                    Design                    //
  //==============================================//

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      state_cs <= IDLE;
    end else begin
      state_cs <= state_ns;
    end
  end

  always @(*) begin
    case (state_cs)
      IDLE: begin
        if (selling) begin
          state_ns <= SELL;
        end else begin
          state_ns <= IDLE;
        end
      end
      SELL: begin
        if (in_valid == 0 && is_out == 0) state_ns <= OUT;
        else state_ns <= SELL;
      end
      OUT: begin
        if (selling == 0) begin
          state_ns <= END;
        end else state_ns <= SELL;
      end
      END: begin
        state_ns <= IDLE;
      end
      default: begin
        state_ns <= IDLE;
      end
    endcase
  end

  always @(posedge clk) begin
    if (state_cs == IDLE) begin
      is_out <= 1'b0;
    end else if (out_valid_order) begin
      is_out <= 1'b1;
    end else if (in_valid) begin
      is_out <= 1'b0;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      cnt_invalid <= 0;
    end else begin
      if (in_valid) begin
        cnt_invalid <= cnt_invalid + 1;
      end else begin
        cnt_invalid <= 0;
      end
    end
  end

  always @(posedge clk) begin
    if (in_valid) begin
      if (cnt_invalid == 0) begin
        ramen_type_reg <= ramen_type;
      end else if (cnt_invalid == 1) begin
        portion_reg <= portion;
      end
    end
  end

  // minus noodle
  always @(*) begin
    g_noodle <= 0;
    if (can_sell) begin
      case (portion_reg)
        1'b0: begin
          g_noodle <= 100;
        end
        default: begin
          g_noodle <= 150;
        end
      endcase
    end
  end

  // minus broth
  always @(*) begin
    g_broth <= 0;
    if (can_sell) begin
      case (portion_reg)
        1'b0: begin
          case (ramen_type_reg)
            TONKOTSU: begin
              g_broth <= 300;
            end
            TONKOTSU_SOY: begin
              g_broth <= 300;
            end
            MISO: begin
              g_broth <= 400;
            end
            MISO_SOY: begin
              g_broth <= 300;
            end
            default: begin
              g_broth <= 0;
            end
          endcase
        end
        default: begin
          case (ramen_type_reg)
            TONKOTSU: begin
              g_broth <= 500;
            end
            TONKOTSU_SOY: begin
              g_broth <= 500;
            end
            MISO: begin
              g_broth <= 650;
            end
            MISO_SOY: begin
              g_broth <= 500;
            end
            default: begin
              g_broth <= 0;
            end
          endcase
        end
      endcase
    end
  end

  // minus tonkotsu soup
  always @(*) begin
    g_tonkotsu <= 0;
    if (can_sell) begin
      case (portion_reg)
        1'b0: begin
          case (ramen_type_reg)
            TONKOTSU: begin
              g_tonkotsu <= 150;
            end
            TONKOTSU_SOY: begin
              g_tonkotsu <= 100;
            end
            MISO_SOY: begin
              g_tonkotsu <= 70;
            end
            default: begin
              g_tonkotsu <= 0;
            end
          endcase
        end
        default: begin
          case (ramen_type_reg)
            TONKOTSU: begin
              g_tonkotsu <= 200;
            end
            TONKOTSU_SOY: begin
              g_tonkotsu <= 150;
            end
            MISO_SOY: begin
              g_tonkotsu <= 100;
            end
            default: begin
              g_tonkotsu <= 0;
            end
          endcase
        end
      endcase
    end
  end

  always @(*) begin
    g_soy <= 0;
    if (can_sell) begin
      case (portion_reg)
        1'b0: begin
          case (ramen_type_reg)
            TONKOTSU_SOY: begin
              g_soy <= 30;
            end
            MISO_SOY: begin
              g_soy <= 15;
            end
            default: begin
              g_soy <= 0;
            end
          endcase
        end
        default: begin
          case (ramen_type_reg)
            TONKOTSU_SOY: begin
              g_soy <= 50;
            end
            MISO_SOY: begin
              g_soy <= 25;
            end
            default: begin
              g_soy <= 0;
            end
          endcase
        end
      endcase
    end
  end

  always @(*) begin
    g_miso <= 0;
    if (can_sell) begin
      case (portion_reg)
        1'b0: begin
          case (ramen_type_reg)
            MISO: begin
              g_miso <= 30;
            end
            MISO_SOY: begin
              g_miso <= 15;
            end
            default: begin
              g_miso <= 0;
            end
          endcase
        end
        default: begin
          case (ramen_type_reg)
            MISO: begin
              g_miso <= 50;
            end
            MISO_SOY: begin
              g_miso <= 25;
            end
            default: begin
              g_miso <= 0;
            end
          endcase
        end
      endcase
    end
  end

  // the resource is enough can sell 
  always @(posedge clk) begin
    case (portion_reg)
      1'b0: begin
        case (ramen_type_reg)
          TONKOTSU: begin
            can_sell <= (m_noodle_cs >= 100 && m_broth_cs >= 300 && m_tonkotsu_cs >= 150) ? 1'b1: 1'b0;
          end
          TONKOTSU_SOY: begin
            can_sell <= (m_noodle_cs >= 100 && m_broth_cs >= 300 && m_tonkotsu_cs >= 100 && m_soy_cs >= 30) ? 1'b1: 1'b0;
          end
          MISO: begin
            can_sell <= (m_noodle_cs >= 100 && m_broth_cs >= 400 && m_miso_cs >= 30) ? 1'b1 : 1'b0;
          end
          MISO_SOY: begin
            can_sell <= (m_noodle_cs >= 100 && m_broth_cs >= 300 && m_tonkotsu_cs >= 70 && m_soy >= 15 && m_miso >= 15) ? 1'b1: 1'b0;
          end
        endcase
      end
      default: begin
        case (ramen_type_reg)
          TONKOTSU: begin
            can_sell <= (m_noodle_cs >= 150 && m_broth_cs >= 500 && m_tonkotsu_cs >= 200) ? 1'b1: 1'b0;
          end
          TONKOTSU_SOY: begin
            can_sell <= (m_noodle_cs >= 150 && m_broth_cs >= 500 && m_tonkotsu_cs >= 150 && m_soy_cs >= 50) ? 1'b1: 1'b0;
          end
          MISO: begin
            can_sell <= (m_noodle_cs >= 150 && m_broth_cs >= 650 && m_miso_cs >= 50) ? 1'b1 : 1'b0;
          end
          MISO_SOY: begin
            can_sell <= (m_noodle_cs >= 150 && m_broth_cs >= 500 && m_tonkotsu_cs >= 100 && m_soy_cs >= 25 && m_miso_cs >= 25) ? 1'b1: 1'b0;
          end
        endcase
      end
    endcase
  end


  // the resource to have
  always @(*) begin
    case (state_cs)
      OUT: begin
        m_noodle <= m_noodle_cs - g_noodle;
        m_broth <= m_broth_cs - g_broth;
        m_tonkotsu <= m_tonkotsu_cs - g_tonkotsu;
        m_miso <= m_miso_cs - g_miso;
        m_soy <= m_soy_cs - g_soy;
      end
      default: begin
        m_noodle <= m_noodle_cs;
        m_broth <= m_broth_cs;
        m_tonkotsu <= m_tonkotsu_cs;
        m_miso <= m_miso_cs;
        m_soy <= m_soy_cs;
      end
    endcase
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      m_noodle_cs <= NOODLE_INIT;
      m_broth_cs <= BROTH_INIT;
      m_tonkotsu_cs <= TONKOTSU_SOUP_INIT;
      m_miso_cs <= MISO_INIT;
      m_soy_cs <= SOY_SAUSE_INIT;
    end else if (state_cs == IDLE) begin
      m_noodle_cs <= NOODLE_INIT;
      m_broth_cs <= BROTH_INIT;
      m_tonkotsu_cs <= TONKOTSU_SOUP_INIT;
      m_miso_cs <= MISO_INIT;
      m_soy_cs <= SOY_SAUSE_INIT;
    end else begin
      m_noodle_cs <= m_noodle;
      m_broth_cs <= m_broth;
      m_tonkotsu_cs <= m_tonkotsu;
      m_miso_cs <= m_miso;
      m_soy_cs <= m_soy;
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      num_tonkotsu_cs <= 0;
      num_tonkotsu_soy_cs <= 0;
      num_miso_cs <= 0;
      num_miso_soy_cs <= 0;
    end else if (state_cs == IDLE) begin
      num_tonkotsu_cs <= 0;
      num_tonkotsu_soy_cs <= 0;
      num_miso_cs <= 0;
      num_miso_soy_cs <= 0;
    end else begin
      num_tonkotsu_cs <= num_tonkotsu;
      num_tonkotsu_soy_cs <= num_tonkotsu_soy;
      num_miso_cs <= num_miso;
      num_miso_soy_cs <= num_miso_soy;
    end
  end

  always @(*) begin
    num_tonkotsu <= num_tonkotsu_cs;
    if (state_cs == OUT && can_sell) begin
      if (ramen_type_reg == TONKOTSU) begin
        num_tonkotsu <= num_tonkotsu_cs + 1'b1;
      end else begin
        num_tonkotsu <= num_tonkotsu_cs;
      end
    end
  end

  always @(*) begin
    num_tonkotsu_soy <= num_tonkotsu_soy_cs;
    if (state_cs == OUT && can_sell) begin
      if (ramen_type_reg == TONKOTSU_SOY) begin
        num_tonkotsu_soy <= num_tonkotsu_soy_cs + 1'b1;
      end else begin
        num_tonkotsu_soy <= num_tonkotsu_soy_cs;
      end
    end
  end

  always @(*) begin
    num_miso <= num_miso_cs;
    if (state_cs == OUT && can_sell) begin
      if (ramen_type_reg == MISO) begin
        num_miso <= num_miso_cs + 1'b1;
      end else begin
        num_miso <= num_miso_cs;
      end
    end
  end

  always @(*) begin
    num_miso_soy <= num_miso_soy_cs;
    if (state_cs == OUT && can_sell) begin
      if (ramen_type_reg == MISO_SOY) begin
        num_miso_soy <= num_miso_soy_cs + 1'b1;
      end else begin
        num_miso_soy <= num_miso_soy_cs;
      end
    end
  end

  //==============================================//
  //                 reg declaration              //
  //==============================================// 

  always @(*) begin
    if (state_cs == OUT) out_valid_order <= 1'b1;
    else out_valid_order <= 1'b0;
  end

  always @(*) begin
    if (state_cs == OUT) begin
      success <= can_sell;
    end else success <= 1'b0;
  end

  always @(*) begin
    if (state_cs == END) begin
      out_valid_tot <= 1'b1;
    end else out_valid_tot <= 1'b0;
  end

  always @(*) begin
    if (state_cs == END) begin
      sold_num <= {num_tonkotsu_cs, num_tonkotsu_soy_cs, num_miso_cs, num_miso_soy_cs};
    end else sold_num <= 28'b0;
  end

  always @(*) begin
    if (state_cs == END) begin
      total_gain <= (num_tonkotsu_cs * 8'd200) + (num_tonkotsu_soy_cs * 8'd250) + (num_miso_cs * 8'd200) + (num_miso_soy_cs * 8'd250);
    end else total_gain <= 15'b0;
  end


endmodule
