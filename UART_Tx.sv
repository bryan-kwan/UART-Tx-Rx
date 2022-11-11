module UART_Tx #(parameter  CLOCK_FREQUENCY = 50000000, // Clock speed in Hz
                            BAUD = 115200,
                            CYCLES_PER_BIT = CLOCK_FREQUENCY/BAUD,
                            CYCLES_PER_READ = CYCLES_PER_BIT / 2
                )
                (input logic [7:0]    i_Tx, // Input parallel data
                                      clk,
                                      enable,
                                      reset_n,
                 output logic  o_Tx, // Output serial data
                );
    int clock_count, bit_index;
    typedef enum logic [1:0] {IDLE,START,STOP,DATA} statetype;
    statetype state;

    parameter START_BIT = 1'b0;
    parameter STOP_BIT = 1'b1;

    always_ff @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            state<=IDLE;
            clock_count<=0;
            bit_index<=0;
            o_Tx<=1;
        end 
        else
            case(state)
                IDLE: begin
                    clock_count<=0;
                    bit_index<=0;
                    o_Tx<=1; // Serial output line is high during idle
                    if(enable) state<=START;
                    else state<=IDLE;
                end
                START: begin
                    if (clock_count<(CYCLES_PER_BIT-1)) begin// Check that middle of start bit is still low
                        clock_count++;
                        o_Tx<=START_BIT;
                        state<=START;
                    end    
                    else begin
                        clock_count<=0;
                        state<=DATA;
                    end
                end
                DATA: begin
                    if (clock_count<(CYCLES_PER_BIT-1)) begin
                        state<=DATA;
                        clock_count++;
                        o_Tx<=i_Tx[bit_index];   
                        else begin 
                            clock_count<=0;
                            if (bit_index<7) begin
                                bit_index++;
                                state<=DATA;
                            end
                            else begin // If we finished sending out all the bits
                                bit_index<=0;
                                state<=STOP;
                            end
                        end 
                    end
                    
                end
                STOP: begin
                    if (clock_count<(CYCLES_PER_BIT-1)) begin
                        clock_count++;
                        state<=STOP;
                        o_Tx<=STOP_BIT;
                    end
                    else begin
                        state<=IDLE;
                        clock_count<=0;
                    end
                end
                default: state<=IDLE;
            endcase
    end

endmodule