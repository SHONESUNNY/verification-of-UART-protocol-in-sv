`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 11:00:16
// Design Name: 
// Module Name: uart_tb
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
`include "uart_env.sv"
module uart_tb;
    
    // 1. Generate the System Clock (100MHz)
    logic clk = 0;
    always #5 clk = ~clk;
    
    // 2. Instantiate the physical interface wires
    uart_if vif(clk);
    
    // 3. Instantiate the Hardware DUT! 
    // We connect the hardware ports to our interface wires.
    uart_dut_tx #(
        .CLKS_PER_BIT(10416) // 9600 Baud at 100MHz
    ) dut_tx (
        .clk(vif.clk),.rst_n(vif.rst_n), .tx_start(vif.tx_start),
        .tx_data(vif.tx_data),.tx(vif.tx),.tx_busy(vif.tx_busy)
    );
     uart_dut_rx #(
        .CLKS_PER_BIT(10416) // 9600 Baud at 100MHz
    ) dut_rx (
        .clk(vif.clk),.rst_n(vif.rst_n),
        .rx_data(vif.rx_data), .rx(vif.tx), .rx_done(vif.rx_done)
    );
    // 4. Instantiate the Software Environment
    uart_env env;
    
    initial begin
        // Reset the hardware cleanly
        vif.rst_n = 0;
        #20;
        vif.rst_n = 1;
        
        env = new(vif);
        env.gen.num_transactions = 20;
        
        // Run the simulation!
        env.run();
    end
    
endmodule
