
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
// `define CYCLE_TIME 15

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
  //================================================================
  // parameters & integer
  //================================================================
  parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
  parameter MAX_CYCLE=10000;
	real CYCLE = 15; // CYCLE_TIME;

	// 7000 ok
	// 6700
  parameter PAT_NUM = 6600;
  integer i_pat;
  integer total_latency, total_cycles;
	integer latency;
	
  // ANSI escape codes for colors
  localparam string RED = "\033[31m";
  localparam string GREEN = "\033[32m";
  localparam string RESET = "\033[0m";


  //================================================================
  // wire & registers
  //================================================================
  logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box


  //================================================================
  // class random
  //================================================================

  /**
   * Class representing a random action.
   */

  //================================================================
  //                           INPUT
  //================================================================


class random_act;
rand Action act_id;
constraint range{
act_id inside{Index_Check, Update, Check_Valid_Date};
}
endclass

class random_fromula;
rand Formula_Type formula_id;
constraint range{
formula_id inside{[Formula_A:Formula_H]};
}
endclass

class random_mode;
rand Mode mode_id;
constraint range{
mode_id inside{Insensitive, Normal, Sensitive};
}
endclass

class random_date;
rand Date date_id;
constraint range{
date_id.M inside{1,2,3,4,5,6,7,8,9,10,11,12};
if(date_id.M == 1 || date_id.M == 3 || date_id.M == 5 || date_id.M == 7 || date_id.M == 8 ||
date_id.M == 10 || date_id.M == 12)
date_id.D inside{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};
else if(date_id.M == 4 || date_id.M == 6 || date_id.M == 9 || date_id.M == 11)
date_id.D inside{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30};
else if(date_id.M == 2)
date_id.D inside{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28};
}
endclass

class random_warn;
rand Warn_Msg warn_id;
constraint range{
warn_id inside{No_Warn, Date_Warn, Risk_Warn, Data_Warn};
}
endclass

class random_data_no;
rand Data_No data_no_id;
constraint range{
data_no_id inside{[0:255]};
}
endclass

class random_index_data;
rand Index index_id;
constraint range{
index_id inside{[0:4095]};
}
endclass

random_act act_in;
random_fromula formula_in;
random_mode mode_in;
random_date date_in;
random_warn warn_in;
random_data_no data_no_in;
random_index_data index_in;

  //================================================================
  //                            LOGIC
  //================================================================
  logic [63:0] dram_read;
	logic [63:0] dram_write;

	logic signed [12:0] dram_index_A, dram_index_B, dram_index_C, dram_index_D;
	logic [7:0] dram_month;
	logic [7:0] dram_day;

	logic [11:0]    golden_result;
	logic [11:0]    threshold;

	Warn_Msg     golden_warn_msg;
  logic        golden_complete;

	logic [11:0] sort_in [0:3];
  logic [11:0] sort_out [0:3];

	logic [11:0]   index_A, index_B, index_C, index_D;
	logic signed [11:0] variation_A, variation_B, variation_C, variation_D;
	logic [11:0]    g_a, g_b, g_c, g_d;
	logic flag_update_data_warn;

	logic signed [13:0]    sum_A, sum_B, sum_C, sum_D;
  //================================================================

  initial
  begin
    $readmemh(DRAM_p_r, golden_DRAM);
    act_in = new();
    formula_in = new();
    mode_in = new();
    date_in = new();
    warn_in = new();
    data_no_in = new();
    index_in = new();

    reset_task;

		total_latency = 0;
    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1)
    begin
      input_action_task;
      case(act_in.act_id)
        Index_Check:
        begin
          input_index_check_task;
					cal_index_check_task;
        end
        Update:
        begin
          input_update_task;
					cal_update_task;
        end
        Check_Valid_Date:
        begin
          input_check_valid_date_task;
					cal_check_valid_date_task;
        end
      endcase
			wait_output_task;
			check_ans_task;
			$display("%sPASS PATTEN NO.%d%s", GREEN, i_pat, RESET);
    end

    YOU_PASS_TASK;
  end

  //================================================================
  // 1. After rst_n, all output signals in Program.sv should be set to 0.
  //================================================================

  task reset_task;
    begin
      inf.formula_valid = 1'b0;
      inf.mode_valid = 1'b0;
      inf.date_valid = 1'b0;
      inf.data_no_valid = 1'b0;
      inf.index_valid = 1'b0;
      inf.D = 72'bx;

      force clk = 1'b0;
      #(CYCLE/2);
      inf.rst_n = 1'b0;
      #(CYCLE/2);
      inf.rst_n = 1'b1;

      if(inf.out_valid === 0 && inf.warn_msg === 0 && inf.complete === 0 &&
          inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && inf.AW_VALID === 0 &&
          inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && inf.B_READY === 0)
      begin
        // No action needed
      end
      else
      begin
        $display("%s============================================================================%s", RED, RESET);
        $display("%sError: 1. After rst_n, all output signals in Program.sv should be set to 0.%s", RED, RESET);
        $display("%s============================================================================%s", RED, RESET);
        repeat(5) @(negedge clk);
        $finish;
      end

      // Apply reset
      #CYCLE;
      release clk;
    end
  endtask

	task wait_output_task;
	begin
		latency = 0;
		while(inf.out_valid !== 1)begin
			latency = latency + 1;
			if(latency > 1000)begin
				$display("%s============================================================================%s", RED, RESET);
        $display("%s           The execution latency exceeded 1000 cycles at Pat No. %d         %s", RED, i_pat, RESET);
        $display("%s============================================================================%s", RED, RESET);
				repeat(5) @(negedge clk);
				$finish;
			end
			@(negedge clk);
		end
		total_latency = total_latency + latency;
	end
	endtask

	task check_ans_task;
	begin
		if(inf.out_valid === 1)begin
			// YOU_FAIL_TASK;
			if(golden_warn_msg !== inf.warn_msg)begin
				$display("%s============================================================================%s", RED, RESET);
				$display("%s              Message is Wrong Answer at Pat No. %d%s                        ", RED, i_pat, RESET);
				$display("%s============================================================================%s", RED, RESET);
				//repeat(5) @(negedge clk);
				$finish;
			end
			else if(golden_complete !== inf.complete)begin
				$display("%s============================================================================%s", RED, RESET);
				$display("%s               Complete is Wrong Answer at Pat No. %d%s                      ", RED, i_pat, RESET);
				$display("%s============================================================================%s", RED, RESET);
				//repeat(5) @(negedge clk);
				$finish;
			end
		end
	end
	endtask

  task input_action_task;
    begin
      repeat(1) @(negedge clk);
      inf.sel_action_valid = 1'b1;

      
			if(i_pat < 3600)begin
				act_in.act_id = Index_Check;
			end
			else begin
      	act_in.randomize();
			end
			inf.D.d_act[0] = act_in.act_id;

      @(negedge clk);
      inf.sel_action_valid = 1'b0;
      inf.D = 72'bx;
    end
  endtask


	task input_formula_task;
		begin
			repeat(0) @(negedge clk);
      inf.formula_valid = 1'b1;  
			if(i_pat < 3600)begin
				case(i_pat % 24)
					0, 1, 2: formula_in.formula_id = Formula_A;
					3, 4, 5: formula_in.formula_id = Formula_B;
					6, 7, 8: formula_in.formula_id = Formula_C;
					9, 10, 11: formula_in.formula_id = Formula_D;
					12, 13, 14: formula_in.formula_id = Formula_E;
					15, 16, 17:	formula_in.formula_id = Formula_F;
					18, 19, 20: formula_in.formula_id = Formula_G;
					21, 22, 23: formula_in.formula_id = Formula_H;
				endcase
			end
			else begin
				void'(formula_in.randomize());
			end
			inf.D.d_formula[0] = formula_in.formula_id;
			@(negedge clk);
      inf.formula_valid = 1'b0;
      inf.D = 72'bx;
		end
	endtask

	task input_mode_task;
		begin
			repeat(0) @(negedge clk);
      inf.mode_valid = 1'b1;
			if(i_pat < 3600)begin
				case(i_pat % 3)
					0: mode_in.mode_id = Insensitive;
					1: mode_in.mode_id = Normal;
					2: mode_in.mode_id = Sensitive;
				endcase
			end
			else begin
      	mode_in.randomize();
			end
      inf.D.d_mode[0] = mode_in.mode_id;
      @(negedge clk);
      inf.mode_valid = 1'b0;
      inf.D = 72'bx;
		end
	endtask
	
	task input_date_task;
		begin
			repeat(0) @(negedge clk);
			inf.date_valid = 1'b1;
			date_in.randomize();
			inf.D.d_date[0] = date_in.date_id;
			@(negedge clk);
			inf.date_valid = 1'b0;
			inf.D = 72'bx;
		end
	endtask

	task input_data_no_task;
	begin
		repeat(0) @(negedge clk);
		inf.data_no_valid = 1'b1;
		data_no_in.randomize();
		inf.D.d_data_no[0] = data_no_in.data_no_id;
		@(negedge clk);
		inf.data_no_valid = 1'b0;
		inf.D = 72'bx;
	end
	endtask

	task input_dram_read;
	begin
		dram_read = {golden_DRAM[65536 + data_no_in.data_no_id * 8 + 7], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 6],
                   golden_DRAM[65536 + data_no_in.data_no_id * 8 + 5], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 4],
                   golden_DRAM[65536 + data_no_in.data_no_id * 8 + 3], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 2],
                   golden_DRAM[65536 + data_no_in.data_no_id * 8 + 1], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 0]};

									 dram_index_A = dram_read[52+:12];
									 dram_index_B = dram_read[40+:12];
									 dram_month = dram_read[32+:8];
									 dram_index_C = dram_read[20+:12];
									 dram_index_D = dram_read[8+:12];
									 dram_day = dram_read[0+:8];
	end
	endtask

  task input_index_check_task;
    begin
      // Formula Type
			input_formula_task;
      // Mode
      input_mode_task;
      // Today's Date
      input_date_task;
      // No. of data in　DRAM
			input_data_no_task;
      // Today's Index A in late trading session
      // Today's Index B in late trading session
      // Today's Index C in late trading session
      // Today's Index D in late trading session
      for (int i = 0; i < 4; i++)
      begin
        repeat(0) @(negedge clk);
        inf.index_valid = 1'b1;
        index_in.randomize();
        inf.D.d_index[0] = index_in.index_id;
				if(i == 0)begin
					index_A = index_in.index_id;
				end
				else if(i == 1)begin
					index_B = index_in.index_id;
				end
				else if(i == 2)begin
					index_C = index_in.index_id;
				end
				else if(i == 3)begin
					index_D = index_in.index_id;
				end
				@(negedge clk);
				inf.index_valid = 1'b0;
				inf.D = 72'bx;
			end
			//DRAM
			input_dram_read;
	end
  endtask

  task input_update_task;
    begin
      // Data Date
      input_date_task;
      // No. of data in DRAM
      input_data_no_task;
      // Variation in Index A in early trading session
      // Variation in Index B in early trading session
      // Variation in Index C in early trading session
      // Variation in Index D in early trading session
      for (int i = 0; i < 4; i++)
      begin
        repeat(0) @(negedge clk);
        inf.index_valid = 1'b1;
        index_in.randomize();
        inf.D.d_index[0] = index_in.index_id;
				if(i == 0)begin
					variation_A = index_in.index_id;
				end
				else if(i == 1)begin
					variation_B = index_in.index_id;
				end
				else if(i == 2)begin
					variation_C = index_in.index_id;
				end
				else if(i == 3)begin
					variation_D = index_in.index_id;
				end
        @(negedge clk);
        inf.index_valid = 1'b0;
        inf.D = 72'bx;
      end
			//DRAM
			input_dram_read;
    end
  endtask

  task input_check_valid_date_task;
    begin
      // Today's Date
      input_date_task;
      // No. of data in DRAM
      input_data_no_task;
			// DRAM
			input_dram_read;
    end
  endtask

  task cal_index_check_task;
    begin
			// golden_warn_msg = No_Warn;
			// golden_complete = 1'b0;

				case (formula_in.formula_id)
					Formula_A,Formula_C :
					begin
						case (mode_in.mode_id)
							Insensitive:
								threshold= 2047;
							Normal:
								threshold = 1023;
							Sensitive:
								threshold = 511;
						endcase
					end
					Formula_B, Formula_F, Formula_G, Formula_H:
					begin
						case (mode_in.mode_id)
							Insensitive:
								threshold = 800;
							Normal:
								threshold = 400;
							Sensitive:
								threshold = 200;
						endcase
					end
					Formula_D, Formula_E:
					begin
						case (mode_in.mode_id)
							Insensitive:
								threshold = 3;
							Normal:
								threshold = 2;
							Sensitive:
								threshold = 1;
						endcase
					end
				endcase

				g_a = (dram_index_A >= index_A) ? (dram_index_A - index_A) : (index_A - dram_index_A);
				g_b = (dram_index_B >= index_B) ? (dram_index_B - index_B) : (index_B - dram_index_B);
				g_c = (dram_index_C >= index_C) ? (dram_index_C - index_C) : (index_C - dram_index_C);
				g_d = (dram_index_D >= index_D) ? (dram_index_D - index_D) : (index_D - dram_index_D);

				if(formula_in.formula_id == Formula_F || formula_in.formula_id == Formula_G || formula_in.formula_id == Formula_H)
				begin
					sort_in[0] = g_a;
					sort_in[1] = g_b;
					sort_in[2] = g_c;
					sort_in[3] = g_d;
				end
				else begin
					sort_in[0] = dram_index_A;
					sort_in[1] = dram_index_B;
					sort_in[2] = dram_index_C;
					sort_in[3] = dram_index_D;
				end
		
				//sorting network to result in sort_out
				for (int i = 0; i < 4; i = i + 1) begin
					for (int j = i + 1; j < 4; j = j + 1) begin
							if (sort_in[i] > sort_in[j]) begin
									// Swap elements
									logic [11:0] temp;
									temp = sort_in[i];
									sort_in[i] = sort_in[j];
									sort_in[j] = temp;
							end
					end
				end

				// Assign sorted values to sort_out
				// 0 the smallest element
				sort_out[0] = sort_in[0];
				sort_out[1] = sort_in[1];
				sort_out[2] = sort_in[2];
				sort_out[3] = sort_in[3];


				if (act_in.act_id == Index_Check)
				begin
					case (formula_in.formula_id)
						Formula_A:
						begin
							golden_result = (dram_index_A + dram_index_B + dram_index_C + dram_index_D)/4;
						end
						Formula_B:
						begin
							golden_result = sort_out[3] - sort_out[0];
						end
						Formula_C:
						begin
							golden_result =   sort_out[0];
						end
						Formula_D:
						begin
							golden_result = ((dram_index_A >= 2047) + (dram_index_B >= 2047) + (dram_index_C >= 2047) + (dram_index_D >= 2047));
						end
						Formula_E:
						begin
							golden_result = ((dram_index_A >= index_A) + (dram_index_B  >= index_B) + (dram_index_C >= index_C) + (dram_index_D >= index_D));
						end
						Formula_F:
						begin
							golden_result = (sort_out[0] + sort_out[1] + sort_out[2]) / 3;
						end
						Formula_G:
						begin
							golden_result = (sort_out[0] / 2) + (sort_out[1] / 4) + (sort_out[2] / 4);
						end
						Formula_H:
							golden_result = ( (g_a + g_b) + (g_c + g_d)) / 4;
						default:
							golden_result = 0;
					endcase
				end
				// $display("dram_index_A =%d, dram_index_B =%d, dram_index_C =%d, dram_index_D =%d", dram_index_A, dram_index_B, dram_index_C, dram_index_D);
				// $display("dram_month = %d, input_month = %d", dram_month, date_in.date_id.M);
				// $display("dram_day = %d, input_day = %d", dram_day, date_in.date_id.D);
				// $display("golden_result = %d", golden_result);
				// $display("threshold = %d", threshold);

				if((date_in.date_id.M == dram_month && date_in.date_id.D < dram_day) || date_in.date_id.M < dram_month)
				begin
					golden_warn_msg = Date_Warn;
					golden_complete = 1'b0;
				end
				else if(golden_result >= threshold)
				begin
					golden_warn_msg = Risk_Warn;
					golden_complete = 1'b0;
				end
				else begin
					golden_warn_msg = No_Warn;
					golden_complete = 1'b1;
				end
    end
  endtask

	task cal_update_task;
	begin
		sum_A = dram_index_A + variation_A;
		sum_B = dram_index_B + variation_B;
		sum_C = dram_index_C + variation_C;
		sum_D = dram_index_D + variation_D;

		flag_update_data_warn = 0;
		if(sum_A > 4095 || sum_B > 4095 || sum_C > 4095 || sum_D > 4095 || sum_A < 0 || sum_B < 0 || sum_C < 0 || sum_D < 0)
			flag_update_data_warn = 1;
		
		if(sum_A > 4095)
			sum_A = 4095;
		else if(sum_A < 0)
			sum_A = 0;

		if(sum_B > 4095)
			sum_B = 4095;
		else if(sum_B < 0)
			sum_B = 0;

		if(sum_C > 4095)
			sum_C = 4095;
		else if(sum_C < 0)
			sum_C = 0;

		if(sum_D > 4095)
			sum_D = 4095;
		else if(sum_D < 0)
			sum_D = 0;

		if(flag_update_data_warn == 1)begin
			golden_warn_msg = Data_Warn;
			golden_complete = 1'b0;
		end
		else begin
			golden_warn_msg = No_Warn;
			golden_complete = 1'b1;
		end


			dram_write[52+:12] = sum_A;
			dram_write[40+:12] = sum_B;
			dram_write[32+:8] = date_in.date_id.M;
			dram_write[20+:12] = sum_C;
			dram_write[8+:12] = sum_D;
			dram_write[0+:8] = date_in.date_id.D;

			
			{golden_DRAM[65536 + data_no_in.data_no_id * 8 + 7], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 6],
			golden_DRAM[65536 + data_no_in.data_no_id * 8 + 5], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 4],
			golden_DRAM[65536 + data_no_in.data_no_id * 8 + 3], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 2],
			golden_DRAM[65536 + data_no_in.data_no_id * 8 + 1], golden_DRAM[65536 + data_no_in.data_no_id * 8 + 0]} = dram_write;
			
	end
	endtask

	task cal_check_valid_date_task;
	begin
			// $display("dram_month = %d, input_month = %d", dram_month, date_in.date_id.M);
			// $display("dram_day = %d, input_day = %d", dram_day, date_in.date_id.D);
			if((date_in.date_id.M == dram_month && date_in.date_id.D < dram_day) || date_in.date_id.M < dram_month)
			begin
				golden_warn_msg = Date_Warn;
				golden_complete = 1'b0;
			end
			else begin
				golden_warn_msg = No_Warn;
				golden_complete = 1'b1;
			end
	end
	endtask

  task YOU_PASS_TASK;
    begin
      $display("                               `-:/+++++++/:-`                                        ");
      $display("                          ./shmNdddmmNNNMMMMMNNhs/.                                   ");
      $display("                       `:yNMMMMMdo------:/+ymMMMMMNds-                                ");
      $display("                     +dNMMNysmMMMd/....-ymNMMMMNMMMMMd+                             ");
      $display("                    .+NMMNy:-.-oNMMm..../MMMNho:-+dMMMMMm+`                           ");
      $display("      ``            +-oso/:::::/+so:....-:+++//////hNNm++dd-                          ");
      $display("      +/-  -`      -:.-//--.....-:+-.....-+/--....--/+-..:Nm:                         ");
      $display("  :--./-:::/.      /-.+:..-:+oso+:-+....-+:/oso+:....-+:..yMN:                        ");
      $display("  -/:-:-.+-/      `+--+.-smNMMMMMNh/....:ymNMMMMNy:...-+../MMm.                       ");
      $display(" ::/+-...--/   --:-...-dMMMh/.-yMMd-..-mMMy::oNMMm:...-..-mMMy.                     ");
      $display(" .-:+:.....---::-......+MMMM-  sMMN-..oMMN.  .mMMM+.......hd+:-::                   ");
      $display("   /+/::/:..:/-........:mMMMmddmMMMs...+NMMmddNMMMm:......-+-....-/.                  ");
      $display("   ```  /.::...........:odmNNNNmh/-..../ydmNNNmds:.......-.......-+                 ");
      $display("         -:+..............--::::--........--:::--..................::                 ");
      $display("          //.......................................................-:                 ");
      $display("          `+...........................................--::::-....-/`                 ");
      $display("           ::.....................................-//os+/+/+oo----.`                  ");
      $display("            :/-.............................-::/\033[0;31;111mosyyyyyyyyyyyh\033[m-   ");
      $display("             +s+:-...................--::/\033[0;31;111m+ssyyyyyyyyyyyyyyyyy\033[m+   ");
      $display("            .\033[0;31;111myyyyso+:::----:/::://+osssyyyyyyyyyyyyyyyyyyyyyyyy\033[m-  ");
      $display("             -/\033[0;31;111msyyyyyyysssssssyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy\033[m. ");
      $display("               `-/\033[0;31;111mssyhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy\033[m`");
      $display("                  `.\033[0;31;111mohyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhyyyyyyyyyyss\033[m/");
      $display("                   \033[0;31;111myyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyydyyyyysso/o\033[m. ");
      $display("                   :\033[0;31;111mhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhhhyy\033[m:-...+   ");
      $display("                   \033[0;31;111msyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy\033[m+....o   ");
      $display("                  `\033[0;31;111mhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy\033[m+:..//   ");
      $display("                  :\033[0;31;111mhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy\033[m:+.-o`   ");
      $display("                  -\033[0;31;111mhyyyyyyssoosyyyyyssoosyyyyyyssoo+oosy\033[m+--..o`   ");
      $display("                  `s\033[0;33;219m/////:-.``.://::-.``.:/++/:-```````.\033[m+:--:+    ");
      $display("                  ./\033[0;33;219m`````````````````````````````````````\033[ms.-.     ");
      $display("                  /-\033[0;33;219m`````````````````. ``````````````````\033[mo        ");
      $display("                  +\033[0;33;219m``````````````````. ``````````````````\033[m+`       ");
      $display("                  +-\033[0;33;219m....-...---------: :::::::::::::/::::\033[m+`       ");
      $display("                  `\033[0;33;219m.....+::::-:+`````   `   `/+..---o:```\033[m         ");
      $display("                        :-..../`              o-....s``                              ");
      $display("                        ./-.--o               :+:::/o                                ");
      $display("                         /::--o               `o````o                                ");
      $display("                        -//   +                +- `-s/                               ");
      $display("                      -/-::::o:              :+////-+/:-                           ");
      $display("                  `///:-:///:::+             `+////:////+s+                          ");
      $display("*************************************************************************************");
      $display("                        \033[0;38;5;219mCongratulations!\033[m                       ");
      $display("                 \033[0;38;5;219mYou have passed all patterns!\033[m                 ");
      $display("                 \033[0;38;5;219mTotal Cycles : %d\033[m                             ",total_latency);
      $display("*************************************************************************************");
      $finish;
    end
  endtask

  task YOU_FAIL_TASK;
    begin
      $display("*************************************************************************************");
      $display("*                                   FAILURE!                                        ");
			$display("                                 action = %d 																		 ", act_in.act_id);
			$display("*                      golden_warn = %d, golden_complete = %d                       ", golden_warn_msg, golden_complete);
			$display("*                           warn = %d  ,     complete = %d                       ", inf.warn_msg, inf.complete);
      $display("*                                   (;´༎ຶД༎ຶ`)                                         ");
      $display("*                     Something went wrong with the test!                           ");
      $display("*************************************************************************************");
    end
  endtask

endprogram


