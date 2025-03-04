module Handshake_syn #(
    parameter WIDTH = 8
) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

  input sclk, dclk;
  input rst_n;
  input sready;
  input [WIDTH-1:0] din;
  input dbusy;
  output sidle;
  output reg dvalid;
  output reg [WIDTH-1:0] dout;

  // You can change the input / output of the custom flag ports
  output reg flag_handshake_to_clk1;
  input flag_clk1_to_handshake;

  output flag_handshake_to_clk2;
  input flag_clk2_to_handshake;

  // Remember:
  //   Don't modify the signal name
  reg sreq;
  wire dreq;
  reg dack;
  wire sack;

  //----------------------------------//
  //          Reg and Wire		 		   //
  //--------------------------------//

  reg [WIDTH-1:0] data;


  //----------------------------------//
  //              Control		  		   //
  //--------------------------------//
  always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
      sreq <= 1'b0;
    end else begin
      case (1'b1)
        (sack): begin
          sreq <= 1'b0;
        end
        (sready): begin
          sreq <= 1'b1;
        end
        default: begin
          sreq <= sreq;
        end
      endcase
    end
  end

  always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
      dack <= 1'b0;
    end else begin
      if (dreq) begin
        if (!dbusy) begin
          dack <= 1'b1;
        end else begin
          dack <= dack;
        end
      end else if (dack) begin
        dack <= 1'b0;
      end else begin
        dack <= dack;
      end
    end
  end

  always @(*) begin
    flag_handshake_to_clk1 = sack;
  end

  assign sidle = !sreq && !sack;

  NDFF_syn u1_ndff (
      .D(sreq),
      .clk(dclk),
      .Q(dreq),
      .rst_n(rst_n)
  );

  NDFF_syn u2_ndff (
      .D(dack),
      .clk(sclk),
      .Q(sack),
      .rst_n(rst_n)
  );

  //----------------------------------//


  always @(posedge sclk, negedge rst_n) begin
    if (!rst_n) begin
      data <= {WIDTH{1'b0}};
    end else begin
      if (sready && !sreq) begin
        data <= din;
      end else begin
        data <= data;
      end
    end
  end

  //----------------------------------//
  //              Output 		  		   //
  //--------------------------------//

  always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
      dout <= {WIDTH{1'b0}};
    end else begin
      if (dreq && !dbusy) begin
        dout <= data;
      end  // DAT_HS_STBL
			else begin
        dout <= dout;
      end
    end
  end

  always @(posedge dclk, negedge rst_n) begin
    if (!rst_n) begin
      dvalid <= 1'b0;
    end else begin
      if (dreq) begin  // ACK_WO_SREQ
        if (!dbusy) begin
          dvalid <= 1'b1;
        end else begin
          dvalid <= dvalid;
        end
      end else begin  // NAK_WO_SREQ
        dvalid <= 1'b0;
      end
    end
  end


endmodule
