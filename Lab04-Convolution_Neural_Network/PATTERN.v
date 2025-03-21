// ############################################################################
//    ____                                    ___ ____     _          _     
//   / ___|  ___ _ __  ___  ___  _ __ ___    |_ _/ ___|   | |    __ _| |__  
//   \___ \ / _ \ '_ \/ __|/ _ \| '__/ __|    | | |       | |   / _` | '_ \ 
//    ___) |  __/ | | \__ \ (_) | |  \__ \    | | |___    | |__| (_| | |_) |
//   |____/ \___|_| |_|___/\___/|_|  |___/   |___\____|   |_____\__,_|_.__/ 
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2024 Fall ICLAB Course
//   Lab04           : CNN
//   Author          : Jyun-Wei, Su
//   Release version : v1.0 Initial Release
//                     v1.1 Add conv temp result with 3 channel, and fix conv
//                     v1.2 Fix max pooling form 2x2 to 3x3
// ############################################################################

`define CYCLE_TIME      29.9
`define SEED_NUMBER     805
`define PATTERN_NUMBER  10000

module PATTERN(
    //Output Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,
    //Input Port
    out_valid,
    out
    );


//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg         clk, rst_n, in_valid;
output reg [31:0]  Img;
output reg [31:0]  Kernel_ch1;
output reg [31:0]  Kernel_ch2;
output reg [31:0]  Weight;
output reg         Opt;
input              out_valid;
input      [31:0]  out;


//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
integer SEED = `SEED_NUMBER;
integer PAT_NUM = `PATTERN_NUMBER;
integer total_latency, latency;
integer out_data_cnt;
integer i_pat;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;


//================================================================
// registers 
//================================================================
// input
reg [31:0] img_input [0:2][0:4][0:4];     // 3 channel, 5x5
reg [31:0] ker_ch1   [0:2][0:1][0:1];     // 3 channel, 2x2
reg [31:0] ker_ch2   [0:2][0:1][0:1];     // 3 channel, 2x2
reg [31:0] fc_weight [0:2][0:7];          // 3 channel, 1x8
reg        option;                        // activation function
// calculation gloden answer
reg [31:0] img_paded     [0:2][0:6][0:6]; // 3 channel, 7x7
reg [31:0] tmp_conv [0:1][0:2][0:5][0:5]; // 2 channel, with 3 sub channel, 6x6
reg [31:0] rslt_conv     [0:1][0:5][0:5]; // 2 channel, 6x6
reg [31:0] rslt_pool     [0:1][0:1][0:1]; // 2 channel, 2x2
reg [31:0] rslt_act      [0:1][0:1][0:1]; // 2 channel, 2x2
reg [31:0] rslt_fc       [0:2];           // 1x3
reg [31:0] rslt_exp      [0:2];           // 1x3 exp(rslt_fc)
reg [31:0] rslt_softmax  [0:2];           // 1x3
// output buffer
reg [31:0] out_buffer    [0:2];


//================================================================
// clock
//================================================================
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;


//================================================================
// initial
//================================================================
initial begin
  reset_signal_task;
  total_latency = 0;
  
  for (i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
    gen_pattern_task;
    calculate_ans_task;
    input_task;
    wait_out_valid_and_check_ans_task;
    total_latency = total_latency + latency;
  end

  YOU_PASS_task;
end

//================================================================
// global check
//================================================================
initial begin
  while(1) begin
    if((out_valid === 0) && (out !== 0))
    begin
      $display("***********************************************************************");
      $display("*  Error Code:                                                        *");
      $display("*  The out        should be reset when out_valid is low.              *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
end

// Output signal out_valid and out_matrix should be zero when in_valid is high
initial begin
  while(1) begin
    if((in_valid === 1) && (out_valid !== 0))
    begin
      $display("***********************************************************************");
      $display("*  Error Code:                                                        *");
      $display("*  The out_valid should be reset when in_valid is high.               *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
end


//================================================================
// task
//================================================================
task reset_signal_task; 
begin
  // $display("reset_signal_task");
  rst_n = 1;
  force clk = 0;
  #(0.5 * CYCLE);
  rst_n = 0;
  in_valid  = 0 ;
  Img = 'bx;
  Kernel_ch1 = 'bx;
  Kernel_ch2 = 'bx;
  Weight = 'bx;
  Opt = 0;
  #(10 * CYCLE);
  if( (out_valid !== 0) || (out !== 0))
  begin
    $display("***********************************************************************");
    $display("*  Error Code:                                                        *");
    $display("*  Output signal should reset after initial RESET                     *");
    $display("***********************************************************************");
    // DONT PUT @(negedge clk) HERE
    $finish;
  end
  #(CYCLE);  rst_n=1;
  #(CYCLE);  release clk;
  @(negedge clk); //#(0.5 * CYCLE);
end 
endtask

task gen_pattern_task;
begin
  // $display("gen_pattern_task");
  real tmp_real;
  // random option
  option = $urandom(SEED) % 2;

  // random img_input, ker_ch1, ker_ch2, fc_weight floating point (32bits)
  // using $shortrealtobits() to convert shortreal to 32bits IEEE754 format
  // the random value is between -0.5 ~ +0.5
  for (int i = 0; i < 3; i = i + 1) begin
    for (int j = 0; j < 5; j = j + 1) begin
      for (int k = 0; k < 5; k = k + 1) begin
        tmp_real = $urandom() / (2.0 ** 32) - 0.5;
        img_input[i][j][k] = $shortrealtobits(tmp_real);
      end
    end
  end
  for (int i = 0; i < 3; i = i + 1) begin
    for (int j = 0; j < 2; j = j + 1) begin
      for (int k = 0; k < 2; k = k + 1) begin
        tmp_real = $urandom() / (2.0 ** 32) - 0.5;
        ker_ch1[i][j][k] = $shortrealtobits(tmp_real);
        ker_ch2[i][j][k] = $shortrealtobits(tmp_real);
      end
    end
  end
  for (int i = 0; i < 3; i = i + 1) begin
    for (int j = 0; j < 8; j = j + 1) begin
      tmp_real = $urandom() / (2.0 ** 32) - 0.5;
      fc_weight[i][j] = $shortrealtobits(tmp_real);
    end
  end
  $display("img_input[0][0][0] = %f", $bitstoshortreal(img_input[0][0][0]));
  $display("img_input[0][0][0] = %x", img_input[0][0][0]);
end
endtask

task calculate_ans_task;
begin
  // $display("calculate_ans_task");
  real tmp_real;
  real tmp_num;
  real tmp_den;
  // Step 1: Padding, option = 0 padding 0, option = 1 padding replicate
  for (int i = 0; i < 3; i = i + 1) begin
    for (int j = 0; j < 5; j = j + 1) begin
      for (int k = 0; k < 5; k = k + 1) begin
        img_paded[i][j+1][k+1] = img_input[i][j][k];
      end
    end
  end
  if (option === 0) begin
    for (int i = 0; i < 3; i = i + 1) begin
      for (int j = 0; j < 7; j = j + 1) begin
        img_paded[i][j][0] = 0;
        img_paded[i][j][6] = 0;
      end
      for (int j = 0; j < 7; j = j + 1) begin
        img_paded[i][0][j] = 0;
        img_paded[i][6][j] = 0;
      end
    end
  end
  else if(option === 1) begin
    for (int i = 0; i < 3; i = i + 1) begin
      for (int j = 0; j < 7; j = j + 1) begin
        img_paded[i][j][0] = img_paded[i][j][1];
        img_paded[i][j][6] = img_paded[i][j][5];
      end
      for (int j = 0; j < 7; j = j + 1) begin
        img_paded[i][0][j] = img_paded[i][1][j];
        img_paded[i][6][j] = img_paded[i][5][j];
      end
    end
  end
  else begin
    $display("Pattern internal error");
    $finish;
  end
  // Step 2-1: Convolution, with 3 sub-channel
  // ch1
  for(integer j = 0; j < 3; j = j + 1) begin
    for(integer m = 0; m < 6; m = m + 1) begin
      for(integer n = 0; n < 6; n = n + 1) begin
        tmp_real = 0;
        for(integer k = 0; k < 2; k = k + 1) begin
          for(integer l = 0; l < 2; l = l + 1) begin
            tmp_real = tmp_real + $bitstoshortreal(img_paded[j][m+k][n+l])
                                * $bitstoshortreal(ker_ch1[j][k][l]);
          end
        end
        tmp_conv[0][j][m][n] = $shortrealtobits(tmp_real);
      end
    end
  end
  // ch2
  for(integer j = 0; j < 3; j = j + 1) begin
    for(integer m = 0; m < 6; m = m + 1) begin
      for(integer n = 0; n < 6; n = n + 1) begin
        tmp_real = 0;
        for(integer k = 0; k < 2; k = k + 1) begin
          for(integer l = 0; l < 2; l = l + 1) begin
            tmp_real = tmp_real + $bitstoshortreal(img_paded[j][m+k][n+l])
                                * $bitstoshortreal(ker_ch2[j][k][l]);
          end
        end
        tmp_conv[1][j][m][n] = $shortrealtobits(tmp_real);
      end
    end
  end
  // Step 2: Convolution, sum three sub-channel
  for (integer i = 0; i < 2; i = i + 1) begin
    for (integer j = 0; j < 6; j = j + 1) begin
      for (integer k = 0; k < 6; k = k + 1) begin
        tmp_real = 0;
        for (integer m = 0; m < 3; m = m + 1) begin
          tmp_real = tmp_real + $bitstoshortreal(tmp_conv[i][m][j][k]);
        end
        rslt_conv[i][j][k] = $shortrealtobits(tmp_real);
      end
    end
  end
  // Step 3: Pooling
  // Initial the pooling result equal to the first element of convolution result
  // and then compare with the other element of convolution result
  for (integer i = 0; i < 2; i = i + 1) begin
    for (integer j = 0; j < 2; j = j + 1) begin
      for (integer k = 0; k < 2; k = k + 1) begin
        rslt_pool[i][j][k] = rslt_conv[i][j*3][k*3];
        for (integer m = 0; m < 3; m = m + 1) begin
          for (integer n = 0; n < 3; n = n + 1) begin
            if($bitstoshortreal(rslt_pool[i][j][k]) < $bitstoshortreal(rslt_conv[i][j*3+m][k*3+n]))
              rslt_pool[i][j][k] = rslt_conv[i][j*3+m][k*3+n];
          end
        end
      end
    end
  end
  // Step 4: Activation
  // option = 0 sigmoid, option = 1 tanh
  if (option === 0) begin
    for (integer i = 0; i < 2; i = i + 1) begin
      for (integer j = 0; j < 2; j = j + 1) begin
        for (integer k = 0; k < 2; k = k + 1) begin
          tmp_num = 1.0;
          tmp_den = 1.0 + $exp(-1.0 * $bitstoshortreal(rslt_pool[i][j][k]));
          rslt_act[i][j][k] = $shortrealtobits(tmp_num / tmp_den);
        end
      end
    end
  end
  else if (option === 1) begin
    for (integer i = 0; i < 2; i = i + 1) begin
      for (integer j = 0; j < 2; j = j + 1) begin
        for (integer k = 0; k < 2; k = k + 1) begin
          tmp_num = $exp($bitstoshortreal(rslt_pool[i][j][k])) - $exp(-1.0 * $bitstoshortreal(rslt_pool[i][j][k]));
          tmp_den = $exp($bitstoshortreal(rslt_pool[i][j][k])) + $exp(-1.0 * $bitstoshortreal(rslt_pool[i][j][k]));
          rslt_act[i][j][k] = $shortrealtobits(tmp_num / tmp_den);
        end
      end
    end
  end
  else begin
    $display("Pattern internal error");
    $finish;
  end
  // Step 5: Fully Connected
  for (integer i = 0; i < 3; i = i + 1) begin
    tmp_real = 0;
    for (integer j = 0; j < 2; j = j + 1) begin
      for (integer k = 0; k < 2; k = k + 1) begin
        for (integer l = 0; l < 2; l = l + 1) begin
          tmp_real = tmp_real + $bitstoshortreal(rslt_act[j][k][l])
                              * $bitstoshortreal(fc_weight[i][j*4+k*2+l]);
        end
      end
    end
    rslt_fc[i] = $shortrealtobits(tmp_real);
  end
  // Step 6-1: Softmax (expedential step)
  for (integer i = 0; i < 3; i = i + 1) begin
    rslt_exp[i] = $shortrealtobits($exp($bitstoshortreal(rslt_fc[i])));
  end
  // Step 6-2: Softmax (sum and division step)
  tmp_real = 0;
  for (integer i = 0; i < 3; i = i + 1) begin
    tmp_real = tmp_real + $bitstoshortreal(rslt_exp[i]);
  end
  for (integer i = 0; i < 3; i = i + 1) begin
    rslt_softmax[i] = $shortrealtobits($bitstoshortreal(rslt_exp[i]) / tmp_real);
  end
end
endtask

task input_task;
begin
  // $display("input_task");
  in_valid = 1;
  for (integer i = 0; i < 75; i = i + 1) begin
    // Img, 3 channel, 5x5
    Img = img_input[i/25][(i%25)/5][(i%25)%5];
    // Kernel, 3 channel, 2x2
    if (i < 12) begin
      Kernel_ch1 = ker_ch1[i/4][(i%4)/2][(i%4)%2];
      Kernel_ch2 = ker_ch2[i/4][(i%4)/2][(i%4)%2];
    end
    else begin
      Kernel_ch1 = 'bx;
      Kernel_ch2 = 'bx;
    end
    // FC Weight, 3 channel, 1x8
    if (i < 24) Weight = fc_weight[i/8][i%8];
    else        Weight = 'bx;
    // Option
    if (i == 0) Opt = option;
    else        Opt = 'bx;
    @(negedge clk);
  end
  // disable input signal
  in_valid = 0;
  Img = 'bx;
  Kernel_ch1 = 'bx;
  Kernel_ch2 = 'bx;
  Weight = 'bx;
end
endtask

task wait_out_valid_and_check_ans_task;
begin
  // $display("wait_out_valid_and_check_ans_task");
  real err [0:2];
  latency = 0;
  out_data_cnt = 0;
  while (out_valid !== 1) begin
    latency = latency + 1;
    @(negedge clk);
    // timeout
    if(latency > 200) begin
      $display("***********************************************************************");
      $display("*  Error Code:                                                        *");
      $display("*  The execution latency are over   200 cycles.                       *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
  end
  while(out_data_cnt < 3) begin
    if(out_valid === 1) begin
      out_buffer[out_data_cnt] = out;
      out_data_cnt = out_data_cnt + 1;
    end
    else begin
      $display("***********************************************************************");
      $display("*  Error Code:                                                        *");
      $display("*  The out_valid should be high for 3 cycles. (current less then 3)   *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    latency = latency + 1;
    @(negedge clk);
  end
  if (out_valid === 1) begin
    $display("***********************************************************************");
    $display("*  Error Code:                                                        *");
    $display("*  The out_valid should be high for 3 cycles. (current more than 3)   *");
    $display("***********************************************************************");
    repeat(2)@(negedge clk);
    $finish;
  end
  // calculate the error
  for (int i = 0; i < 3; i = i + 1) begin
    err[i] = $abs($bitstoshortreal(out_buffer[i]) - $bitstoshortreal(rslt_softmax[i]));
  end
  // check the output data, allow 0.0001 error
  if(err[0] >= 0.0001 || err[1] >= 0.0001 || err[2] >= 0.0001) begin
    $display("***********************************************************************");
    $display("*  Error Code:                                                        *");
    $display("*  The output data is not correct (err > 0.0001)                      *");
    $display("*  Golden answer : %10.6f (%08x)", $bitstoshortreal(rslt_softmax[0]), rslt_softmax[0]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(rslt_softmax[1]), rslt_softmax[1]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(rslt_softmax[2]), rslt_softmax[2]);
    $display("*  Your answer   : %10.6f (%08x)", $bitstoshortreal(out_buffer[0]), out_buffer[0]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(out_buffer[1]), out_buffer[1]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(out_buffer[2]), out_buffer[2]);
    $display("***********************************************************************");
    repeat(2)@(negedge clk);
    $finish;
  end
  // show warning message if the error > 0.00007
  if(err[0] >= 0.00007 || err[1] >= 0.00007 || err[2] >= 0.00007) begin
    $display("***********************************************************************");
    $display("*  Warning Code:                                                      *");
    $display("*  The output data may not correct (err > 0.00007)                     *");
    $display("*  Golden answer : %10.6f (%08x)", $bitstoshortreal(rslt_softmax[0]), rslt_softmax[0]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(rslt_softmax[1]), rslt_softmax[1]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(rslt_softmax[2]), rslt_softmax[2]);
    $display("*  Your answer   : %10.6f (%08x)", $bitstoshortreal(out_buffer[0]), out_buffer[0]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(out_buffer[1]), out_buffer[1]);
    $display("*                  %10.6f (%08x)", $bitstoshortreal(out_buffer[2]), out_buffer[2]);
    $display("***********************************************************************");
  end
  $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",i_pat , latency);
  // wait 1~3 cycles
  repeat($random(SEED) % 3 + 1) @(negedge clk);
end
endtask

task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*                         Congratulations!                              *");
  $display("*                Your execution cycles = %5d cycles          *", total_latency);
  $display("*                Your clock period = %.1f ns          *", CYCLE);
  $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
  $display("***********************************************************************");
  $finish;
end endtask

task YOU_FAIL_task; begin
  $display("*                              FAIL!                                    *");
  $display("*                    Error message from PATTERN.v                       *");
end endtask

endmodule



