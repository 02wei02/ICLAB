`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();

	always_ff @(posedge clk) begin
		if(inf.formula_valid) begin
				fm_info.f_type = inf.D.d_formula[0];
		end
		if(inf.mode_valid) begin
				fm_info.f_mode = inf.D.d_mode[0];
		end
	end


	//================================================================
	//                            Register
	//================================================================
	Action action_reg;
	logic [2:0] cnt_in;


	//================================================================
	//                       Register Update
	//================================================================
	always_ff@(posedge clk or negedge inf.rst_n)begin
		if(!inf.rst_n)begin
			action_reg <= Index_Check;
		end
		else begin
			action_reg <= (inf.sel_action_valid)? inf.D.d_act[0] : action_reg;
		end
	end

	always_ff@(posedge clk or negedge inf.rst_n)begin
		if(!inf.rst_n)begin
			cnt_in <= 0;
		end
		else begin
			if(cnt_in == 4)begin
				cnt_in <= 0;
			end
			else begin 
				cnt_in <= (inf.index_valid)? cnt_in + 1'b1 : cnt_in;
			end
		end
	end

	//================================================================
	// 1. Each case of Formula_Type should be select at least 150 times.
	//================================================================

	covergroup Spec1 @(posedge clk iff(inf.formula_valid));
		option.at_least = 150;
		option.per_instance = 1;
		f_type_150: coverpoint fm_info.f_type {
			bins formula_type [] = {[Formula_A : Formula_H]};
		}
	endgroup

	Spec1 Spec1_inst = new();

	//================================================================
	// 2. Each case of Mode should be select at least 150 times.
	//================================================================

	covergroup Spec2 @(posedge clk iff(inf.mode_valid));
		option.at_least = 150;
		option.per_instance = 1;
		f_mode_150: coverpoint fm_info.f_mode {
			bins Insensitive = {Insensitive};
			bins Normal = {Normal};
			bins Sensitive = {Sensitive};
		}
	endgroup

	Spec2 Spec2_inst = new();

	//================================================================
	// 3. Create a cross bin for the SPEC1 and SPEC2. Each combination should be select at least 150 times. 
	// (Formula_A, B, C, D, E, F, G, H) x (Insensitive, Normal, Sensitive)
	//================================================================

	covergroup Spec3 @(posedge clk iff(inf.mode_valid)); // ?
		option.at_least = 150;
		option.per_instance = 1;
		cross fm_info.f_type, fm_info.f_mode;
	endgroup

	logic flag;
	always_ff @( posedge clk or inf.rst_n) begin 
    if (!inf.rst_n) 
        flag <= 1'b0;
    else begin
        if (inf.mode_valid === 1)
            flag <= 1'b1;
        else
            flag <= 1'b0;
    end
	end

	covergroup SPEC3 @(posedge clk iff flag);
			option.at_least = 150;
			option.per_instance = 1;
			coverpoint fm_info.f_type;
			coverpoint fm_info.f_mode;
			cross fm_info.f_type, fm_info.f_mode;
	endgroup

	Spec3 Spec3_inst = new();

	//================================================================
	// 4. Output signal inf.warn_msg should be "No_Warn", "Date_Warn" or "Data_Warn", "Risk Warn" each at least 50 times.
	// (Sample the value when inf.out_valid is high)
	//================================================================

	covergroup Spec4 @(posedge clk iff(inf.out_valid));
		option.at_least = 50;
		option.per_instance = 1;
		warn_msg_50: coverpoint inf.warn_msg {
			bins No_Warn = {No_Warn};
			bins Date_Warn = {Date_Warn};
			bins Risk_Warn = {Risk_Warn};
			bins Data_Warn = {Data_Warn};
		}
	endgroup

	Spec4 Spec4_inst = new();

	//================================================================
	// 5. Create the transition bin for the inf.D_act[0] signal from [Index_Check: Check_Valid_Date] to [Index_Check: Check_Valid_Date].
	// Each transition should be hit at least 300 times. (sampel the value at posedge clk iff inf.sel_action_valid)
	//================================================================

	covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
		option.at_least = 300;
		option.per_instance = 1;
		d_act_transition_300: coverpoint inf.D.d_act[0] {
			bins data_act [] = ( [Index_Check:Check_Valid_Date] => [Index_Check:Check_Valid_Date] );
		}
	endgroup

	Spec5 Spec5_inst = new();
	//================================================================
	// 6. Create a covergroup for variation of Update action with auto_bin_max = 32, and each bin have to be hit at least 1 times.
	//================================================================

	covergroup Spec6 @(posedge clk iff(inf.index_valid));
		option.at_least = 1;
		option.per_instance = 1;
		d_act_auto_bin: coverpoint inf.D.d_index[0] {
			option.auto_bin_max = 32;
		}
	endgroup

	Spec6 Spec6_inst = new();

	//================================================================
	//                           Assertion
	//================================================================

	//================================================================
	// 1. All output signals (Program.sv) should be zero after reset.
	//================================================================

	always@(negedge inf.rst_n)begin // negedge check rst
		#(1);
		assertion_rst: assert(inf.out_valid === 0 && inf.warn_msg === 0 && inf.complete === 0 &&
													inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && inf.AW_VALID === 0 &&
													inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && inf.B_READY === 0 )begin
			
		end
		else begin
			$display("\033[1;31mAssertion 1 is violated\033[0m");
			$fatal;
		end
	end

	//================================================================
	// 2. Latency should be less than 1000 cycles for each operation.
	//================================================================
	always@(posedge clk)begin
		assertion_latency1: assert property (@(posedge clk)( (action_reg === Index_Check || action_reg === Update) && cnt_in == 4)
		 																			|-> (##[0:999] inf.out_valid == 1))begin

																				end
		else begin
			$display("\033[1;31mAssertion 2 is violated\033[0m");
			  $fatal;
		end
		
		assertion_latency2: assert property (@(posedge clk)( (action_reg === Check_Valid_Date) && inf.data_no_valid === 1)
		 																			|-> (##[1:1000] inf.out_valid == 1))begin

																				end
		else begin
			$display("\033[1;31mAssertion 2 is violated\033[0m");
			  $fatal;
		end
	end

	//================================================================
	// 3. If action is complete (complete=1), warn_msg should be 2'b0 (No_Warn).
	//================================================================

	always@(posedge inf.complete)begin
    assertion_warn_msg: assert (inf.warn_msg === 0 && inf.out_valid === 1)begin
    end
    else begin
			$display("\033[1;31mAssertion 3 is violated\033[0m");
				$fatal;
    end
	end

	//================================================================
	// 4. Next input valid will be valid 1~4 cycles after previous input valid fall.
	//================================================================
	property input_index_check_request;
		@(posedge clk) inf.formula_valid ##[1:4] inf.mode_valid ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid ##[1:4] 
										inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid;
	endproperty : input_index_check_request

	property input_update_request;
	@(posedge clk) inf.date_valid ##[1:4] inf.data_no_valid ##[1:4] 
									inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid;
	endproperty : input_update_request

	property input_valid_date_request;
	@(posedge clk) inf.date_valid ##[1:4] inf.data_no_valid;
	endproperty : input_valid_date_request

	always@(posedge clk)begin
		assert property (@(posedge clk) inf.formula_valid |-> (##[1:4] inf.mode_valid))
		else begin 
			$display("\033[1;31mAssertion 4 is violated\033[0m");
			$fatal;
		end
		
		assert property (@(posedge clk) inf.mode_valid |-> (##[1:4] inf.date_valid))
		else begin 
			$display("\033[1;31mAssertion 4 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk) inf.date_valid |-> (##[1:4] inf.data_no_valid))
		else begin 
			$display("\033[1;31mAssertion 4 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk)((action_reg === Index_Check || action_reg === Update) && inf.data_no_valid === 1) |-> 
											(##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid))
		else begin 
			$display("\033[1;31mAssertion 4 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk) inf.sel_action_valid === 1 |-> (##[1:4] (inf.date_valid || inf.formula_valid)))
		else begin 
			$display("\033[1;31mAssertion 4 is violated\033[0m");
			$fatal;
		end

	end

	//================================================================
	// 5. All input valid signal won't overlap with each other.
	//================================================================

	always@(posedge clk)begin
		assert property (@(posedge clk) inf.formula_valid === 1 |-> (inf.mode_valid !==1 && inf.date_valid !==1 && inf.data_no_valid !==1 && inf.index_valid !==1 && inf.sel_action_valid !== 1) )
		else begin 
			$display("\033[1;31mAssertion 5 is violated\033[0m");
			$fatal;
		end
		
		assert property (@(posedge clk) inf.mode_valid === 1|-> (inf.formula_valid !==1 && inf.date_valid !==1 && inf.data_no_valid !==1 && inf.index_valid !==1
		 && inf.sel_action_valid !== 1))
		else begin 
			$display("\033[1;31mAssertion 5 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk) inf.date_valid === 1 |-> (inf.formula_valid !==1 && inf.mode_valid !==1 && inf.data_no_valid !==1 && inf.index_valid !== 1
		&& inf.sel_action_valid !== 1))
		else begin 
			$display("\033[1;31mAssertion 5 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk) inf.data_no_valid === 1|-> (inf.index_valid !==1 && inf.formula_valid !== 1 && inf.mode_valid !== 1 && inf.date_valid !==1
		&& inf.sel_action_valid !== 1))
		else begin 
			$display("\033[1;31mAssertion 5 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk) inf.index_valid === 1|-> (inf.formula_valid !== 1 && inf.mode_valid !== 1 && inf.date_valid !== 1 && inf.data_no_valid !== 1
		&& inf.sel_action_valid !== 1))
		else begin 
			$display("\033[1;31mAssertion 5 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk) inf.sel_action_valid === 1|-> (inf.formula_valid !== 1 && inf.mode_valid !== 1 && inf.date_valid !== 1 && inf.data_no_valid !== 1
		&& inf.index_valid !== 1))
		else begin 
			$display("\033[1;31mAssertion 5 is violated\033[0m");
			$fatal;
		end
	end

	

	//================================================================
	// 6. Out_valid can only be high for exactly 1 cycle.
	//================================================================
	
	always@(posedge clk)begin
		assert property (@(posedge clk) inf.out_valid |=> !inf.out_valid)
		else begin 
			$display("\033[1;31mAssertion 6 is violated\033[0m");
			$fatal;
		end
	end

	//================================================================
	// 7. Next operation will be valid 1~4 cycles after previous operation complete.
	//================================================================
	always@(posedge clk)begin
		assert property (@(posedge clk) inf.out_valid |-> (##[1:4]inf.sel_action_valid === 1))
		else begin
			$display("\033[1;31mAssertion 7 is violated\033[0m");
			$fatal;
		end
	end

	//================================================================
	// 8. The input date from pattern should adhere to the real calendar.
	// (ex: 2/29, 3/0, 4/31, 13/1 are illega)
	//================================================================
	logic month_31, month_30;

	always_comb begin
		month_31 = (inf.D.d_date[0].M === 1 || inf.D.d_date[0].M === 3 || inf.D.d_date[0].M === 5 || inf.D.d_date[0].M === 7 || 
								inf.D.d_date[0].M === 8 || inf.D.d_date[0].M === 10 || inf.D.d_date[0].M === 12);
	end

	always_comb begin
		month_30 = (inf.D.d_date[0].M === 4 || inf.D.d_date[0].M === 6 || inf.D.d_date[0].M === 9 || inf.D.d_date[0].M === 11);
	end

	always@(posedge clk)begin
		assert property (@(posedge clk) inf.date_valid === 1 |-> (inf.D.d_date[0].M > 0 && inf.D.d_date[0].M < 13))
		else begin 
			$display("\033[1;31mAssertion 8 is violated\033[0m");
			$fatal;
		end
			
			assert property (@(posedge clk) (inf.date_valid === 1 &&
			month_31) |-> 
			 (inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 32))
			else begin
				$display("\033[1;31mAssertion 8 is violated\033[0m");
					$fatal;
			end

		assert property (@(posedge clk) inf.date_valid === 1 && (month_30)
												|-> (inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 31))
		else begin 
			$display("\033[1;31mAssertion 8 is violated\033[0m");
			$fatal;
		end

		assert property (@(posedge clk) inf.date_valid === 1 && (inf.D.d_date[0].M === 2) |-> inf.D.d_date[0].D > 0 && inf.D.d_date[0].D < 29)
		else begin
			$display("\033[1;31mAssertion 8 is violated\033[0m");
			$fatal;
		end
	end

	//================================================================
	// 9. The AR_VALID signal should not overlap with the AW_VALID signal.
	//================================================================
	always@(posedge clk)begin
		assert property (@(posedge clk) inf.AR_VALID === 1 |=> inf.AW_VALID === 0)
		else begin
			$display("\033[1;31mAssertion 9 is violated\033[0m");
			$fatal;
		end
	end

endmodule