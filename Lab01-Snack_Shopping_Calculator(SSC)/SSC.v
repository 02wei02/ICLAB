//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price,
    // Output signals
    out_valid,
    out_change
  );

  //================================================================
  //   INPUT AND OUTPUT DECLARATION
  //================================================================
  input [63:0] card_num;
  input [8:0] input_money;
  input [31:0] snack_num;
  input [31:0] price;
  output out_valid;
  output [8:0] out_change;

  //================================================================
  //    Wire & Registers
  //================================================================
  // Declare the wire/reg you would use in your circuit
  // remember
  // wire for port connection and cont. assignment
  // reg for proc. assignment

  reg [7:0] sum;

  // wire [39:0] slices; // 9 * 2  = 18 needs 5 bits

  // assign slices[0+:5] = card_num[7:4] << 1;
  // assign slices[5+:5] = card_num[15:12] << 1;
  // assign slices[10+:5] = card_num[23:20] << 1;
  // assign slices[15+:5] = card_num[31:28] << 1;
  // assign slices[20+:5] = card_num[39:36] << 1;
  // assign slices[25+:5] = card_num[47:44] << 1;
  // assign slices[30+:5] = card_num[55:52] << 1;
  // assign slices[35+:5] = card_num[63:60] << 1;

  // reg [31:0] slices_d;

  // div_1 d1 (card_num[4+:4], slices_d[0+:4]);
  // div_1 d2 (card_num[12+:4], slices_d[4+:4]);
  // div_1 d3 (card_num[20+:4], slices_d[8+:4]);
  // div_1 d4 (card_num[28+:4], slices_d[12+:4]);
  // div_1 d5 (card_num[36+:4], slices_d[16+:4]);
  // div_1 d6 (card_num[44+:4], slices_d[20+:4]);
  // div_1 d7 (card_num[52+:4], slices_d[24+:4]);
  // div_1 d8 (card_num[60+:4], slices_d[28+:4]);

  // assign slices_d[0+:4] = (slices[0+:5] >= 10) ?  slices[0+:5] - 9 : slices[0+:5];
  // assign slices_d[4+:4] = (slices[5+:5] >= 10) ?  slices[5+:5] - 9 : slices[5+:5];
  // assign slices_d[8+:4] = (slices[10+:5] >= 10) ?  slices[10+:5] - 9 : slices[10+:5];
  // assign slices_d[12+:4] = (slices[15+:5] >= 10) ?  slices[15+:5] - 9 : slices[15+:5];
  // assign slices_d[16+:4] = (slices[20+:5] >= 10) ?  slices[20+:5] - 9 : slices[20+:5];
  // assign slices_d[20+:4] = (slices[25+:5] >= 10) ?  slices[25+:5] - 9 : slices[25+:5];
  // assign slices_d[24+:4] = (slices[30+:5] >= 10) ?  slices[30+:5] - 9 : slices[30+:5];
  // assign slices_d[28+:4] = (slices[35+:5] >= 10) ?  slices[35+:5] - 9 : slices[35+:5];

  reg [39:0] slices; // 8 slices, each 5 bits wide
  reg [31:0] slices_d; // 8 slices_d, each 4 bits wide
  integer i;

  // always @(*) begin
  //     // Loop for card_num to slices assignment
  //     for (i = 0; i < 8; i = i + 1) begin
  //         slices[i*5 +: 5] = card_num[(i*8 + 4) +: 4] << 1; // Shift card_num[7:4], [15:12], etc.
  //     end

  //     // Loop for slices to slices_d assignment
  //     for (i = 0; i < 8; i = i + 1) begin
  //         slices_d[i*4 +: 4] = ( slices[i*5 +: 5] >= 10) ? slices[i*5 +: 5] - 9 : slices[i*5 +: 5];
  //     end
  // end

  always@(*)
  begin   // Loop for slices to slices_d assignment
    for (i = 0; i < 8; i = i + 1)
    begin
      slices_d[i*4 +: 4] = ( {card_num[(i*8 + 4) +: 4],1'b0} >= 10) ? {card_num[(i*8 + 4) +: 4],1'b0} - 9 :{card_num[(i*8 + 4) +: 4],1'b0};
    end
  end


  assign sum = slices_d[0+:4] +
         slices_d[4+:4] +
         slices_d[8+:4] +
         slices_d[12+:4] +
         slices_d[16+:4] +
         slices_d[20+:4] +
         slices_d[24+:4] +
         slices_d[28+:4] + card_num[0+:4] + card_num[8+:4]+ card_num[16+:4] + card_num[24+:4] + card_num[32+:4] + card_num[40+:4] + card_num[48+:4] + card_num[56+:4];



  // Initialize the first sum element

  // card_valid(sum , out_valid);
  assign	out_valid = (sum % 10 == 0)? 1'b1 : 1'b0;

  reg [63:0] sort;

  wire [63:0] total;

  mul m1(snack_num[3:0], price[3:0], total[7:0]);
  mul m2(snack_num[7:4], price[7:4], total[15:8]);
  mul m3(snack_num[11:8], price[11:8],total[23:16]);
  mul m4(snack_num[15:12], price[15:12],total[31:24]);
  mul m5(snack_num[19:16], price[19:16],total[39:32]);
  mul m6(snack_num[23:20], price[23:20],total[47:40]);
  mul m7(snack_num[27:24], price[27:24],total[55:48]);
  mul m8(snack_num[31:28], price[31:28],total[63:56]);

  // assign total[7:0] =  snack_num[3:0] *  price[3:0];
  // assign total[15:8] = snack_num[7:4] *  price[7:4];
  // assign total[23:16] = snack_num[11:8] *  price[11:8];
  // assign total[31:24] = snack_num[15:12] *  price[15:12];
  // assign total[39:32] = snack_num[19:16] *  price[19:16];
  // assign total[47:40] = snack_num[23:20]*  price[23:20];
  // assign total[55:48] = snack_num[27:24] * price[27:24];
  // assign total[63:56] = snack_num[31:28] *  price[31:28];

  wire [7:0] t1, t2, t3, t4, t5, t6, t7, t8;
  wire [7:0] lev1, lev2, lev3, lev4, lev5, lev6, lev7, lev8;
  wire [7:0] lev1_1, lev1_2, lev1_3, lev1_4, lev1_5, lev1_6, lev1_7, lev1_8;
  wire [7:0] lev2_1, lev2_2, lev2_3, lev2_4, lev2_5, lev2_6, lev2_7, lev2_8;
  wire [7:0] lev3_1, lev3_2, lev3_3, lev3_4, lev3_5, lev3_6, lev3_7, lev3_8;
  wire [7:0] lev4_1, lev4_2, lev4_3, lev4_4, lev4_5, lev4_6, lev4_7, lev4_8;
  wire [7:0] lev5_1, lev5_2, lev5_3, lev5_4, lev5_5, lev5_6, lev5_7, lev5_8;


  assign t1 = total[7:0];
  assign t2 = total[15:8];
  assign t3 = total[23:16];
  assign t4 = total[31:24];
  assign t5 = total[39:32];
  assign t6 = total[47:40];
  assign t7 = total[55:48];
  assign t8 = total[63:56];

  // assign sort[0+:8] = lev2_1;
  // assign sort[8+:8] = lev4_2;
  // assign sort[16+:8] = lev4_3;
  // assign sort[24+:8] = lev5_4;
  // assign sort[32+:8] = lev5_5;
  // assign sort[40+:8] = lev4_6;
  // assign sort[48+:8] = lev4_7;
  // assign sort[56+:8] =  lev2_8;

  // assign sort[0+:8] = lev2_1;
  // assign sort[8+:8] = lev4_2;
  // assign sort[16+:8] = lev5_3;
  // assign sort[24+:8] = lev4_4;
  // assign sort[32+:8] = lev4_5;
  // assign sort[40+:8] = lev5_6;
  // assign sort[48+:8] = lev4_7;
  // assign sort[56+:8] = lev2_8;

  // bitonic_sorter bs({t1, t2, t3, t4, t5, t6, t7, t8},
  // 				{sort[0+:8], sort[8+:8],
  // 				sort[16+:8],
  // 				sort[24+:8],
  // 				sort[32+:8],
  // 				sort[40+:8],
  // 				sort[48+:8],
  // 				sort[56+:8]});

  comp c1(t5, t1, lev5, lev1);
  comp c2(t6, t2, lev6, lev2);
  comp c3(t7, t3, lev7, lev3);
  comp c4(t8, t4, lev8, lev4);
  comp c5(lev3, lev1, lev1_3, lev1_1);
  comp c6(lev4, lev2, lev1_4, lev1_2);
  comp c7(lev7, lev5, lev1_7, lev1_5);
  comp c8(lev8, lev6, lev1_8, lev1_6);
  comp c9(lev1_5, lev1_3, lev2_5, lev2_3);
  comp c10(lev1_6, lev1_4, lev2_6, lev2_4);
  comp c11(lev1_2, lev1_1, lev2_2, sort[7:0]);
  comp c12(lev2_4, lev2_3, lev3_4, lev3_3);
  comp c13(lev2_6, lev2_5, lev3_6, lev3_5);
  comp c14(lev1_8, lev1_7, sort[63:56], lev2_7);
  comp c15(lev3_5, lev2_2, lev4_5, lev3_2);
  comp c16(lev2_7, lev3_4, lev3_7, lev4_4);
  comp c17(lev3_3, lev3_2, sort[23:16], sort[15:8]);
  comp c18(lev4_5, lev4_4, sort[39:32], sort[31:24]);
  comp c19(lev3_7, lev3_6, sort[55:48], sort[47:40]);

  // comp c1(t4, t2, lev4, lev2);
  // comp c2(t3, t1, lev3, lev1);
  // comp c3(t7, t5, lev7, lev5);
  // comp c4(t8, t6, lev8, lev6);
  // comp c5(lev8, lev4, lev1_8, lev1_4);
  // comp c6(lev7, lev3, lev1_7, lev1_3);
  // comp c7(lev6, lev2, lev1_6, lev1_2);
  // comp c8(lev5, lev1, lev1_5, lev1_1);
  // comp c9 (lev1_8, lev1_7, lev2_8, lev2_7);
  // comp c10(lev1_6, lev1_5, lev2_6, lev2_5);
  // comp c11(lev1_4, lev1_3, lev2_4, lev2_3);
  // comp c12(lev1_2, lev1_1, lev2_2, lev2_1);
  // comp c13(lev2_6, lev2_4, lev3_6, lev3_4);
  // comp c14(lev2_5, lev2_3, lev3_5, lev3_3);
  // comp c15(lev2_7, lev3_4, lev3_7, lev4_4);
  // comp c16(lev3_5, lev2_2, lev4_5, lev3_2);
  // comp c17(lev3_7, lev3_6, lev4_7, lev4_6);
  // comp c18(lev4_5, lev4_4, lev5_5, lev5_4);
  // comp c19(lev3_3, lev3_2, lev4_3, lev4_2);

  // comp c1(t2, t1, lev2, lev1);
  // comp c2(t4, t3, lev4, lev3);
  // comp c3(t6, t5, lev6, lev5);
  // comp c4(t8, t7, lev8, lev7);
  // comp c5(lev3, lev1, lev1_3, lev1_1);
  // comp c6(lev4, lev2, lev1_4, lev1_2);
  // comp c7(lev7, lev5, lev1_7, lev1_5);
  // comp c8(lev8, lev6, lev1_8, lev1_6);
  // comp c9 (lev1_3, lev1_2, lev2_3, lev2_2);
  // comp c10(lev1_7, lev1_6, lev2_7, lev2_6);
  // comp c11(lev1_5, lev1_1, lev2_5, lev2_1);
  // comp c12(lev2_6, lev2_2, lev3_6, lev3_2);
  // comp c13(lev2_7, lev2_3, lev3_7, lev3_3);
  // comp c14(lev1_8, lev1_4, lev2_8, lev2_4);
  // comp c15(lev2_5, lev3_3, lev3_5, lev4_3);
  // comp c16(lev3_6, lev2_4, lev4_6, lev3_4);
  // comp c17(lev4_3, lev3_2, lev5_3, lev4_2);
  // comp c18(lev3_5, lev3_4, lev4_5, lev4_4);
  // comp c19(lev3_7, lev4_6, lev4_7, lev5_6);


  wire signed [9:0] change1, change2;
  wire signed [9:0] change3, change4;
  wire signed [10:0] change5, change6;
  wire signed [10:0] change7, change8;


  assign change1 = sort[56+:8];
  assign change2 = change1 + sort[48+:8];
  assign change3 = change2 + sort[40+:8];
  assign change4 = change3 + sort[32+:8];
  assign change5 = change4 + sort[24+:8];
  assign change6 = change5 + sort[16+:8];
  assign change7 = change6 + sort[8+:8];
  assign change8 = change7 + sort[0+:8];


  // assign change1 = sort[0+:8];
  // assign change2 = change1 + sort[8+:8];
  // assign change3 = change2 + sort[16+:8];
  // assign change4 = change3 + sort[24+:8];
  // assign change5 = change4 + sort[32+:8];
  // assign change6 = change5 + sort[40+:8];
  // assign change7 = change6 + sort[48+:8];
  // assign change8 = change7 + sort[56+:8];

  reg [8:0] change_money;

  always @(*)
  begin
    case (out_valid)
      1'b0:
        change_money = input_money;
      1'b1:
      begin
        case (1'b1) // Use a case where the first matching condition is executed
          (input_money >= change8): change_money = input_money - change8;
          (input_money >= change7): change_money = input_money - change7;
          (input_money >= change6): change_money = input_money - change6;
          (input_money >= change5): change_money = input_money - change5;
          (input_money >= change4): change_money = input_money - change4;
          (input_money >= change3): change_money = input_money - change3;
          (input_money >= change2): change_money = input_money - change2;
          (input_money >= change1): change_money = input_money - change1;
          default:
            change_money = input_money;
        endcase
      end
    endcase
  end

  assign out_change = change_money;

  // always@(*)begin
  // 	if(out_valid == 1'b0)
  // 		remain = input_money;
  // 	else if(input_money >= change8)
  // 		remain = input_money - change8;
  // 	else if(input_money >= change7)
  // 		remain = input_money - change7;
  // 	else if(input_money >= change6)
  // 		remain = input_money - change6;
  // 	else if(input_money >= change5)
  // 		remain = input_money - change5;
  // 	else if(input_money >= change4)
  // 		remain = input_money - change4;
  // 	else if(input_money >= change3)
  // 		remain = input_money - change3;
  // 	else if(input_money >= change2)
  // 		remain = input_money - change2;
  // 	else if(input_money >= change1)
  // 		remain = input_money - change1;
  // 	else remain = input_money;
  // end


  // reg [8:0] change_temp [7:0];

  // assign out_change = change_temp[7];
  // always @(*) begin
  // 	if(out_valid == 1'b1)begin
  // 		change_temp[0] = (input_money >= sort[56+:8]) ? input_money - sort[56+:8] : input_money;
  // 		change_temp[1] =  (change_temp[0] >= sort[48+:8] && change_temp[0] != input_money) ? change_temp[0] - sort[48+:8] : change_temp[0];
  // 		change_temp[2] =  (change_temp[1] >= sort[40+:8] && change_temp[0] != change_temp[1]) ? change_temp[1] - sort[40+:8] : change_temp[1];
  // 		change_temp[3] =  (change_temp[2] >= sort[32+:8] && change_temp[1] != change_temp[2]) ? change_temp[2] - sort[32+:8] : change_temp[2];
  // 		change_temp[4] =  (change_temp[3] >= sort[24+:8] && change_temp[2] != change_temp[3]) ? change_temp[3] - sort[24+:8] : change_temp[3];
  // 		change_temp[5] =  (change_temp[4] >= sort[16+:8] && change_temp[3] != change_temp[4]) ? change_temp[4] - sort[16+:8] : change_temp[4];
  // 		change_temp[6] =  (change_temp[5] >= sort[8+:8] && change_temp[4] != change_temp[5]) ? change_temp[5] - sort[8+:8] : change_temp[5];
  // 		change_temp[7] =  (change_temp[6] >= sort[0+:8] && change_temp[5] != change_temp[6]) ? change_temp[6] - sort[0+:8] : change_temp[6];
  // 	end
  // 	else change_temp[7] = input_money;
  // end

  //================================================================
  //    DESIGN
  //================================================================

endmodule


// module mul(a,b,out); // multiplexer
//     input [3:0] a,b;
//     output [7:0] out;
//     wire [7:0]w0,w1,w2,w3;
// 	assign w0 = a[0]?{4'b0,b}:8'b0;
// 	assign w1 = a[1]?{3'b0,b,1'b0}:8'b0;
// 	assign w2 = a[2]?{2'b0,b,2'b0}:8'b0;
// 	assign w3 = a[3]?{1'b0,b,3'b0}:8'b0;
//     assign out = w0 + w1 + w2 + w3;
// endmodule

module mul(a, b, out); // 4x4 bit multiplier
  input [3:0] a, b;
  output [7:0] out;
  assign out = (a[0] ? b : 8'b0) +
         (a[1] ? (b << 1) : 8'b0) +
         (a[2] ? (b << 2) : 8'b0) +
         (a[3] ? (b << 3) : 8'b0);
endmodule


module comp(a, b , outa, outb); // compare
  input [7:0] a, b;
  output reg [7:0] outa, outb;

  // always@(*)begin
  // 	case(a>b)
  // 	1'b1: {outa, outb} = {a,b} ;
  // 	default: {outa, outb} =  {b,a};
  // 	endcase
  // end
  assign {outa, outb} = (a>b)? {a,b} : {b,a};
  // always@(*)begin
  // 	if(a > b) begin
  // 		outa = a;
  // 		outb = b;
  // 	end
  // 	else begin
  // 		outa = b;
  // 		outb = a;
  // 	end
  // end
endmodule


module div_1(in, out);
  input [3:0] in;
  output reg[3:0] out;

  always@(*)
  case(in)
    4'd1:
      out = 4'd2;
    4'd2:
      out = 4'd4;
    4'd3:
      out = 4'd6;
    4'd4:
      out = 4'd8;
    4'd5:
      out = 4'd1;
    4'd6:
      out = 4'd3;
    4'd7:
      out = 4'd5;
    4'd8:
      out = 4'd7;
    4'd9:
      out = 4'd9;
    default:
      out = 4'd0;
  endcase

endmodule

module card_valid(in, out);
  input [7:0] in;
  output reg out;

  always@(*)
  begin
    case(in)
      8'd0:
        out = 1'b1;
      8'd10:
        out = 1'b1;
      8'd20:
        out = 1'b1;
      8'd30:
        out = 1'b1;
      8'd40:
        out = 1'b1;
      8'd50:
        out = 1'b1;
      8'd60:
        out = 1'b1;
      8'd70:
        out = 1'b1;
      8'd80:
        out = 1'b1;
      8'd90:
        out = 1'b1;
      8'd100:
        out = 1'b1;
      8'd110:
        out = 1'b1;
      8'd120:
        out = 1'b1;
      8'd130:
        out = 1'b1;
      8'd140:
        out = 1'b1;
      default:
        out = 1'b0;
    endcase
  end
endmodule

module sorting(total, sort);

  parameter SIZE = 8;
  parameter NUM_VALS = 8;

  input [SIZE*NUM_VALS-1:0] total;
  output reg [SIZE*NUM_VALS-1:0] sort;

  integer i, j;
  reg [SIZE-1:0] temp;
  reg [SIZE-1:0] array [1:NUM_VALS];
  always @(*)
  begin
    for (i = 0; i < NUM_VALS; i = i + 1)
    begin
      array[i+1] = total[i*SIZE +: SIZE];
    end

    for (i = NUM_VALS; i > 0; i = i - 1)
    begin
      for (j = 1 ; j < i; j = j + 1)
      begin
        if (array[j] < array[j + 1])
        begin
          temp         = array[j];
          array[j]     = array[j + 1];
          array[j + 1] = temp;
        end
      end
    end

    for (i = 0; i < NUM_VALS; i = i + 1)
    begin
      sort[i*SIZE +: SIZE] = array[i+1];
    end
  end
endmodule

module bitonic_sorter #(parameter N = 8, DATA_WIDTH = 8)(
    input [DATA_WIDTH-1:0] data_in [0:N-1], // Input data array
    output reg [DATA_WIDTH-1:0] data_out [0:N-1]// Sorted output data

    reg [DATA_WIDTH-1:0] arr [0:N-1];  // Array for sorting
    reg [DATA_WIDTH-1:0] temp;  // Temporary register for swapping
    integer k, j, i, l;
    // XOR operation function
    function integer bitwiseXOR;
      input integer a, b;
      begin
        bitwiseXOR = a ^ b;
      end
    endfunction

    // AND operation function
    function integer bitwiseAND;
      input integer a, b;
      begin
        bitwiseAND = a & b;
      end
    endfunction

    // Main sorting process
    always @(*)
    begin
      begin
        // Initialize input data
        for (i = 0; i < N; i = i + 1)
        begin
          arr[i] = data_in[i];
        end

        // Outer k loop: k doubles each iteration
        for (k = 2; k <= N; k = k * 2)
        begin
          // Middle j loop: j halves each iteration
          for (j = k / 2; j > 0; j = j / 2)
          begin
            // Inner i loop: iterate through the array
            for (i = 0; i < N; i = i + 1)
            begin
              // Calculate l = i ^ j
              l = bitwiseXOR(i, j);

              // If l > i, perform comparison and swap
              if (l > i)
              begin
                if (((bitwiseAND(i, k) == 0) && (arr[i] < arr[l])) ||
                    ((bitwiseAND(i, k) != 0) && (arr[i] > arr[l])))
                begin
                  // Swap arr[i] and arr[l]
                  temp = arr[i];
                  arr[i] = arr[l];
                  arr[l] = temp;
                end
              end
            end
          end
        end

        // Output the sorted data
        for (i = 0; i < N; i = i + 1)
        begin
          data_out[i] = arr[i];
        end
      end
    end
  endmodule
