module FIFO_syn #(
    parameter WIDTH = 8,
    parameter WORDS = 64
) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
    flag_clk1_to_fifo
);

  input wclk, rclk;
  input rst_n;
  input winc;
  input [WIDTH-1:0] wdata;
  output reg wfull;
  input rinc;
  output reg [WIDTH-1:0] rdata;
  output reg rempty;

  // You can change the input / output of the custom flag ports
  output flag_fifo_to_clk2;
  input flag_clk2_to_fifo;

  output flag_fifo_to_clk1;
  input flag_clk1_to_fifo;

  wire [WIDTH-1:0] rdata_q;

  // Remember: 
  //   wptr and rptr should be gray coded
  //   Don't modify the signal name
  reg [$clog2(WORDS):0] wptr;
  reg [$clog2(WORDS):0] rptr;

  // reg to rdata
  reg rinc_reg;
  reg rempty_reg;
  wire [$clog2(WORDS):0] rq2_wptr;
  wire [$clog2(WORDS):0] wq2_rptr;

  wire [$clog2(WORDS):0] rptr_q;
  wire [$clog2(WORDS):0] r_addr_q;
  wire rempty_q;

  wire [$clog2(WORDS):0] wptr_q;
  wire [$clog2(WORDS):0] w_addr_q;
  wire wfull_q;




  //------------------------------------------//
  //                  OUTPUT		  		   
  //-----------------------------------------//

  always @(posedge rclk, negedge rst_n) begin
    if (!rst_n) begin
      rdata <= {WIDTH{1'b0}};
    end else begin
      if (rinc_reg && !rempty_reg) begin
        rdata <= rdata_q;
      end
    end
  end
  //-------------------------------------//
  //                SRAM		  		  
  //------------------------------------//

  reg [6:0] w_addr;
  reg [6:0] r_addr;
  wire m_wen;

  assign m_wen = !(winc & !wfull);

  // A write, B read
  DUAL_64X8X1BM1 u_dual_sram (
      .A0  (w_addr[0]),
      .A1  (w_addr[1]),
      .A2  (w_addr[2]),
      .A3  (w_addr[3]),
      .A4  (w_addr[4]),
      .A5  (w_addr[5]),
      .B0  (r_addr[0]),
      .B1  (r_addr[1]),
      .B2  (r_addr[2]),
      .B3  (r_addr[3]),
      .B4  (r_addr[4]),
      .B5  (r_addr[5]),
      .DOA0(),
      .DOA1(),
      .DOA2(),
      .DOA3(),
      .DOA4(),
      .DOA5(),
      .DOA6(),
      .DOA7(),
      .DOB0(rdata_q[0]),
      .DOB1(rdata_q[1]),
      .DOB2(rdata_q[2]),
      .DOB3(rdata_q[3]),
      .DOB4(rdata_q[4]),
      .DOB5(rdata_q[5]),
      .DOB6(rdata_q[6]),
      .DOB7(rdata_q[7]),
      .DIA0(wdata[0]),
      .DIA1(wdata[1]),
      .DIA2(wdata[2]),
      .DIA3(wdata[3]),
      .DIA4(wdata[4]),
      .DIA5(wdata[5]),
      .DIA6(wdata[6]),
      .DIA7(wdata[7]),
      .DIB0(1'b0),
      .DIB1(1'b0),
      .DIB2(1'b0),
      .DIB3(1'b0),
      .DIB4(1'b0),
      .DIB5(1'b0),
      .DIB6(1'b0),
      .DIB7(1'b0),
      .WEAN(m_wen),
      .WEBN(1'b1),
      .CKA (wclk),
      .CKB (rclk),
      .CSA (1'b1),
      .CSB (1'b1),
      .OEA (1'b1),
      .OEB (1'b1)
  );

  //----------------------------------//

  NDFF_BUS_syn #(
      .WIDTH(7)
  ) u1_ndff_bus (
      .D(wptr),
      .clk(rclk),
      .Q(rq2_wptr),
      .rst_n(rst_n)
  );

  NDFF_BUS_syn #(
      .WIDTH(7)
  ) u2_ndff_bus (
      .D(rptr),
      .clk(wclk),
      .Q(wq2_rptr),
      .rst_n(rst_n)
  );

  // read

  assign r_addr_q = r_addr + (rinc & !rempty);
  assign rptr_q   = (r_addr_q >> 1) ^ r_addr_q;  // gray code
  assign rempty_q = (rq2_wptr == rptr_q);

  always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
      rinc_reg <= 1'b0;
    end else begin
      rinc_reg <= rinc;
    end
  end

  always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
      rempty_reg <= 1'b1;
    end else begin
      rempty_reg <= rempty;
    end
  end

  always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
      r_addr <= 0;
    end else begin
      r_addr <= r_addr_q;
    end
  end

  always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
      rptr <= 0;
    end else begin
      rptr <= rptr_q;
    end
  end

  always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
      rempty <= 1'b1;
    end else begin
      rempty <= rempty_q;
    end
  end

  // write

  assign w_addr_q = w_addr + !m_wen;
  assign wptr_q = (w_addr_q >> 1) ^ w_addr_q;  // gray code
  assign wfull_q = ({~wq2_rptr[$clog2(
      WORDS
  ):$clog2(
      WORDS
  )-1], wq2_rptr[$clog2(
      WORDS
  )-2:0]} == wptr_q);

  always @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
      w_addr <= 7'b0;
    end else begin
      w_addr <= w_addr_q;
    end
  end

  always @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= 0;
    end else begin
      wptr <= wptr_q;
    end
  end

  always @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
      wfull <= 1'b0;
    end else begin
      wfull <= wfull_q;
    end
  end


endmodule
