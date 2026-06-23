`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 10:22:28
// Design Name: 
// Module Name: gen_driv
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



class transaction;

    rand bit [7:0] data;

    function transaction clone();
        transaction copy = new();
        copy.data = this.data;
        return copy;
    endfunction

endclass


class uart_driver;
    mailbox #(transaction) gen2driv ;
    virtual uart_if vif;

    function new(virtual uart_if vif ,mailbox #(transaction) gen2driv);
        this.vif = vif;
        this.gen2driv = gen2driv ;
    endfunction

    task main();
    
        vif.tx_start <= 1'b0;
        vif.tx_data  <= 8'h00;
        
     forever begin
        transaction trans ;
        trans = new();
        gen2driv.get(trans);
           wait(vif.tx_busy === 1'b0);
            @(posedge vif.clk);
          //  $display("after wait tx_busy : data = %0h" ,trans.data);

            // 2. Load the letter into the machine and press "START"
            vif.tx_data  <= trans.data;
            vif.tx_start <= 1'b1;
            @(posedge vif.clk);
            vif.tx_start <= 1'b0;
            @(posedge vif.clk);
            $display("[DRIVER] Handed payload %h to the DUT", trans.data);
        end

    endtask

endclass


class uart_generator;

    uart_driver drv;
    mailbox #(transaction) gen2driv;
    mailbox #(transaction) gen2scb ;
    
    // Test constraints
    int num_transactions = 20; // How many letters to send today
    event ended;

    function new(mailbox #(transaction) gen2driv ,mailbox #(transaction) gen2scb);
        this.gen2driv = gen2driv;
        this.gen2scb = gen2scb ;
        
    endfunction

    task main();
        $display("-----------------------------------------");
        $display("[GENERATOR] Starting to generate %0d packets.", num_transactions);
        $display("-----------------------------------------");

        for (int i = 0; i < num_transactions; i++) begin
            
            // 1. The Creator: Grab a blank piece of paper
            transaction trans ;
            trans = new();
            if (!trans.randomize()) begin
                $fatal("[GENERATOR] Randomization failed!");
            end
            gen2driv.put(trans.clone());
            gen2scb.put(trans.clone());
            
            $display("[GENERATOR] Created Packet %0d: data = %h ", i+1, trans.data);
        end
        

      -> ended ;
    endtask

endclass
  
