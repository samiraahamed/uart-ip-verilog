module uart_tb;

reg clk;
reg rst;
reg [7:0] tx_data;
reg tx_start;

reg baud_tick;
integer baud_count;

reg serial_tx;

reg tx_done;
reg [1:0] tx_state;
reg [2:0] tx_bit;

reg [7:0] rx_data;
reg rx_done;
reg [2:0] rx_state;          
reg [2:0] rx_bit_cnt;
reg [1:0] sample_cnt;        
reg serial_tx_sync;          
reg serial_tx_prev;          


always #5 clk = ~clk;


always @(posedge clk or posedge rst) begin
    if(rst) begin
        baud_count <= 0;
        baud_tick <= 0;
    end else begin
        if(baud_count == 3) begin
            baud_count <= 0;
            baud_tick <= 1;
        end else begin
            baud_count <= baud_count + 1;
            baud_tick <= 0;
        end
    end
end


always @(posedge clk or posedge rst) begin
    if(rst) begin
        serial_tx <= 1'b1;
        tx_done <= 0;
        tx_state <= 0;
        tx_bit <= 0;
    end else if(baud_tick) begin
        case(tx_state)
            0: begin
                serial_tx <= 1'b1;
                tx_done <= 0;
                if(tx_start) tx_state <= 1;
            end
            1: begin
                serial_tx <= 1'b0;
                tx_bit <= 0;
                tx_state <= 2;
            end
            2: begin
                serial_tx <= tx_data[tx_bit];
                if(tx_bit == 7) tx_state <= 3;
                else tx_bit <= tx_bit + 1;
            end
            3: begin
                serial_tx <= 1'b1;
                tx_done <= 1;
                tx_state <= 0;
            end
        endcase
    end
end


always @(posedge clk or posedge rst) begin
    if(rst) begin
        rx_data <= 0;
        rx_done <= 0;
        rx_state <= 0;
        rx_bit_cnt <= 0;
        sample_cnt <= 0;
        serial_tx_sync <= 1'b1;
        serial_tx_prev <= 1'b1;
    end else begin
       
        serial_tx_sync <= serial_tx;
        serial_tx_prev <= serial_tx_sync;

       
        sample_cnt <= sample_cnt + 1;

        case(rx_state)
            
            0: begin
                rx_done <= 0;
                if(serial_tx_prev == 1'b1 && serial_tx_sync == 1'b0) begin
                    rx_state <= 1;          
                    sample_cnt <= 0;        
                end
            end

            
            1: begin
                if(sample_cnt == 2) begin
                    if(serial_tx_sync == 1'b0) begin
                        rx_state <= 2;      
                        rx_bit_cnt <= 0;
                    end else begin
                        rx_state <= 0;      
                    end
                end
            end

         
            2: begin
                if(sample_cnt == 2) begin
                    rx_data[rx_bit_cnt] <= serial_tx_sync;
                    if(rx_bit_cnt == 7) begin
                        rx_state <= 3;      
                    end else begin
                        rx_bit_cnt <= rx_bit_cnt + 1;
                    end
                end
            end

         
            3: begin
                if(sample_cnt == 2) begin
                   
                    rx_done <= 1;
                    rx_state <= 0;
                end
            end
        endcase
    end
end


initial begin
    clk = 0;
    rst = 1;
    tx_start = 0;
    tx_data = 8'b10101010;

    #20;
    rst = 0;

    
    @(posedge baud_tick);
    #1;
    tx_start = 1;
    @(posedge baud_tick);
    #1;
    tx_start = 0;

    #4000;

    $display("==============================");
    $display(" UART FULL SYSTEM TEST ");
    $display("==============================");
    $display("Data Sent     = %b", tx_data);
    $display("Data Received = %b", rx_data);
    $display("TX Done = %b", tx_done);
    $display("RX Done = %b", rx_done);

    if(rx_data == tx_data)
        $display("*** SUCCESS! DATA MATCH! ***");
    else
        $display("*** ERROR! DATA MISMATCH! ***");

    $display("==============================");
    $finish;
end

endmodule
