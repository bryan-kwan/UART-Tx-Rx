module UART_Rx #(parameter  CLOCK_FREQUENCY = 50000000, // Clock speed in Hz
                            BAUD = 115200,
                            CYCLES_PER_BIT = CLOCK_FREQUENCY/BAUD,
                            CYCLES_PER_READ = CYCLES_PER_BIT / 2
                )
                (input logic    i_Rx, // Input serial data
                                clk,
                 output logic [7:0] o_Rx_Byte, // Byte received
                 output logic o_Rx_valid
                );
    int clock_count, bit_index;
    typedef enum logic [1:0] {IDLE,START,STOP,DATA} statetype;
    statetype state;

    always_ff @(posedge clk) begin
        case(state)
            IDLE: begin
                clock_count<=0;
                bit_index<=0;
                o_Rx_valid<=0;
                if(i_Rx==0) state<=START; // On negedge of serial data line, start detecting byte
                else state<=IDLE;
            end
            START: begin
                if (clock_count==(CYCLES_PER_BIT-1) / 2) begin// Check that middle of start bit is still low
                    if (i_Rx==1'b0)
                        clock_count<=0;
                    else state<=IDLE;
                end
                else
                    clock_count++;
                if(clock_count%(CYCLES_PER_BIT-1)==0) state<=DATA; // After detecting start bit, start receiving byte
                else state<=START;
            end
            DATA: begin
                if (clock_count<(CYCLES_PER_BIT-1)) begin
                    state<=DATA;
                    clock_count++;   
                    else begin 
                        clock_count<=0;
                        o_Rx_Byte[bit_index]<=i_Rx; // Read input value after CYCLES_PER_BIT - 1 cycles
                        if (bit_index<7)
                            bit_index++;
                        else begin
                            bit_index<=0;
                            state<=STOP;
                        end
                    end 
                end
                
            end
            STOP: begin
                if (clock_count<CYCLES_PER_BIT-1) begin
                    clock_count++;
                    state<=STOP;
                    
                end
                else begin
                    state<=IDLE;
                    o_Rx_valid<=1; // Output a 1 to signal that we have received the byte
                    clock_count<=0;
                end
            end
            default: state<=IDLE;
        endcase
    end

endmodule