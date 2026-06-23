`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 01:08:09
// Design Name: 
// Module Name: mon_scb
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


   class uart_monitor;
    virtual uart_if vif;
    mailbox #(transaction) mon2scb;
    
    // 10416 hardware clock cycles * 10ns clock period
    time bit_period = 104160ns; 
    transaction trans;
            
    // Define our FSM States (No Parity state this time!)
    typedef enum logic [1:0] {
        IDLE, 
        START, 
        DATA, 
        STOP
    } fsm_state_e;

    fsm_state_e current_state;

    // Constructor asking for the wire and the Scoreboard mailbox
    function new(virtual uart_if vif, mailbox #(transaction) mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task main();
        current_state = IDLE;
        
        forever begin      
            case (current_state)
                IDLE: begin
                     
                    wait(vif.tx === 1'b0); 
                    current_state = START;
                    trans  = new();
                end
                
                START: begin
                    // Wait exactly HALF a bit period to sample the very center of the bit
                    #(bit_period / 2); 
                    
                    if (vif.tx === 1'b0) begin
                        #(bit_period); // Move forward to the center of the first Data bit
                        current_state = DATA;
                    end else begin
                        current_state = IDLE; 
                    end
                end
                
                DATA: begin
                    // Loop 8 times to grab all the bits, waiting a full period between each
                    for (int i = 0; i < 8; i++) begin
                        trans.data[i] = vif.tx;
                        #(bit_period);
                    end
                    current_state = STOP; 
                end
                
                STOP: begin
                    if (vif.tx === 1'b1) begin
                        $display("[MONITOR] Successfully received: %h", trans.data);
                         mon2scb.put(trans); 
                    end else begin
                        $error("[MONITOR] Framing Error");
                    end
                    
                    // Reset back to waiting for the next message
                    current_state = IDLE; 
                end
            endcase
        end
    endtask
endclass

class uart_scoreboard;
    mailbox #(transaction) gen2scb; 
    mailbox #(transaction) mon2scb; 
    
    function new(mailbox #(transaction) gen2scb, mailbox #(transaction) mon2scb);
        this.gen2scb = gen2scb;
        this.mon2scb = mon2scb;
    endfunction
    
    task main();
        forever begin
           transaction expected_trans;
           transaction actual_trans;
            
            
            gen2scb.get(expected_trans);
            mon2scb.get(actual_trans);
            
            if (expected_trans.data === actual_trans.data) begin
                $display("[SCOREBOARD] PASS! Expected: %h | Received: %h", 
                          expected_trans.data, actual_trans.data);
            end else begin
                $error("[SCOREBOARD] FAIL! Expected: %h | Received: %h", 
                        expected_trans.data, actual_trans.data);
            end
        end
    endtask
endclass

