`timescale 1ns / 1ps

// state variables
`define S0 3'b000
`define S1 3'b001
`define S2 3'b010
`define S3 3'b100
`define S4 3'b101
`define S5 3'b110
`define S6 3'b111

// Roll Counter
// Should continuously run with CLK
module Counter(
    input CLK,
    input reset,
    output reg [2:0] DiceOut
);
    
    // Counter Logic
    initial 
    begin
        DiceOut = 1;      
    end
    
    always @(posedge CLK)
    begin
        if(DiceOut == 6 || reset == 1)
        begin
            DiceOut <= 1;
        end
        else
        begin
            DiceOut <= DiceOut + 1;
        end
    end
endmodule

// Output display
module SevenSegDisplay(
    input CLK,
    input reset,
    input Win, 
    input Lose,
    input Roll,
    input[2:0] Diceout1,
    input[2:0] Diceout2,
    output reg[7:0] Anode = 8'b11111111,
    output reg[6:0] Cathode
);
    
endmodule

// State logic for Win, Lose, NS, PS
module DiceGame(
    input CLK,
    input reset,
    input Rb1,
    input Rb2,
    input [2:0] cntr1,
    input [2:0] cntr2,
    output reg Win,
    output reg Lose,
    output reg Roll,
    output [2:0] DiceOut1, 
    output [2:0] DiceOut2 
    );
    
    // internal registers for state
    reg [2:0] PS;
    reg [2:0] NS;
    
    reg [2:0] Dice1;
    reg [2:0] Dice2;
    reg [3:0] sum;
    reg [3:0] prev_sum;
    reg [3:0] trials;
    reg [3:0] current_trial;
    
    // Dice Out for Seven Segment Display
    assign DiceOut1 = Dice1;
    assign DiceOut2 = Dice2;
    
    // State Update
    always @(posedge CLK)
    begin
        if(reset == 1'b1)
        begin
            PS <= `S0;
            trials <= 1; // Starting number of Trials
            current_trial <= 1; // Starting Trial number
            sum <= 0;
            prev_sum <= 0;
            Dice1 <= 0;
            Dice2 <= 0;
            Win <= 0;
            Lose <= 0;
            Roll <= 1;
           
        end
        else
        begin
            PS <= NS;
        end
    end

    // Next State Calculation
    always @(*)
    begin
    
    case(PS)
        `S0: // Initial State
            begin
                if(Rb1 == 1'b1)
                begin
                    Dice1 = cntr1;
                    NS = `S1;
                end
                else
                begin
                    NS = `S0;
                end
            end
            
        `S1: // Roll 1 state
            begin
                if(Rb2 == 1'b1)
                begin
                    Dice2 = cntr2;
                    NS = `S2;
                end
                else
                begin
                    NS = `S1;
                end
            end
            
        `S2: // Roll 2 state
            begin
                if(trials == 1)
                begin
                    NS = `S3;
                end
                else
                begin
                    NS = `S4;
                end
            end
            
        `S3: // First Trial state
            begin            
                sum = Dice1 + Dice2;
                
                // Win condition    
                if(sum == 7 || sum == 11)
                begin
                    NS = `S5;
                end
                
                // Lose condition
                else if(sum == 2 || sum == 3 || sum == 12)
                begin
                    NS = `S6;
                end
                
                // Other condition
                else
                begin
                    Roll = 1;
                    prev_sum = sum;
                    trials = sum;
                    NS = `S0;
                end
            end
            
        `S4: // Subsequent Trials state
            begin
                sum = Dice1 + Dice2;
                current_trial = current_trial + 1;
                
                // Second Win condition
                if(sum == prev_sum)
                begin
                    NS = `S5;
                end
                
                // Second Lose condition
                else if(sum == 7 || current_trial == trials)
                begin
                    NS = `S6;
                end
                
                // Other, keep rolling
                else
                begin
                    NS = `S0;
                end
                
            end
            
        `S5: // Win State
            begin
                Win = 1;
                if(reset == 1)
                begin
                    NS = `S0;
                end
                else
                begin
                    NS = `S5;
                end
            end
            
        `S6: // Lose State
            begin
                Lose = 1;
                if(reset == 1)
                begin
                    NS = `S0;
                end
                else
                begin
                    NS = `S6;
                end
            end
            
        default: // go back to initial state just incase of bug
            begin
                NS = `S0;
            end
    endcase
    end
endmodule




// Outer encompassing module
module Main(
    input Rb1,
    input Rb2,
    input reset,
    input CLK,
    output [7:0] Anode,
    output [6:0] Cathode
);

    wire [2:0] cntr1;
    wire [2:0] cntr2;
    wire Win;
    wire Lose;
    wire Roll;
    wire DiceOut1;
    wire Diceout2;
    
    Counter counter1(.CLK(CLK), .CounterOut(cntr1));
    Counter counter2(.CLK(CLK), .CounterOut(cntr2));
    DiceGame dicegame(.CLK(CLK), .reset(reset), .Rb1(Rb1), .Rb2(Rb2), .cntr1n1(cntr1), .cntr2(cntr2), .Win(Win), .Lose(Lose), .Roll(Roll), .DiceOut1(DiceOut1), .DiceOut2(DiceOut2));
endmodule 


module DGTB();

endmodule
