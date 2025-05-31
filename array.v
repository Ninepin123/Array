module KeyPadScanner(
    input wire clk,
    input wire rst,
    input wire [3:0] col,     
    output reg [3:0] row,      
    output reg [3:0] key_value,
    output reg key_valid       
);


    parameter S_0 = 3'b000;  // Idle state
    parameter S_1 = 3'b001;  // Scan row 0
    parameter S_2 = 3'b010;  // Scan row 1
    parameter S_3 = 3'b011;  // Scan row 2
    parameter S_4 = 3'b100;  // Scan row 3
    parameter S_5 = 3'b101;  // Wait for key release

    reg [2:0] current_state, next_state;
    reg [5:0] scan_code;     
    reg [3:0] decode_key;   

    // 狀態轉換 (時序邏輯)
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S_0;
        else
            current_state <= next_state;
    end

    // 下一狀態邏輯 (組合邏輯)
    always @(*) begin
        case (current_state)
            S_0: begin
                if (col == 4'b1111)
                    next_state = S_1;
                else
                    next_state = S_5;
            end
            
            S_1: begin
                if (col == 4'b1111)
                    next_state = S_2;
                else
                    next_state = S_5;
            end
            
            S_2: begin
                if (col == 4'b1111)
                    next_state = S_3;
                else
                    next_state = S_5;
            end
            
            S_3: begin
                if (col == 4'b1111)
                    next_state = S_4;
                else
                    next_state = S_5;
            end
            
            S_4: begin
                if (col == 4'b1111)
                    next_state = S_0;
                else
                    next_state = S_5;
            end
            
            S_5: begin
                if (col == 4'b1111)
                    next_state = S_0;
                else
                    next_state = S_5;
            end
            
            default: next_state = S_0;
        endcase
    end

    // 輸出邏輯 - row 信號
    always @(*) begin
        case (current_state)
            S_0: row = 4'b0000;  
            S_1: row = 4'b1110;  
            S_2: row = 4'b1101;  
            S_3: row = 4'b1011;   
            S_4: row = 4'b0111;  
            S_5: row = 4'b0000;  
            default: row = 4'b0000;
        endcase
    end

    // 掃描碼生成邏輯
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_code <= 6'b111111;
            key_valid <= 1'b0;
        end
        else begin
            // 當偵測到按鍵按下時，記錄掃描碼
            if (col != 4'b1111 && current_state >= S_1 && current_state <= S_4) begin
                scan_code <= {(current_state - 1), col};
                key_valid <= 1'b1;
            end
            else if (current_state == S_0) begin
                key_valid <= 1'b0;
            end
        end
    end

    always @(*) begin
        case (scan_code)
           
            6'b001110: decode_key = 4'h1;  // col[0]=0, row[0] -> 1
            6'b011110: decode_key = 4'h2;  // col[0]=0, row[1] -> 2
            6'b101110: decode_key = 4'h3;  // col[0]=0, row[2] -> 3
            6'b111110: decode_key = 4'hA;  // col[0]=0, row[3] -> A
            
            // Col 1 按下時 (col[1]=0) -> col = 4'b1101
            6'b001101: decode_key = 4'h4;  // col[1]=0, row[0] -> 4
            6'b011101: decode_key = 4'h5;  // col[1]=0, row[1] -> 5
            6'b101101: decode_key = 4'h6;  // col[1]=0, row[2] -> 6
            6'b111101: decode_key = 4'hB;  // col[1]=0, row[3] -> B
            
            // Col 2 按下時 (col[2]=0) -> col = 4'b1011
            6'b001011: decode_key = 4'h7;  // col[2]=0, row[0] -> 7
            6'b011011: decode_key = 4'h8;  // col[2]=0, row[1] -> 8
            6'b101011: decode_key = 4'h9;  // col[2]=0, row[2] -> 9
            6'b111011: decode_key = 4'hC;  // col[2]=0, row[3] -> C
            
            // Col 3 按下時 (col[3]=0) -> col = 4'b0111
            6'b000111: decode_key = 4'hE;  // col[3]=0, row[0] -> * (E)
            6'b010111: decode_key = 4'h0;  // col[3]=0, row[1] -> 0
            6'b100111: decode_key = 4'hF;  // col[3]=0, row[2] -> # (F)
            6'b110111: decode_key = 4'hD;  // col[3]=0, row[3] -> D
            
            default: decode_key = 4'h0;
        endcase
    end

    // 輸出按鍵值
    always @(posedge clk or posedge rst) begin
        if (rst)
            key_value <= 4'h0;
        else if (key_valid)
            key_value <= decode_key;
    end

endmodule

module SevenSegDecoder(
    input wire [3:0] key_value,    
    output reg [6:0] seg_out      
);
  
    
    always @(*) begin
        case (key_value)
            4'h0: seg_out = 7'b1111110;  // "0"
            4'h1: seg_out = 7'b0110000;  // "1"
            4'h2: seg_out = 7'b1101101;  // "2"
            4'h3: seg_out = 7'b1111001;  // "3"
            4'h4: seg_out = 7'b0110011;  // "4"
            4'h5: seg_out = 7'b1011011;  // "5"
            4'h6: seg_out = 7'b1011111;  // "6"
            4'h7: seg_out = 7'b1110000;  // "7"
            4'h8: seg_out = 7'b1111111;  // "8"
            4'h9: seg_out = 7'b1111011;  // "9"
            4'hA: seg_out = 7'b1110111;  // "A"
            4'hB: seg_out = 7'b0011111;  // "b"
            4'hC: seg_out = 7'b1001110;  // "C"
            4'hD: seg_out = 7'b0111101;  // "d"
            4'hE: seg_out = 7'b1001111;  // "E" (表示 *)
            4'hF: seg_out = 7'b1000111;  // "F" (表示 #)
            default: seg_out = 7'b0000000; // 全部熄滅
        endcase
    end
endmodule

module KeyPadWithDisplay(
    input wire clk,
    input wire rst,
    input wire [3:0] col,          
    output wire [3:0] row,       
    output wire [6:0] seg_out,     
    output wire key_valid          
);
    wire [3:0] key_value;
    
    KeyPadScanner keypad_inst (
        .clk(clk),
        .rst(rst),
        .col(col),         
        .row(row),         
        .key_value(key_value),
        .key_valid(key_valid)
    );
    

    SevenSegDecoder seg_inst (
        .key_value(key_value),
        .seg_out(seg_out)
    );
endmodule