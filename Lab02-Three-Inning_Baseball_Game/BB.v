module BB (
    //Input Ports
    input       clk,
    input       rst_n,
    input       in_valid,
    input [1:0] inning,    // Current inning number
    input       half,      // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,    // Action code

    //Output Ports
    output reg       out_valid,  // Result output valid
    output reg [7:0] score_A,    // Score of team A (guest team)
    output reg [7:0] score_B,    // Score of team B (home team)
    output reg [1:0] result      // 0: Team A wins, 1: Team B wins, 2: Darw
  );

  //==============================================//
  //             Action Memo for Students         //
  // Action code interpretation:
  // 3’d0: Walk (BB)
  // 3’d1: 1H (single hit)
  // 3’d2: 2H (double hit)
  // 3’d3: 3H (triple hit)
  // 3’d4: HR (home run)
  // 3’d5: Bunt (short hit)
  // 3’d6: Ground ball
  // 3’d7: Fly ball
  //==============================================//

  //==============================================//
  //             Parameter and Integer            //
  //==============================================//
  // State declaration for FSM
  // Example: parameter IDLE = 3'b000;

  parameter WALK = 3'd0;
  parameter H1 = 3'd1;
  parameter H2 = 3'd2;
  parameter H3 = 3'd3;
  parameter HR = 3'd4;
  parameter BUNT = 3'd5;
  parameter GROUND = 3'd6;
  parameter FLY = 3'd7;

  parameter OUT0 = 2'd0;
  parameter OUT1 = 2'd1;
  parameter OUT2 = 2'd2;
  parameter OUT3 = 2'd3;


  //==============================================//
  //                 reg declaration              //
  //==============================================//

  reg [3:0] scoreA_ns, scoreB_ns;  // out status 0, 1, 2, 3
  reg [2:0] run;
  reg       out_valid_ns;
  reg [1:0] out;
  reg [1:0] out_ns;
  reg [1:0] result_ns;
  reg       countB;
  reg [3:0] score_cs, score_ns;

  //==============================================//
  //             Current State Block              //
  //==============================================//


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      score_A <= 8'd0;
    end
    else
    case (1'b1)
      (out_valid):
      begin
        score_A <= 8'b0;
      end
      (half == 0 && in_valid): score_A <= score_ns;
      default:
      begin
        score_A <= score_A;
      end
    endcase
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      score_B <= 8'd0;
    end
    else
    begin
      case (1'b1)
        (out_valid):
        begin
          score_B <= 8'b0;
        end
        (half == 1 && in_valid && !countB):
        begin
          score_B <= score_ns;
        end
        default:
          score_B <= score_B;
      endcase
    end
  end

  always @(posedge clk)
  begin
    score_cs <= score_ns;
  end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      out_valid <= 1'b0;
    end
    else
    begin
      out_valid <= out_valid_ns;
    end
  end

  always @(posedge clk)
  begin
    out_valid_ns <= (out_ns == 3 && half == 1 && inning == 3) ? 1 : 0;
  end


  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      out <= 2'b0;
    end
    else if (out_ns == 3)
      out <= 1'b0;
    else
      out <= out_ns;
  end

  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      result <= 2'b0;
    end
    else
      result <= result_ns;
  end
  //==============================================//
  //              Next State Block                //
  //==============================================//

  //   scoreCal #(
  //       .control(0)
  //   ) Acal (
  //       .cs(score_A),
  //       .ns(scoreA_ns),
  //       .action(action),
  //       .half(half),
  //       .run(run),
  //       .out(out),
  //       .inning(inning),
  //       .result(result),
  //       .countB(countB),
  //       .in_valid(in_valid)
  //   );
  //   scoreCal #(
  //       .control(1)
  //   ) Bcal (
  //       .cs(score_B),
  //       .ns(scoreB_ns),
  //       .action(action),
  //       .half(half),
  //       .run(run),
  //       .out(out),
  //       .inning(inning),
  //       .result(result),
  //       .countB(countB),
  //       .in_valid(in_valid)
  //   );

  wire [3:0]                          score_temp;
  wire [3:0] score1 = 1 + score_temp;
  wire [3:0] score2 = 2 + score_temp;
  wire [3:0] score3 = 3 + score_temp;

  assign score_temp = (half) ? score_B : score_A;
  wire run3 = (run[2] && run[1] && run[0]);
  always @(*)
  begin
    case (action)
      WALK:
      begin
        score_ns = (run3) ? score1 : score_temp;
      end
      H1:
      begin
        case (out)
          OUT0, OUT1:
          begin
            score_ns = (run[2]) ? score1 : score_temp;
          end
          OUT2:
          begin
            case ({
                      run[2], run[1]
                    })
              2'b01:
                score_ns = score1;
              2'b10:
                score_ns = score1;
              2'b11:
                score_ns = score2;
              default:
                score_ns = score_temp;
            endcase
          end
          default:
            score_ns = score_temp;
        endcase
      end
      H2:
      begin
        case (out)
          OUT0, OUT1:
          begin
            case ({
                      run[2], run[1]
                    })
              2'b01:
                score_ns = score1;
              2'b10:
                score_ns = score1;
              2'b11:
                score_ns = score2;
              default:
                score_ns = score_temp;
            endcase
          end
          OUT2:
          begin
            case (run)
              3'b001:
                score_ns = score1;
              3'b010:
                score_ns = score1;
              3'b100:
                score_ns = score1;
              3'b011:
                score_ns = score2;
              3'b110:
                score_ns = score2;
              3'b101:
                score_ns = score2;
              3'b111:
                score_ns = score3;
              default:
                score_ns = score_temp;
            endcase
          end
          default:
            score_ns = score_temp;
        endcase
      end
      H3:
      begin
        case (run)
          3'b001:
            score_ns = score1;
          3'b010:
            score_ns = score1;
          3'b100:
            score_ns = score1;
          3'b011:
            score_ns = score2;
          3'b110:
            score_ns = score2;
          3'b101:
            score_ns = score2;
          3'b111:
            score_ns = score3;
          default:
            score_ns = score_temp;
        endcase
      end
      HR:
      begin
        case (run)
          3'b000:
            score_ns = score1;
          3'b001:
            score_ns = score2;
          3'b010:
            score_ns = score2;
          3'b100:
            score_ns = score2;
          // 3'b011:  score_ns = score3;
          // 3'b110:  score_ns = score3;
          // 3'b101:  score_ns = score3;
          3'b111:
            score_ns = score_temp + 4;
          default:
            score_ns = score3;
        endcase
      end
      BUNT:
      begin
        score_ns = (run[2]) ? score1 : score_temp;
      end
      GROUND:
      begin
        case (out)
          OUT0:
          begin
            score_ns = (run[2]) ? score1 : score_temp;
          end
          OUT1:
          begin
            score_ns = (run[2] && ~run[0]) ? score1 : score_temp;
          end
          default:
            score_ns = score_temp;
        endcase
      end
      FLY:
      begin
        case (out)
          OUT0, OUT1:
          begin
            score_ns = (run[2]) ? score1 : score_temp;
          end
          default:
            score_ns = score_temp;
        endcase
      end
      default:
        score_ns = score_temp;
    endcase
  end

  // always @(*) begin

  //      if  begin
  //         case (action)
  //             WALK: begin
  //                 scoreB_ns = (run3) ? score_B + 1 : score_B;
  //             end
  //             H1: begin
  //                 case (out)
  //                     OUT0, OUT1: begin
  //                         scoreB_ns = (run[2]) ? score_B + 1 : score_B;
  //                     end
  //                     OUT2: begin
  //                         case ({
  //                             run[2], run[1]
  //                         })
  //                             2'b01:   scoreB_ns = score_B + 1;
  //                             2'b10:   scoreB_ns = score_B + 1;
  //                             2'b11:   scoreB_ns = score_B + 2;
  //                             default: scoreB_ns = score_B;
  //                         endcase
  //                     end
  //                     default: scoreB_ns = score_B;
  //                 endcase
  //             end
  //             H2: begin
  //                 case (out)
  //                     OUT0, OUT1: begin
  //                         case ({
  //                             run[2], run[1]
  //                         })
  //                             2'b01:   scoreB_ns = score_B + 1;
  //                             2'b10:   scoreB_ns = score_B + 1;
  //                             2'b11:   scoreB_ns = score_B + 2;
  //                             default: scoreB_ns = score_B;
  //                         endcase
  //                     end
  //                     OUT2: begin
  //                         case (run)
  //                             3'b001:  scoreB_ns = score_B + 1;
  //                             3'b010:  scoreB_ns = score_B + 1;
  //                             3'b100:  scoreB_ns = score_B + 1;
  //                             3'b011:  scoreB_ns = score_B + 2;
  //                             3'b110:  scoreB_ns = score_B + 2;
  //                             3'b101:  scoreB_ns = score_B + 2;
  //                             3'b111:  scoreB_ns = score_B + 3;
  //                             default: scoreB_ns = score_B;
  //                         endcase
  //                     end
  //                     default: scoreB_ns = score_B;
  //                 endcase
  //             end
  //             H3: begin
  //                 case (run)
  //                     3'b001:  scoreB_ns = score_B + 1;
  //                     3'b010:  scoreB_ns = score_B + 1;
  //                     3'b100:  scoreB_ns = score_B + 1;
  //                     3'b011:  scoreB_ns = score_B + 2;
  //                     3'b110:  scoreB_ns = score_B + 2;
  //                     3'b101:  scoreB_ns = score_B + 2;
  //                     3'b111:  scoreB_ns = score_B + 3;
  //                     default: scoreB_ns = score_B;
  //                 endcase
  //             end
  //             HR: begin
  //                 case (run)
  //                     3'b001:  scoreB_ns = score_B + 2;
  //                     3'b010:  scoreB_ns = score_B + 2;
  //                     3'b100:  scoreB_ns = score_B + 2;
  //                     3'b011:  scoreB_ns = score_B + 3;
  //                     3'b110:  scoreB_ns = score_B + 3;
  //                     3'b101:  scoreB_ns = score_B + 3;
  //                     3'b111:  scoreB_ns = score_B + 4;
  //                     default: scoreB_ns = score_B + 1;
  //                 endcase
  //             end
  //             BUNT: begin
  //                 scoreB_ns = (run[2]) ? score_B + 1 : score_B;
  //             end
  //             GROUND: begin
  //                 case (out)
  //                     OUT0: begin
  //                         scoreB_ns = (run[2]) ? score_B + 1 : score_B;
  //                     end
  //                     OUT1: begin
  //                         scoreB_ns = (run[2] && ~run[0]) ? score_B + 1 : score_B;
  //                     end
  //                     default: scoreB_ns = score_B;
  //                 endcase
  //             end
  //             FLY: begin
  //                 case (out)
  //                     OUT0, OUT1: begin
  //                         scoreB_ns = (run[2]) ? score_B + 1 : score_B;
  //                     end
  //                     default: scoreB_ns = score_B;
  //                 endcase
  //             end
  //             default: scoreB_ns = score_B;
  //         endcase
  //     end else begin
  //         scoreB_ns = score_B;
  //     end
  // end


  always @(*)
  begin
    if (in_valid)
    begin
      case (action)
        BUNT:
          out_ns = out + 1;
        GROUND:
        begin
          case (out)
            OUT0, OUT1:
              out_ns = (run[0]) ? out + 2 : out + 1;
            OUT2:
              out_ns = 2'd3;
            default:
              out_ns = out;
          endcase
        end
        FLY:
        begin
          out_ns = out + 1;
        end
        default:
          out_ns = out;
      endcase
    end
    else
      out_ns = out;
  end

  //==============================================//
  //             Base and Score Logic             //
  //==============================================//
  // Handle base runner movements and score calculation.
  // Update bases and score depending on the action:
  // Example: Walk, Hits (1H, 2H, 3H), Home Runs, etc.

  // action
  always @(posedge clk, negedge rst_n)
  begin
    if (!rst_n)
    begin
      run <= 3'b000;  // 1, 2, 3 b
    end
    else
    case (1'b1)
      (out_valid):
      begin
        run <= 3'b000;
      end
      (in_valid):
      begin
        case (action)
          WALK:
          begin
            case (run)
              4'b000:
                run <= 3'b001;
              4'b001:
                run <= 3'b011;
              4'b010:
                run <= 3'b011;
              4'b011:
                run <= 3'b111;
              4'b100:
                run <= 3'b101;
              default:
                run <= 3'b111;
            endcase
          end
          H1:
          begin
            case (out)
              OUT0, OUT1:
              begin
                run[2] <= run[1];
                run[1] <= run[0];
                run[0] <= 1'b1;
              end
              OUT2:
              begin
                run[2] <= run[0];
                run[1] <= 1'b0;  // always no runner
                run[0] <= 1'b1;
              end
              default:
                run <= run;
            endcase
          end
          H2:
          begin
            case (out)
              OUT0, OUT1:
              begin
                run[2] <= run[0];
                run[1] <= 1'b1;  // always no runner
                run[0] <= 1'b0;
              end
              OUT2:
              begin
                run <= 3'b010;
              end
              default:
                run <= run;
            endcase
          end
          H3:
          begin
            run <= 3'b100;
          end
          HR:
          begin
            run <= 3'b000;
          end
          BUNT:
          begin
            run[2] <= run[1];
            run[1] <= run[0];
            run[0] <= 1'b0;
          end
          GROUND:
          begin
            case (out)
              OUT0:
              begin
                run[2] <= run[1];
                run[1] <= 1'b0;
                run[0] <= 1'b0;
              end
              OUT1:
              begin
                if (run[0])
                begin
                  run <= 3'b000;
                end
                else
                begin
                  run[2] <= run[1];
                  run[1] <= 1'b0;
                  run[0] <= 1'b0;
                end
              end
              OUT2:
              begin
                run <= 3'b000;
              end
              default:
                run <= run;
            endcase
          end
          FLY:
          begin
            case (out)
              OUT0, OUT1:
              begin
                if (run[2])
                begin
                  run[2] <= 1'b0;
                  run[1] <= run[1];
                  run[0] <= run[0];
                end
                else
                begin
                  run <= run;
                end
              end
              OUT2:
              begin
                run <= 3'b000;
              end
              default:
                run <= run;
            endcase
          end
          default:
            run <= 3'b000;
        endcase
      end
      default:
        run <= run;
    endcase
  end

  always @(posedge clk)
  begin
    case (1'b1)
      (out_valid):
      begin
        countB <= 1'b0;
      end
      (half == 0 && inning == 3 && in_valid):
      begin
        countB <= result;
      end
      default:
        countB <= countB;
    endcase
  end
  //==============================================//
  //                Output Block                  //
  //==============================================//
  // Decide when to set out_valid high, and output score_A, score_B, and result.
  always @(*)
  begin
    result_ns = (score_A[3:0] > score_B[3:0]) ? 0 : (score_B[3:0] > score_A[3:0]) ? 1 : 2;
  end

endmodule

// module scoreCal #(
//     parameter control = 1
// ) (
//     cs,
//     ns,
//     action,
//     half,
//     run,
//     out,
//     result,
//     inning,
//     countB,
//     in_valid
// );
//   input half;
//   input [7:0] cs;
//   input [2:0] action;
//   input [2:0] run;
//   input [1:0] out;
//   input countB;
//   input in_valid;
//   output reg [7:0] ns;
//   input [1:0] inning;
//   input [1:0] result;

//   parameter WALK = 3'd0;
//   parameter H1 = 3'd1;
//   parameter H2 = 3'd2;
//   parameter H3 = 3'd3;
//   parameter HR = 3'd4;
//   parameter BUNT = 3'd5;
//   parameter GROUND = 3'd6;
//   parameter FLY = 3'd7;

//   parameter OUT0 = 2'd0;
//   parameter OUT1 = 2'd1;
//   parameter OUT2 = 2'd2;
//   parameter OUT3 = 2'd3;

//   always @(*) begin
//     if (countB && half == 1 && in_valid) begin  // b win in inning 3
//       ns = cs;
//     end else if (half == control && in_valid) begin
//       case (action)
//         WALK: begin
//           ns = (run[2] && run[1] && run[0]) ? cs + 1 : cs;
//         end
//         H1: begin
//           case (out)
//             OUT0, OUT1: begin
//               ns = (run[2]) ? cs + 1 : cs;
//             end
//             OUT2: begin
//               case ({
//                 run[2], run[1]
//               })
//                 2'b01:   ns = cs + 1;
//                 2'b10:   ns = cs + 1;
//                 2'b11:   ns = cs + 2;
//                 default: ns = cs;
//               endcase
//             end
//             default: ns = cs;
//           endcase
//         end
//         H2: begin
//           case (out)
//             OUT0, OUT1: begin
//               case ({
//                 run[2], run[1]
//               })
//                 2'b01:   ns = cs + 1;
//                 2'b10:   ns = cs + 1;
//                 2'b11:   ns = cs + 2;
//                 default: ns = cs;
//               endcase
//             end
//             OUT2: begin
//               case (run)
//                 3'b001:  ns = cs + 1;
//                 3'b010:  ns = cs + 1;
//                 3'b100:  ns = cs + 1;
//                 3'b011:  ns = cs + 2;
//                 3'b110:  ns = cs + 2;
//                 3'b101:  ns = cs + 2;
//                 3'b111:  ns = cs + 3;
//                 default: ns = cs;
//               endcase
//             end
//             default: ns = cs;
//           endcase
//         end
//         H3: begin
//           case (run)
//             3'b001:  ns = cs + 1;
//             3'b010:  ns = cs + 1;
//             3'b100:  ns = cs + 1;
//             3'b011:  ns = cs + 2;
//             3'b110:  ns = cs + 2;
//             3'b101:  ns = cs + 2;
//             3'b111:  ns = cs + 3;
//             default: ns = cs;
//           endcase
//         end
//         HR: begin
//           case (run)
//             3'b001:  ns = cs + 2;
//             3'b010:  ns = cs + 2;
//             3'b100:  ns = cs + 2;
//             3'b011:  ns = cs + 3;
//             3'b110:  ns = cs + 3;
//             3'b101:  ns = cs + 3;
//             3'b111:  ns = cs + 4;
//             default: ns = cs + 1;
//           endcase
//         end
//         BUNT: begin
//           ns = (run[2]) ? cs + 1 : cs;
//         end
//         GROUND: begin
//           case (out)
//             OUT0: begin
//               ns = (run[2]) ? cs + 1 : cs;
//             end
//             OUT1: begin
//               ns = (run[2] && ~run[0]) ? cs + 1 : cs;
//             end
//             default: ns = cs;
//           endcase
//         end
//         FLY: begin
//           case (out)
//             OUT0, OUT1: begin
//               ns = (run[2]) ? cs + 1 : cs;
//             end
//             default: ns = cs;
//           endcase
//         end
//         default: ns = cs;
//       endcase
//     end else begin
//       ns = cs;
//     end
//   end


// endmodule  // end calculate a and b
