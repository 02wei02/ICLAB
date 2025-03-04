/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
    //INPUT
    rst_n,
    clk,
    in_valid,
    tetrominoes,
    position,
    //OUTPUT
    tetris_valid,
    score_valid,
    fail,
    score,
    tetris
);

    //---------------------------------------------------------------------
    //   PORT DECLARATION          
    //---------------------------------------------------------------------
    input rst_n, clk, in_valid;
    input [2:0] tetrominoes;
    input [2:0] position;
    output reg tetris_valid, score_valid, fail;
    output reg [3:0] score;
    output reg [71:0] tetris;


    //---------------------------------------------------------------------
    //   PARAMETER & INTEGER DECLARATION
    //---------------------------------------------------------------------

    parameter COL_SIZE = 4;  // 11 bits
    parameter WIDTH = 6;
    parameter IDLE = 0;
    parameter PROCESS = 1;
    parameter OK = 2;
    parameter ROUND = 3;
    integer i, j, k;

    //---------------------------------------------------------------------
    //   REG & WIRE DECLARATION
    //---------------------------------------------------------------------

    reg  [89:0] map;
    reg  [71:0] temp_tetris;
    reg  [ 3:0] score_ns;
    reg         fail_ns;
    reg         tetris_valid_ns;
    reg         score_valid_ns;
    // reg  [23:0] col_h;
    reg  [ 1:0] row_loc;  // the max width tetris is 4 
    // wire [ 3:0] col0r;  // relative to left position (the tetris column loc would = position(col) + row_loc * 6)
    // wire [ 3:0] col1r;
    // wire [ 3:0] col2r;
    // wire [ 3:0] col3r;

    wire [ 3:0] col0r;  // relative to left position (the tetris column loc would = position(col) + row_loc * 6)
    wire [ 3:0] col1r;
    wire [ 3:0] col2r;
    wire [ 3:0] col3r;

    wire [ 6:0] col0x6;  // x 6
    wire [ 6:0] col1x6;
    wire [ 6:0] col2x6;
    wire [ 6:0] col3x6;
    reg [1:0] state_cs, state_ns;
    reg [3:0] counter;  // 12 cycles 
    reg [4:0] counter_times;  // 16 tetriminoes in each round of game;
    reg       already_out_score;

    reg [2:0] tetrominoes_delay;
    reg [2:0] position_delay;
    //---------------------------------------------------------------------
    //   DESIGN
    //---------------------------------------------------------------------

    // always @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         position_lock <= 0;
    //     end else if (in_valid) position_lock <= position;
    // end

    reg       in_valid_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            position_delay    <= 3'b0;
            tetrominoes_delay <= 3'b0;
            in_valid_reg      <= 3'b0;
        end else if (in_valid) begin
            position_delay    <= position;
            tetrominoes_delay <= tetrominoes;
            in_valid_reg      <= in_valid;
        end else begin
            position_delay    <= position_delay;
            tetrominoes_delay <= tetrominoes_delay;
            in_valid_reg      <= in_valid;
        end
    end

    always @(posedge clk) begin
        if (in_valid) tetrominoes_delay <= tetrominoes;
    end

    always @(posedge clk) begin
        if (in_valid) in_valid_reg <= in_valid;
        else in_valid_reg <= 1'b0;
    end
    wire [2:0] position1;
    wire [2:0] position2;
    wire [2:0] position3;

    assign position1 = ((position + 1) > 5) ? position : position + 1;
    assign position2 = ((position + 2) > 5) ? position : position + 2;
    assign position3 = ((position + 3) > 5) ? position : position + 3;

    find_height h0 (
        .map   (map),
        .loc   (position),
        .height(col0r)
    );

    find_height h1 (
        .map   (map),
        .loc   (position1),
        .height(col1r)
    );

    find_height h2 (
        .map   (map),
        .loc   (position2),
        .height(col2r)
    );

    find_height h3 (
        .map   (map),
        .loc   (position3),
        .height(col3r)
    );

    assign col0x6 = col0r * WIDTH + position;
    assign col1x6 = col1r * WIDTH + position;
    assign col2x6 = col2r * WIDTH + position;
    assign col3x6 = col3r * WIDTH + position;

    // Finite State Machine: cs
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_cs <= IDLE;
        end else begin
            state_cs <= state_ns;
        end
    end


    // Finite State Machine: ns
    always @(*) begin
        case (state_cs)
            IDLE: begin
                if (in_valid) state_ns = PROCESS;
                else state_ns = IDLE;
            end
            PROCESS: begin
                if ((&map[0+:6] || &map[6+:6] || &map[12+:6] || &map[18+:6] || &map[24+:6] || &map[30+:6] || &map[36+:6] || &map[42+:6] || &map[48+:6] || &map[54+:6] || &map[60+:6] || &map[66+:6])) begin  // there is no line to delete
                    state_ns = PROCESS;
                end else if (fail_ns) state_ns = ROUND;
                else if (counter_times == 5'd15) begin
                    state_ns = ROUND;
                end else if (already_out_score == 1'b0) begin
                    state_ns = OK;
                end else state_ns = PROCESS;
                // end else if (counter == 4'd12) begin
                //     state_ns = OK;
            end
            OK: begin
                if (fail_ns) begin
                    state_ns = IDLE;
                end else state_ns = PROCESS;
            end
            ROUND: begin
                state_ns = IDLE;
            end
            default: state_ns = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            already_out_score <= 1'b0;
        end else if (in_valid) already_out_score <= 1'b0;
        else if (score_valid == 1) already_out_score <= 1'b1;
    end

    // non-blocking 
    always @(*) begin
        case (state_cs)
            IDLE, PROCESS: begin
                score = 4'd0;
            end
            default: begin
                score = score_ns;
            end
        endcase
    end

    always @(*) begin
        case (state_cs)
            ROUND: begin
                tetris_valid = 1'b1;
            end
            default: tetris_valid = 1'b0;
        endcase
    end

    always @(*) begin
        case (state_cs)
            ROUND: begin
                fail = fail_ns;
            end
            default: fail = 1'b0;
        endcase
    end

    always @(*) begin
        case (state_cs)
            IDLE, PROCESS: begin
                score_valid = 1'b0;
            end
            default: begin
                score_valid = 1'b1;
            end
        endcase
    end

    always @(posedge clk) begin
        case (state_cs)
            IDLE: begin
                counter <= 4'd0;
            end
            PROCESS: begin
                counter <= counter + 1'b1;
            end
            default: counter <= 4'd0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_times <= 4'd0;
        end else if (state_cs == IDLE) begin
            counter_times <= 4'd0;
        end else if (in_valid) counter_times <= counter_times + 1'b1;
        else counter_times <= counter_times;
    end

    always @(*) begin
        fail_ns = (map[89:72] != 0) ? 1'b1 : 1'b0;
    end

    always @(*) begin
        case (tetrominoes)
            3'd0: begin  // square
                row_loc = (col0r >= col1r) ? 2'd0 : 2'd1;
            end
            3'd1: begin
                row_loc = 2'd0;
            end
            3'd2: begin
                row_loc = (col0r >= col1r && col0r >= col2r && col0r >= col3r) ? 2'd0 : (col1r >= col2r && col1r >= col3r) ? 2'd1 : (col2r >= col3r) ? 2'd2 : 2'd3;
            end
            3'd3: begin
                row_loc = (col0r >= (col1r + 2)) ? 2'd0 : 2'd1;
            end
            3'd4: begin
                row_loc = ((col0r + 1) >= (col1r) && (col0r + 1) >= (col2r)) ? 2'd0 : ((col1r) >= (col2r)) ? 2'd1 : 2'd2;
            end
            3'd5: begin
                row_loc = (col0r >= col1r) ? 2'd0 : 2'd1;
            end
            3'd6: begin
                row_loc = ((col0r) >= (col1r + 1)) ? 2'd0 : 2'd1;
            end
            3'd7: begin
                row_loc = (col0r >= (col1r) && (col0r + 1) >= (col2r)) ? 2'd0 : ((col1r + 1) >= (col2r)) ? 2'd1 : 2'd2;
            end
            default: row_loc = 2'd0;
        endcase
    end

    always @(*) begin
        if (tetris_valid) begin
            tetris = map[71:0];
        end else begin
            tetris = 72'b0;
        end
    end

    wire [5:0] row0;
    wire [5:0] row1;
    wire [5:0] row2;
    wire [5:0] row3;
    wire [5:0] row4;
    wire [5:0] row5;
    wire [5:0] row6;
    wire [5:0] row7;
    wire [5:0] row8;
    wire [5:0] row9;
    wire [5:0] row10;
    wire [5:0] row11;
    wire [5:0] row12;
    wire [5:0] row13;
    wire [5:0] row14;

    assign row0  = map[0+:6];
    assign row1  = map[6+:6];
    assign row2  = map[12+:6];
    assign row3  = map[18+:6];
    assign row4  = map[24+:6];
    assign row5  = map[30+:6];
    assign row6  = map[36+:6];
    assign row7  = map[42+:6];
    assign row8  = map[48+:6];
    assign row9  = map[54+:6];
    assign row10 = map[60+:6];
    assign row11 = map[66+:6];
    assign row12 = map[72+:6];
    assign row13 = map[78+:6];
    assign row14 = map[84+:6];

    wire [71:0] col0x6m5 = (col0x6 >= 5) ? (col0x6 - 5) : 0;
    wire [71:0] col0x6m11 = (col0x6 >= 11) ? (col0x6 - 11) : 0;
    wire [71:0] col1x6m6 = (col1x6 >= 6) ? (col1x6 - 6) : 0;
    wire [71:0] col2x6m6 = (col2x6 >= 6) ? (col2x6 - 6) : 0;
    wire [71:0] col2x6m5 = (col2x6 >= 5) ? (col2x6 - 5) : 0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            map      <= 90'd0;
            score_ns <= 4'd0;
        end else if (state_ns == IDLE) begin
            map      <= 90'd0;
            score_ns <= 4'd0;
        end else if (in_valid) begin
            score_ns <= score_ns;
            case (tetrominoes)
                3'b000: begin  // square
                    case (row_loc)
                        2'b0: begin
                            map[col0x6]   <= 1'b1;
                            map[col0x6+6] <= 1'b1;
                            map[col0x6+1] <= 1'b1;
                            map[col0x6+7] <= 1'b1;
                        end
                        default: begin
                            map[col1x6]   <= 1'b1;
                            map[col1x6+6] <= 1'b1;
                            map[col1x6+1] <= 1'b1;
                            map[col1x6+7] <= 1'b1;
                        end
                    endcase
                end
                3'b001: begin  // line
                    map[col0x6]    <= 1'b1;
                    map[col0x6+6]  <= 1'b1;
                    map[col0x6+12] <= 1'b1;
                    map[col0x6+18] <= 1'b1;
                end
                3'b010: begin
                    case (row_loc)
                        2'd0: begin
                            map[col0x6]   <= 1'b1;
                            map[col0x6+1] <= 1'b1;
                            map[col0x6+2] <= 1'b1;
                            map[col0x6+3] <= 1'b1;
                        end
                        2'd1: begin
                            map[col1x6]   <= 1'b1;
                            map[col1x6+1] <= 1'b1;
                            map[col1x6+2] <= 1'b1;
                            map[col1x6+3] <= 1'b1;
                        end
                        2'd2: begin
                            map[col2x6]   <= 1'b1;
                            map[col2x6+1] <= 1'b1;
                            map[col2x6+2] <= 1'b1;
                            map[col2x6+3] <= 1'b1;
                        end
                        default: begin
                            map[col3x6]   <= 1'b1;
                            map[col3x6+1] <= 1'b1;
                            map[col3x6+2] <= 1'b1;
                            map[col3x6+3] <= 1'b1;
                        end
                    endcase
                end
                3'b011: begin
                    case (row_loc)
                        2'd0: begin
                            map[col0x6]    <= 1'b1;
                            map[col0x6+1]  <= 1'b1;
                            map[col0x6m5]  <= 1'b1;
                            map[col0x6m11] <= 1'b1;
                        end
                        2'd1: begin
                            map[col1x6+12] <= 1'b1;
                            map[col1x6+1]  <= 1'b1;
                            map[col1x6+7]  <= 1'b1;
                            map[col1x6+13] <= 1'b1;
                        end
                    endcase
                end
                3'b100: begin
                    case (row_loc)
                        2'd0: begin
                            map[col0x6]   <= 1'b1;
                            map[col0x6+6] <= 1'b1;
                            map[col0x6+7] <= 1'b1;
                            map[col0x6+8] <= 1'b1;
                        end
                        2'd1: begin
                            map[col1x6+1] <= 1'b1;
                            map[col1x6+2] <= 1'b1;
                            map[col1x6]   <= 1'b1;
                            map[col1x6m6] <= 1'b1;
                        end
                        default: begin
                            map[col2x6+1] <= 1'b1;
                            map[col2x6+2] <= 1'b1;
                            map[col2x6]   <= 1'b1;
                            map[col2x6m6] <= 1'b1;
                        end
                    endcase
                end
                3'b101: begin
                    case (row_loc)
                        2'd0: begin
                            map[col0x6]    <= 1'b1;
                            map[col0x6+6]  <= 1'b1;
                            map[col0x6+12] <= 1'b1;
                            map[col0x6+1]  <= 1'b1;
                        end
                        2'd1: begin
                            map[col1x6]    <= 1'b1;
                            map[col1x6+6]  <= 1'b1;
                            map[col1x6+12] <= 1'b1;
                            map[col1x6+1]  <= 1'b1;
                        end
                    endcase
                end
                3'b110: begin
                    case (row_loc)
                        2'd0: begin
                            map[col0x6]   <= 1'b1;
                            map[col0x6+6] <= 1'b1;
                            map[col0x6+1] <= 1'b1;
                            map[col0x6m5] <= 1'b1;
                        end
                        default: begin
                            map[col1x6+1]  <= 1'b1;
                            map[col1x6+7]  <= 1'b1;
                            map[col1x6+6]  <= 1'b1;
                            map[col1x6+12] <= 1'b1;
                        end
                    endcase
                end
                3'b111: begin
                    case (row_loc)
                        2'd0: begin
                            map[col0x6]   <= 1'b1;
                            map[col0x6+1] <= 1'b1;
                            map[col0x6+7] <= 1'b1;
                            map[col0x6+8] <= 1'b1;
                        end
                        2'd1: begin
                            map[col1x6]   <= 1'b1;
                            map[col1x6+1] <= 1'b1;
                            map[col1x6+7] <= 1'b1;
                            map[col1x6+8] <= 1'b1;
                        end
                        default: begin
                            map[col2x6m6] <= 1'b1;
                            map[col2x6m5] <= 1'b1;
                            map[col2x6+1] <= 1'b1;
                            map[col2x6+2] <= 1'b1;
                        end
                    endcase
                end
            endcase
        end else if (state_cs == PROCESS) begin
            case (1'b1)
                (map[(0)+:6] == 6'b111111): begin
                    map[0+:6]  <= map[6+:6];
                    map[6+:6]  <= map[12+:6];
                    map[12+:6] <= map[18+:6];
                    map[18+:6] <= map[24+:6];
                    map[24+:6] <= map[30+:6];
                    map[30+:6] <= map[36+:6];
                    map[36+:6] <= map[42+:6];
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(6)+:6] == 6'b111111): begin
                    map[6+:6]  <= map[12+:6];
                    map[12+:6] <= map[18+:6];
                    map[18+:6] <= map[24+:6];
                    map[24+:6] <= map[30+:6];
                    map[30+:6] <= map[36+:6];
                    map[36+:6] <= map[42+:6];
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(12)+:6] == 6'b111111): begin
                    map[12+:6] <= map[18+:6];
                    map[18+:6] <= map[24+:6];
                    map[24+:6] <= map[30+:6];
                    map[30+:6] <= map[36+:6];
                    map[36+:6] <= map[42+:6];
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(18)+:6] == 6'b111111): begin
                    map[18+:6] <= map[24+:6];
                    map[24+:6] <= map[30+:6];
                    map[30+:6] <= map[36+:6];
                    map[36+:6] <= map[42+:6];
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(24)+:6] == 6'b111111): begin
                    map[24+:6] <= map[30+:6];
                    map[30+:6] <= map[36+:6];
                    map[36+:6] <= map[42+:6];
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(30)+:6] == 6'b111111): begin
                    map[30+:6] <= map[36+:6];
                    map[36+:6] <= map[42+:6];
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(36)+:6] == 6'b111111): begin
                    map[36+:6] <= map[42+:6];
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(42)+:6] == 6'b111111): begin
                    map[42+:6] <= map[48+:6];
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(48)+:6] == 6'b111111): begin
                    map[48+:6] <= map[54+:6];
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(54)+:6] == 6'b111111): begin
                    map[54+:6] <= map[60+:6];
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(60)+:6] == 6'b111111): begin
                    map[60+:6] <= map[66+:6];
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
                (map[(66)+:6] == 6'b111111): begin
                    map[66+:6] <= map[72+:6];
                    map[72+:6] <= map[78+:6];
                    map[78+:6] <= map[84+:6];
                    map[84+:6] <= 6'd0;
                    score_ns   <= score_ns + 1;
                end
            endcase

        end
    end
endmodule

// for (i = 0; i < 16; i = i + 1) begin  // delete the tetris
//     if (map[(i*6)+:6] == 6'b111111) begin
//         for (j = i; j < 15; j = j + 1) begin
//             map[(j*6)+:6] <= map[((j*6)+6)+:6];
//         end
//         score_ns <= score_ns + 1;
//     end
// end


module find_height (
    map,
    loc,
    height
);
    parameter COL = 6;
    input [89:0] map;
    input [2:0] loc;
    output reg [3:0] height;

    always @(*) begin
        case (1'b1)
            (map[66+loc]): height = 4'd12;
            (map[60+loc]): height = 4'd11;
            (map[54+loc]): height = 4'd10;
            (map[48+loc]): height = 4'd9;
            (map[42+loc]): height = 4'd8;
            (map[36+loc]): height = 4'd7;
            (map[30+loc]): height = 4'd6;
            (map[24+loc]): height = 4'd5;
            (map[18+loc]): height = 4'd4;
            (map[12+loc]): height = 4'd3;
            (map[6+loc]): height = 4'd2;
            (map[loc]): height = 4'd1;
            default: height = 4'd0;
        endcase
    end
endmodule


// module map_delete {
// 	map,
// 	loc
// };
// 	input [91:0]
// (&map[0+:6] || &map[6+:6] || &map[12+:6] || &map[18+:6] || &map[24+:6] || &map[30+:6] || &map[36+:6] || &map[42+:6] || &map[48+:6] || &map[54+:6] || &map[60+:6] || &map[66+:6])

// endmodule
