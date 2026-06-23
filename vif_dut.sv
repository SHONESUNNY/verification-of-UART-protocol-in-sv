`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 11:13:15
// Design Name: 
// Module Name: vif_dut
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



interface uart_if(input logic clk);
    logic       rst_n;
    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx_busy;
    logic       tx;
    logic       rx;        // The incoming serial wire
    logic [7:0] rx_data;     // The reconstructed 8-bit letter
    logic       rx_done ;  
endinterface

 module uart_dut_tx #(parameter CLKS_PER_BIT = 10416)
(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx,
    output logic       tx_busy
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_e;
    state_e state;

    logic [7:0] shift_reg;
    logic [2:0] bit_idx;
    integer clk_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            shift_reg <= 8'h00;
            bit_idx   <= 3'd0;
            clk_count <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    tx        <= 1'b1;
                    tx_busy   <= 1'b0;
                    clk_count <= 0;

                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy   <= 1'b1;
                        state     <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end
                    else begin
                        clk_count <= 0;
                        bit_idx   <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx <= shift_reg[bit_idx];
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end
                    else begin
                        clk_count <= 0;

                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end
                        else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1;

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end
                    else begin
                        clk_count <= 0;
                        state     <= IDLE;
                    end
                end

            endcase
        end
    end
endmodule

module uart_dut_rx #(
    parameter CLKS_PER_BIT = 10416 // 9600 Baud at 100MHz clock
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx,          // The incoming serial wire
    output logic [7:0] rx_data,     // The reconstructed 8-bit letter
    output logic       rx_done      // Pulses High for 1 clock when a byte is fully received
);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    integer clk_count;
    logic [2:0] bit_idx; 
    logic [7:0] rx_shift_reg; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            clk_count  <= 0;
            bit_idx  <= 0;
            rx_done  <= 0;
            rx_data  <= 8'h00;
            rx_shift_reg<= 8'h00;
        end else begin
            
            // Default: Keep rx_done low unless we specifically trigger it
            rx_done <= 1'b0; 

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_idx <= 0;
                    if (rx == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    // Hardware version of #(bit_period / 2)!
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        if (rx == 1'b0) begin // Glitch filter check
                            clk_count <= 0;     // Reset the metronome
                            state   <= DATA;
                        end else begin
                            state   <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DATA: begin
                    // Hardware version of #(bit_period)
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_shift_reg[bit_idx] <= rx; // Write the bit down
                        
                        if (bit_idx == 7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                STOP: begin
                    // Wait one full bit period for the Stop Bit
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_data <= rx_shift_reg; // Push the final letter to the output wire
                        rx_done <= 1'b1;      // Shoot the flare gun!
                        state   <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule