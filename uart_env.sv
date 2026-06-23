`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 00:44:34
// Design Name: 
// Module Name: uart_env
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
`include "gen_driv.sv"
`include "mon_scb.sv"


class uart_env;
    uart_generator  gen;
    uart_driver     driv;
    uart_monitor    mon;
    uart_scoreboard scb;
    transaction trans ;
    
    // The Physical Mailboxes
    mailbox #(transaction) gen2driv;
    mailbox #(transaction) gen2scb;
    mailbox #(transaction) mon2scb;
    
    virtual uart_if vif;
    
    function new(virtual uart_if vif);
        this.vif = vif;
        
        // 1. Build the mailboxes
        gen2driv = new();
        gen2scb  = new();
        mon2scb  = new();
        
        // 2. Instantiate all the classes and hand them their mailbox keys
        gen  = new(gen2driv, gen2scb); 
        driv = new(vif, gen2driv);
        mon  = new(vif, mon2scb);
        scb  = new(gen2scb, mon2scb);
    endfunction
    
    task test();
        // fork/join_any runs all these tasks in parallel at the same time
        fork
            gen.main();
            driv.main();
            mon.main();
            scb.main();
        join_none
        wait(gen.ended.triggered);
        #50000000 ;
        $finish ;
    endtask
    
    task post_test();
        // Wait for the Generator to finish creating its 20 packets
        wait(gen.ended.triggered);
        
        // Give the Hardware and Monitor enough time to finish processing the final packet
        #5ms; 
    endtask
    
    task run();
        test();
        post_test();
        $finish; // End the simulation
    endtask
endclass
