`timescale 10s / 1s

// state variables
`define S0 3'b000
`define S1 3'b001
`define S2 3'b010
`define S3 3'b011
`define S4 3'b100
`define S5 3'b101
`define S6 3'b110

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

    // Letters 
    parameter W = 7'b1010101;
    parameter I = 7'b1001111;
    parameter N = 7'b1101010;
    parameter L = 7'b1110001;
    parameter O = 7'b0000001;
    parameter S = 7'b0100100;
    parameter E = 7'b0110000;
    parameter R = 7'b1111010;
    parameter NULL = 7'b1111111;
    
    // numbers
    parameter one = 7'b1001111;
    parameter two = 7'b0010010;
    parameter three = 7'b0000110;
    parameter four = 7'b1001100;
    parameter five = 7'b0100100;
    parameter six = 7'b0100000;
    
    // internal vars
    reg [16:0] count;
    wire clock_sig;
    reg [2:0] state;
    reg [2:0] next;
    
    always @(posedge CLK)
    begin
        count <= count + 1;
        if(count == 12000)
        begin
            count = 0;
            if(reset)
            begin
                state <= 1;
            end
            else if(state == 6)
            begin
                state <= 1;
            end
            else
            begin
                state <= state + 1;
            end
        end
    end

    always @(state)
    begin
        Anode <= 8'b11111111;
        
        case(state)
            1:begin
                Anode[2] <= 0;
                case(Diceout1)
                    1:begin
                        Cathode <= one;
                    end
                    2:begin
                        Cathode <= two;
                    end
                    3:begin
                        Cathode <= three;
                    end
                    4:begin
                        Cathode <= four;
                    end
                    5:begin
                        Cathode <= five;
                    end
                    6:begin
                        Cathode <= six;
                    end
                    default: begin
                        Cathode <= NULL;
                    end
                endcase
             end
             2:begin
                Anode[0] <= 0;
                case(Diceout2)
                    1:begin
                        Cathode <= one;
                    end
                    2:begin
                        Cathode <= two;
                    end
                    3:begin
                        Cathode <= three;
                    end
                    4:begin
                        Cathode <= four;
                    end
                    5:begin
                        Cathode <= five;
                    end
                    6:begin
                        Cathode <= six;
                    end
                    default: begin
                        Cathode <= NULL;
                    end
                endcase
             end
             3:begin
                Anode[7] <= 0;
                case(Win)
                    1:begin
                        Cathode <= W;
                    end
                endcase
                case(Lose)
                    1:begin
                        Cathode <= L;
                    end
                endcase
                case(Roll)
                    1:begin
                        Cathode <= R;
                    end
                endcase
             end
             4:begin
                Anode[6] <= 0;
                case(Win)
                    1:begin
                        Cathode <= I;
                    end
                endcase
                case(Lose)
                    1:begin
                        Cathode <= O;
                    end
                endcase
                case(Roll)
                    1:begin
                        Cathode <= O;
                    end
                endcase
             end
             5:begin
                Anode[5] <= 0;
                case(Win)
                    1:begin
                        Cathode <= N;
                    end
                endcase
                case(Lose)
                    1:begin
                        Cathode <= S;
                    end
                endcase
                case(Roll)
                    1:begin
                        Cathode <= L;
                    end
                endcase
             end
             6:begin
                Anode[4] <= 0;
                case(Win)
                    1:begin
                        Cathode <= NULL;
                    end
                endcase
                case(Lose)
                    1:begin
                        Cathode <= E;
                    end
                endcase
                case(Roll)
                    1:begin
                        Cathode <= L;
                    end
                endcase
             end
       endcase  
    end
    
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
            current_trial <= 0; // Starting Trial number
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
                    Roll = 0;
                    NS = `S5;
                end
                
                // Lose condition
                else if(sum == 2 || sum == 3 || sum == 12)
                begin
                    Roll = 0;
                    NS = `S6;
                end
                
                // Other condition
                else
                begin
                    Roll = 1;
                    trials = sum;
                    prev_sum = sum;
                    NS = `S0;
                end
            end
            
        `S4: // Subsequent Trials state
            begin
                prev_sum = sum;
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
                Lose = 0;
                Roll = 0;
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
                Win = 0;
                Roll = 0;
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



// To the Grader, Below is a test bench to show that the Dice Game works, you need to comment out Main and SSD
// and then Uncomment the test bench

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
    
    Counter counter1(.CLK(CLK), .reset(reset), .DiceOut(cntr1));
    Counter counter2(.CLK(CLK), .reset(reset), .DiceOut(cntr2));
    SevenSegDisplay display(.CLK(CLK), .reset(reset), .Win(Win), .Lose(Lose), .Roll(Roll), .Diceout1(DiceOut1), .Diceout2(DiceOut2), .Anode(Anode), .Cathode(Cathode));
    DiceGame dicegame(.CLK(CLK), .reset(reset), .Rb1(Rb1), .Rb2(Rb2), .cntr1(cntr1), .cntr2(cntr2), .Win(Win), .Lose(Lose), .Roll(Roll), .DiceOut1(DiceOut1), .DiceOut2(DiceOut2));
endmodule 


//module DGTB();
//    reg Rb1;
//    reg Rb2;
//    reg reset;
//    reg CLK;
//    reg [2:0] DC1;
//    reg [2:0] DC2;
//    wire Win;
//    wire Lose;
//    wire Roll;
//    wire [2:0] Dout1;
//    wire [2:0] Dout2;
    
//    DiceGame dgame(.CLK(CLK), .Rb1(Rb1), .Rb2(Rb2), .reset(reset), .cntr1(DC1), .cntr2(DC2), .Win(Win), .Lose(Lose), .Roll(Roll), .DiceOut1(Dout1), .DiceOut2(Dout2));
    
//    always
//    begin
//        #10 CLK <= ~CLK;
//    end
    
    
//    initial
//    begin
//    CLK = 1;
    
//    // Use this to test win right away
////    @(posedge CLK);
////    reset = 1;
////    @(posedge CLK);
////    reset = 0;
////    DC1 = 3;
////    DC2 = 4;
////    @(posedge CLK);
////    Rb1 = 1;
////    Rb2 = 1;
////    @(posedge CLK);
////    @(posedge CLK);

//    // Use this to test lose right away
////        @(posedge CLK);
////    reset = 1;
////    @(posedge CLK);
////    reset = 0;
////    DC1 = 2;
////    DC2 = 1;
////    @(posedge CLK);
////    Rb1 = 1;
////    Rb2 = 1;
////    @(posedge CLK);
////    @(posedge CLK);
    
//    // Use this to test running out of rolls waveforms
////        @(posedge CLK);
////        reset = 1;
////        @(posedge CLK);
////        reset = 0;
////        @(posedge CLK);
////        DC1 = 2;
////        DC2 = 2;
////        @(posedge CLK);
////        Rb1 = 1;
////        @(posedge CLK);
////        Rb2 = 1;
////        @(posedge CLK);
////        @(posedge CLK);
////        DC1 = 2;
////        DC2 = 1;
////        @(posedge CLK);
////        @(posedge CLK);
////        DC1 = 2;
////        DC2 = 3;
////        @(posedge CLK);
////        @(posedge CLK);
////        DC1 = 1;
////        DC2 = 1;
////        @(posedge CLK);
////        @(posedge CLK);
////        DC1 = 1;
////        DC2 = 2;
////        @(posedge CLK);
////        @(posedge CLK);
////        DC1 = 2;
////        DC2 = 2;
////        @(posedge CLK);
////        @(posedge CLK);
////        DC1 = 3;
////        DC2 = 2;
////        @(posedge CLK);
////        @(posedge CLK);
////        DC1 = 1;
////        DC2 = 2;

//    // Use this to test Win subsetquent rolls
////    @(posedge CLK);
////    reset = 1;
////    @(posedge CLK);
////    reset = 0;
////    DC1 = 2;
////    DC2 = 2;
////    @(posedge CLK);
////    Rb1 = 1;
////    Rb2 = 1;
////    @(posedge CLK);
////    @(posedge CLK);
   
//   // use this to test Lose subsequent rolls roll 7
////    @(posedge CLK);
////    reset = 1;
////    @(posedge CLK);
////    reset = 0;
////    DC1 = 2;
////    DC2 = 2;
////    @(posedge CLK);
////    Rb1 = 1;
////    Rb2 = 1;
////    @(posedge CLK);
////    @(posedge CLK);
////    DC1 = 3;
////    DC2 = 4;
    
        
//    end
//endmodule
