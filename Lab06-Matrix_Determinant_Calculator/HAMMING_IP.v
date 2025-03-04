//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
  );

  // ===============================================================
  // Input & Output
  // ===============================================================
  // input 9~15 bits
  input [IP_BIT+4-1:0]  IN_code;
  // output 5~11 bits
  output reg [IP_BIT-1:0] OUT_code;

  // ===============================================================
  // Design
  // ===============================================================
  reg [14:0] code_in; // to expand the input code into 15 bits
  wire [3:0] error_bit; // find the error bit
  reg [14:0] code_corrected; // corrected code

  // always@(*)
  // begin
  //   case(IP_BIT)
  //     5:
  //       code_in = {IN_code, {6{1'b0}}};
  //     6:
  //       code_in = {IN_code, {5{1'b0}}};
  //     7:
  //       code_in = {IN_code, {4{1'b0}}};
  //     8:
  //       code_in = {IN_code, {3{1'b0}}};
  //     9:
  //       code_in = {IN_code, {2{1'b0}}};
  //     10:
  //       code_in = {IN_code, {1{1'b0}}};
  //     default:
  //       code_in = IN_code;
  //   endcase
  // end

  always@(*)
  begin
    code_in = {IN_code, {11-IP_BIT{1'b0}}};
  end

  assign error_bit[0] = code_in[0]^code_in[2]^code_in[4]^code_in[6]^code_in[8]^code_in[10]^code_in[12]^code_in[14];
  assign error_bit[1] = code_in[0]^code_in[1]^code_in[4]^code_in[5]^code_in[8]^code_in[9]^code_in[12]^code_in[13];
  assign error_bit[2] = code_in[0]^code_in[1]^code_in[2]^code_in[3]^code_in[8]^code_in[9]^code_in[10]^code_in[11];
  assign error_bit[3] = code_in[0]^code_in[1]^code_in[2]^code_in[3]^code_in[4]^code_in[5]^code_in[6]^code_in[7];

  always @(*)
  begin
    // Correct the error by flipping the erroneous bit and then extract the desired bits
    code_corrected = (code_in ^ (1'b1 << (15 - error_bit)));
  end

  always@(*)
  begin
    OUT_code[IP_BIT-1] = code_corrected[12];
    OUT_code[IP_BIT-2:IP_BIT-4] = code_corrected[10:8];
    OUT_code[IP_BIT-5:0] = code_corrected[6:11-IP_BIT];
  end

endmodule

// always@(*)begin
// 	case(IP_BIT)
// 		5: begin
// 			OUT_code[4] = code_corrected[12];
// 			OUT_code[3:1] = code_corrected[10:8];
// 			OUT_code[0] = code_corrected[6];
// 		end
// 		6: begin
// 			OUT_code[5] = code_corrected[12];
// 			OUT_code[4:2] = code_corrected[10:8];
// 			OUT_code[1:0] = code_corrected[6:5];
// 		end
// 		7: begin
// 			OUT_code[6] = code_corrected[12];
// 			OUT_code[5:3] = code_corrected[10:8];
// 			OUT_code[2:0] = code_corrected[6:4];
// 		end
// 		8: begin
// 			OUT_code[7] = code_corrected[12];
// 			OUT_code[6:4] = code_corrected[10:8];
// 			OUT_code[3:0] = code_corrected[6:3];
// 		end
// 		9: begin
// 			OUT_code[8] = code_corrected[12];
// 			OUT_code[7:5] = code_corrected[10:8];
// 			OUT_code[4:0] = code_corrected[6:2];
// 		end
// 		10: begin
// 			OUT_code[9] = code_corrected[12];
// 			OUT_code[8:6] = code_corrected[10:8];
// 			OUT_code[5:0] = code_corrected[6:1];
// 		end
// 		11: begin
// 			OUT_code[10] = code_corrected[12];
// 			OUT_code[9:7] = code_corrected[10:8];
// 			OUT_code[6:0] = code_corrected[6:0];
// 		end
// 		default: begin
// 			OUT_code = 0;
// 		end
// 	endcase
// end
