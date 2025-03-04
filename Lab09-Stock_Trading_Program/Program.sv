module Program(input clk, INF.Program_inf inf);
import usertype::*;


  //              INTEGERS & PARAMETERS

  integer i,j,k;
  typedef enum logic [2:0]{
            IDLE,
            ADDR_GET,
            WORK,
            UPDATE_ACT,
            OUT
          } state_t;

  //                           REGISTERS

  state_t state_cs, state_ns;
  Action     act_reg;
  Formula_Type     formula_reg;
  Mode     mode_reg;
	logic [7:0]     data_no_reg;
	Date date_reg;

  //sum =  index + variation
	logic signed [13:0]    sum [0:3];
	logic signed [12:0]    sum_underflow [0:3]; // underflow
	logic signed [12:0] 	buffer_index [0:3];
	logic [11:0]    update_dram [0:3];
  
  //from DRAM
	logic signed [12:0] dram_signed [0:3];

  // from input
  logic [11:0]    d_index_reg [0:3];
	// d_index_reg to signed
	logic signed [11:0]    variation [0:3];
  // abs between DRAM and d_index_reg
  logic [11:0]    g_a, g_b, g_c, g_d;
  logic [63:0]    R_DATA_reg;
	// from DRAM
  logic [3:0]     dram_month;
  logic [4:0]     dram_day;
	// calculated result
  logic [11:0]    result;
  logic [11:0]    threshold;
  
  logic [3:0]     cnt_index_valid;
  logic flag_warn_date, flag_risk_warn, flag_warn_overflow;
  logic flag_in;

	logic RB_valid;  

	// output
	Warn_Msg     warn_msg;
  logic           complete;


  //                             FSM

  always_ff @( posedge clk or negedge inf.rst_n)
  begin : STATE_CS_FF
    if (!inf.rst_n)
    begin
      state_cs <= IDLE;
    end
    else
    begin
      state_cs <= state_ns;
    end
  end


  assign RB_valid = (inf.R_VALID || inf.B_VALID)? 1'b1: 1'b0;

  always_comb
  begin : STATE_NS_COMB
    state_ns = state_cs;
    case(state_cs)
      IDLE:
      begin
					if(act_reg == Index_Check || act_reg == Update)begin
						if(cnt_index_valid == 'd4)begin 
								state_ns = ADDR_GET;
						end
					end
          else if(inf.data_no_valid) // can read from DRAM
          begin
            state_ns = ADDR_GET;
          end
      end
      ADDR_GET:
      begin
        if(RB_valid) // it's ok to read from DRAM (considering the hight b latency)
        begin
          state_ns = WORK;
        end
      end
      WORK:
      begin
        if((act_reg == Check_Valid_Date) || (act_reg == Index_Check) )
        begin
          state_ns = OUT;
        end
        else if(inf.W_READY && act_reg == Update)
        begin
          state_ns = UPDATE_ACT;
        end
      end
      UPDATE_ACT:
      begin
				if(RB_valid)begin
					if(flag_in || (inf.data_no_valid && act_reg != Update) || (act_reg == Update && cnt_index_valid == 3))
					begin
						state_ns = ADDR_GET;
					end
					if(!flag_in)
					begin
						state_ns = OUT;
					end
				end
      end
      OUT:
      begin
        state_ns = IDLE;
      end
      default:  begin
        state_ns = IDLE;
			end
    endcase
  end
  
  //                           COUNTER

  // always @(posedge clk or negedge inf.rst_n)
  // begin : CNT_INDEX_VALID_FF
  //   if (!inf.rst_n)
  //   begin
  //     cnt_index_valid <= 0;
  //   end
	// 	 else if(inf.index_valid)
  //   begin
  //     cnt_index_valid <= cnt_index_valid + 1'b1;
  //   end
  //   else if(state_cs == IDLE)
  //   begin
  //     cnt_index_valid <= 0;
  //   end
  // end
	always @(posedge clk or negedge inf.rst_n)begin
			if (!inf.rst_n)begin
				cnt_index_valid <= 'd0;
			end
			else if(state_cs == OUT)begin
				cnt_index_valid <= 'd0;
			end
			else if(inf.index_valid)
			begin
				cnt_index_valid <= cnt_index_valid + 1'b1;
			end
	end

	always_ff @( posedge clk or negedge inf.rst_n)
  begin
    if (!inf.rst_n)
    begin
      flag_in <= 1'b0;
    end
    else
    begin
      if(state_cs == UPDATE_ACT)
      begin
        flag_in <= 1'b0;
      end
      else if(act_reg == Update && cnt_index_valid == 4)
      begin
          flag_in <= 1'b1;
      end
      else if(inf.data_no_valid)
			begin
				flag_in <= 1'b1;
			end
    end
  end

  //                           INPUT

  always_ff@(posedge clk, negedge inf.rst_n)
  begin: DATE_REG_FF
    if(!inf.rst_n)
    begin
      date_reg <= 0;
    end
    else
    begin
      date_reg <= inf.date_valid ? inf.D.d_date[0]: date_reg;
    end
  end

  always_ff@(posedge clk, negedge inf.rst_n)
  begin: ACT_REG_FF
    if(!inf.rst_n)
    begin
      act_reg <= Index_Check;
    end
    else
    begin
      act_reg <= inf.sel_action_valid ? inf.D.d_act[0]: act_reg;
    end
  end

  always_ff@(posedge clk, negedge inf.rst_n)
  begin: FORMULA_REG_FF
    if(!inf.rst_n)
    begin
      formula_reg <= Formula_A;
    end
    else
    begin
      formula_reg <= inf.formula_valid ? inf.D.d_formula[0]: formula_reg;
    end
  end

  always_ff@(posedge clk, negedge inf.rst_n)
  begin: MODE_REG_FF
    if(!inf.rst_n)
    begin
      mode_reg <= Insensitive;
    end
    else
    begin
      mode_reg <= inf.mode_valid ? inf.D.d_mode[0]: mode_reg;
    end
  end


  always_ff @(posedge clk or negedge inf.rst_n)
  begin : INDEX_REG_FF
    if (!inf.rst_n)
    begin
      for(i = 0 ; i < 4 ; i++)
      begin
        d_index_reg[i] <= 0;
      end
    end
    else if (act_reg == Index_Check || act_reg == Update)
    begin 
			if(inf.index_valid)begin
				d_index_reg[0] <= inf.D.d_index[0]; // 0:D 1:C 2:B 3:A
				for(i = 0; i < 3; i++)
				begin
					d_index_reg[i+1] <= d_index_reg[i];
				end
			end
    end
  end

	assign variation[0] = d_index_reg[0];
	assign variation[1] = d_index_reg[1];
	assign variation[2] = d_index_reg[2];
	assign variation[3] = d_index_reg[3];


  //                           DRAM

  // read
  always_ff@(posedge clk, negedge inf.rst_n)
  begin: DATA_NO_REG_FF
    if(!inf.rst_n)
    begin
      data_no_reg <= 0;
    end
    else
    begin
      data_no_reg <= inf.data_no_valid ? inf.D.d_data_no[0]: data_no_reg;
    end
  end

  always_ff @(posedge clk or negedge inf.rst_n)
  begin : DRAM_ADDR_FF
    if(!inf.rst_n)
    begin
      inf.AR_ADDR <= 0;
			inf.AW_ADDR <= 0;
    end
    else
    begin
      inf.AR_ADDR <= {6'b100000,data_no_reg,3'b0};
			inf.AW_ADDR <= {6'b100000,data_no_reg,3'b0};
    end
  end


  always_ff @(posedge clk or negedge inf.rst_n)
  begin : AR_VALID_FF
    if (!inf.rst_n)
    begin
      inf.AR_VALID <= 1'b0;
    end
    else
    begin
      if (state_cs == IDLE || state_cs == UPDATE_ACT)
      begin
        inf.AR_VALID <= (state_ns == ADDR_GET)? 1'b1 : inf.AR_VALID;
      end
      else if (inf.AR_READY)
      begin
        inf.AR_VALID <= 1'b0;
      end
    end
  end

  always_ff@(posedge clk, negedge inf.rst_n)
  begin: R_READY_FF
    if(!inf.rst_n)
    begin
      inf.R_READY <= 1'b0;
    end
    else if(inf.R_VALID)
    begin
      inf.R_READY <= (inf.R_READY) ? 1'b0 : 1'b1;
    end
  end

  always_ff@(posedge clk or negedge inf.rst_n)
  begin: R_DATA_reg_FF
    if(!inf.rst_n)
    begin
      R_DATA_reg <= 0;
    end
    else
    begin
      R_DATA_reg <= (RB_valid)? inf.R_DATA : R_DATA_reg;
    end
  end
  // Dram read
  always_comb
  begin
    dram_day     = R_DATA_reg[0+:8];
    dram_signed[3] = R_DATA_reg[8+:12];
    dram_signed[2] = R_DATA_reg[20+:12];
    dram_month   = R_DATA_reg[32+:8];
    dram_signed[1] = R_DATA_reg[40+:12];
    dram_signed[0] = R_DATA_reg[52+:12];
  end

  // 								     Distance Calculation

	always_comb
	begin : G_ABCD_COMB
  	g_a = (dram_signed[0] >= d_index_reg[3]) ? (dram_signed[0] - d_index_reg[3]) : (d_index_reg[3] - dram_signed[0]);
  	g_b = (dram_signed[1] >= d_index_reg[2]) ? (dram_signed[1] - d_index_reg[2]) : (d_index_reg[2] - dram_signed[1]);
  	g_c = (dram_signed[2] >= d_index_reg[1]) ? (dram_signed[2] - d_index_reg[1]) : (d_index_reg[1] - dram_signed[2]);
  	g_d = (dram_signed[3] >= d_index_reg[0]) ? (dram_signed[3] - d_index_reg[0]) : (d_index_reg[0] - dram_signed[3]);
	end

  logic [11:0] sort_in [0:3];
  logic [11:0] sort_out [0:3];

  always_comb
  begin: SORT_IN_COMB
    sort_in[0] = dram_signed[0];
    sort_in[1] = dram_signed[1];
    sort_in[2] = dram_signed[2];
    sort_in[3] = dram_signed[3];
    if(formula_reg == Formula_F || formula_reg == Formula_G || formula_reg == Formula_H)
    begin
      sort_in[0] = g_a;
      sort_in[1] = g_b;
      sort_in[2] = g_c;
      sort_in[3] = g_d;
    end
  end

  //sorting network to result in sort_out
  sorting_network_4 sort1(.in1(sort_in[0]), .in2(sort_in[1]), .in3(sort_in[2]), .in4(sort_in[3]), .out1(sort_out[0]), .out2(sort_out[1])
                          , .out3(sort_out[2]), .out4(sort_out[3]));



  always_comb
  begin : RESULT_COMB
    result = 0;
    if (act_reg == Index_Check)
    begin
      case (formula_reg)
        Formula_A:
        begin
          result = (dram_signed[0] + dram_signed[1] + dram_signed[2] + dram_signed[3])/4;
        end
        Formula_B:
        begin
          result = sort_out[3] - sort_out[0];
        end
        Formula_C:
        begin
          result =   sort_out[0];
        end
        Formula_D:
        begin
          result = ((dram_signed[0] >= 2047) + (dram_signed[1] >= 2047) + (dram_signed[2] >= 2047) + (dram_signed[3] >= 2047));
        end
        Formula_E:
        begin
          result = ((dram_signed[0] >= d_index_reg[3]) + (dram_signed[1] >= d_index_reg[2]) + (dram_signed[2] >= d_index_reg[1]) + (dram_signed[3] >= d_index_reg[0]));
        end
        Formula_F:
        begin
          result = (sort_out[0] + sort_out[1] + sort_out[2]) / 3;
        end
        Formula_G:
        begin
          result = (sort_out[0] / 2) + (sort_out[1] / 4) + (sort_out[2] / 4);
        end
        Formula_H:
          result = ( (g_a + g_b) + (g_c + g_d)) / 4;
        default:
          result = 0;
      endcase
    end
  end


  //                          THRESHOLD

  always_comb
  begin : THRESHOLD_COMB
    threshold = 0;
    case (formula_reg)
      Formula_A,Formula_C :
      begin
        case (mode_reg)
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
        case (mode_reg)
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
        case (mode_reg)
          Insensitive:
            threshold = 3;
          Normal:
            threshold = 2;
          Sensitive:
            threshold = 1;
        endcase
      end
    endcase
  end

  //                       WARNING OPERATION



  assign flag_warn_date = (dram_month > date_reg.M) || ((dram_month == date_reg.M)&&(dram_day > date_reg.D));
  assign flag_risk_warn = result >= threshold;
  assign flag_warn_overflow =  (buffer_index[0][12] || buffer_index[1][12] || buffer_index[2][12] || buffer_index[3][12]
                                || sum[0][13] || sum[1][13] || sum[2][13] || sum[3][13]);

  //                     UPDATE OPERATION


	// Generate sum and next_index assignments
	generate
		for (genvar gen_i = 0; gen_i < 4; gen_i++) begin : GEN_SUM_NEXT_INDEX
				assign sum[gen_i] = dram_signed[gen_i] + variation[3 - gen_i];
				assign sum_underflow[gen_i] = sum[gen_i][13] ? 0 : sum[gen_i];
		end
	endgenerate

	// Sequential logic for buffer_index
	always_ff @(posedge clk or negedge inf.rst_n) begin : BUFFER_INDEX_FF
		if (!inf.rst_n) begin
				buffer_index[0] <= 0;
				buffer_index[1] <= 0;
				buffer_index[2] <= 0;
				buffer_index[3] <= 0;
		end else begin
				buffer_index[0] <= sum_underflow[0];
				buffer_index[1] <= sum_underflow[1];
				buffer_index[2] <= sum_underflow[2];
				buffer_index[3] <= sum_underflow[3];
		end
	end

	// Generate update_dram assignments
	generate
		for (genvar gen_i = 0; gen_i < 4; gen_i++) begin : GEN_UPDATE_INDEX
				assign update_dram[gen_i] = (buffer_index[gen_i][12]) ? 4095 : buffer_index[gen_i]; // 4095 = 12'b111111111111
		end
	endgenerate

	// Combinational logic for inf.W_DATA
	always_comb begin : W_DATA_COMB
		inf.W_DATA[52+:12] = update_dram[0];
		inf.W_DATA[40+:12] = update_dram[1];
		inf.W_DATA[32+:8]  = date_reg.M;
		inf.W_DATA[20+:12] = update_dram[2];
		inf.W_DATA[8+:12]  = update_dram[3];
		inf.W_DATA[0+:8]   = date_reg.D;
	end


  //                           DRAM WRITE

  always_ff@(posedge clk, negedge inf.rst_n)
  begin: B_READY_FF
    if(!inf.rst_n)
    begin
      inf.B_READY <= 1'b0;
    end
		else if(inf.B_VALID)begin
			inf.B_READY <= 1'b0;	
		end
		else if(inf.AW_READY)begin
			inf.B_READY <= 1'b1;
		end
  end

  always_ff @(posedge clk or negedge inf.rst_n)
  begin : W_VALID_FF
    if(!inf.rst_n)
    begin
      inf.W_VALID <= 1'b0;
    end
    else
    begin
			if(inf.W_READY)
      begin
        inf.W_VALID <= 1'b0;
      end
      else if(inf.AW_READY)
      begin
        inf.W_VALID <= 1'b1;
      end
    end
  end
	
  always_ff @(posedge clk or negedge inf.rst_n)
  begin : AW_VALID_FF
    if(!inf.rst_n)
    begin
      inf.AW_VALID <= 1'b0;
    end
    else
    begin
      if(act_reg == Update)
      begin
        if (inf.R_VALID)
        begin
          inf.AW_VALID <= 1'b1;
        end
        else
        begin
          inf.AW_VALID <= 1'b0;
        end
      end
      else if(inf.AW_READY)
      begin
        inf.AW_VALID <= 1'b0;
      end
    end
  end





  //                            OUTPUT

  always_ff@(posedge clk or negedge inf.rst_n)
  begin: OUT_VALID_FF
    if(!inf.rst_n)
    begin
      inf.out_valid <= 1'b0;
    end
    else
    begin
        inf.out_valid <= (state_ns == OUT)? 1'b1 : 1'b0;
    end
  end

  always_ff@(posedge clk or negedge inf.rst_n)
  begin: WARN_MSG_FF
    if(!inf.rst_n)
    begin
      inf.warn_msg  <= No_Warn;
      inf.complete <= 1'b0;
    end
    else
    begin
      if(state_ns == OUT)
      begin
        case(act_reg)
          Index_Check:
          begin
            if(flag_warn_date)
            begin
              inf.warn_msg <= Date_Warn;
            end
            else if(flag_risk_warn)
            begin
              inf.warn_msg <= Risk_Warn;
            end
            else
            begin
              inf.complete <= 1'b1;
            end
          end
          Update:
          begin
            if(flag_warn_overflow)
            begin
              inf.warn_msg <= Data_Warn;
            end
            else
            begin
              inf.complete <= 1'b1;
            end
          end
          Check_Valid_Date:
          begin
            if(flag_warn_date)
            begin
              inf.warn_msg <= Date_Warn;
            end
            else
            begin
              inf.complete <= 1'b1;
            end
          end
        endcase
      end
      else
      begin
        inf.warn_msg  <= No_Warn;
        inf.complete <= 1'b0;
      end
    end
  end

endmodule

// sorting network
// https://demonstrations.wolfram.com/SortingNetworks/
module sorting_network_4 (
    input  [11:0] in1, in2, in3, in4,
    output [11:0] out1, out2, out3, out4 //min to max
  );

  reg [11:0] lev1_1, lev1_2, lev1_3, lev1_4;
  reg [11:0] lev2_1, lev2_2, lev2_3, lev2_4;
  reg [11:0] lev3_1, lev3_2, lev3_3, lev3_4;

  assign {lev1_3, lev1_1} = (in3 > in1) ? {in3, in1} : {in1, in3};
  assign {lev1_4, lev1_2} = (in4 > in2) ? {in4, in2} : {in2, in4};
  assign {lev2_2, lev2_1} = (lev1_1 > lev1_2) ? {lev1_1, lev1_2} : {lev1_2, lev1_1};
  assign {lev2_4, lev2_3} = (lev1_3 > lev1_4) ? {lev1_3, lev1_4} : {lev1_4, lev1_3};
  assign {lev3_3, lev3_2} = (lev2_3 > lev2_2) ? {lev2_3, lev2_2} : {lev2_2, lev2_3};

  assign {out4, out3, out2, out1} = {lev2_4, lev3_3, lev3_2, lev2_1};

endmodule
