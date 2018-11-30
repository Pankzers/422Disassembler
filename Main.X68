INPSTART    EQU $500
INPEND      EQU $520
    ORG    $1000
START:                

* MAIN PROGRAM LOOP
*__________________    
MAIN:
    LEA INPSTART,A6
    LEA INPEND,A7
    LEA BUFF, A3
    LEA INPSTART,A2
    LEA M_INPSTARTRANGE,A1
    JSR USRINPUT
    LEA M_INPENDRANGE,A1
    LEA INPEND,A2
    JSR USRINPUT

MAINLOOP:
    CMP.L A6,A7     *Check for End of Range
    BGE EXIT            *Branch to Exit
    MOVEA.L A3,A4     * Buffer
    MOVE.W (A1)+,D6   * Get and move instruction and increment
                      * get Buffer
    MOVE.W D6,D5      * move copy into d5 of instruction
                   
    AND.W #$F000,D5  *AND to get the first 4 bits 
         
    LEA table,A5      *load table into memory
     
    JSR 00(A5,D5)    *jump to corresponding section
                    
   

*----------------------------------------------------------
*Table that will use the 4 bits to jump to the correct instruction
*-----------------------------------------------------------
table 
            JMP value0000
            JMP value0001
            JMP value0010
            JMP value0011
            JMP value0100
            JMP value0101
            JMP value0110
            JMP value0111
            JMP value1000
            JMP value1001
            JMP value1010
            JMP value1011
            JMP value1100
            JMP value1101
            JMP value1110
            JMP value1111
            
            
value0000               *Check for CMPI OPWORD






            
value0100 CMP.W #$4D71,(A1)   *Check for NOP OPWORD
          BRA MAINLOOP

*---------------------------------------------------------------
*Set Text Buffer to Data can't disassemble instruction
*---------------------------------------------------------------
NOOPWORD


* USER INPUT
* __________
USRINPUT:
    MOVE.B  #14,D0          *displays input message
    TRAP    #15
    BRA INPSTR
    
BADINPUT:
    LEA M_INPINVALID, A1
    MOVE.B #14,D0
    TRAP #15
    BRA INPSTR 

INPSTR:
    MOVEA.L A2,A1
    MOVE.B #2,D0
    TRAP #15

    CMP.B #$0,(A1)
    BEQ BADINPUT
    CMP.B #6,D1
    BGT BADINPUT
    NOP *Validate User Input stored in (A1)
        *Convert to Hex
    JSR STRING_HEX
    RTS
    
    
*STRING TO HEX
*PRECONDITIONS:
*   Memory location of string must be loaded into A1
*   Length of string must be loaded into D1
*REGISTERS USED:
*   D0,D1,D2,D3,D4,A2
*POSTCONDITIONS:
*   Hex equivalent of string is located at A1 with null character terminating in memory
*NOTES:
*   D0 Counts from 0 to string length
*   D2 is the current working value converted from string
*   D3 is the sum of all the working values
*   D4 is the multiplier for the logical shift left on the current working value
*   A2 Holds the starting address if A1
*_____________
STRING_HEX:
    MOVE.B  #0,D0
    MOVE.L  #0,D3
    MOVEA.L A1,A2
STRING_HEX_01:
    MOVE.L  #0,D2
    CMP.B   D0,D1
    BNE     STRING_HEX_02
    MOVE.L  D3,(A2)
    ADDA.W  #4,A2
    MOVE.B  #$FF,(A2)
    RTS
STRING_HEX_02:
    MOVE.B  (A1),D2
    SUBI.B  #$30,D2     
    CMP.B   #$9,D2
    BLE     NSUB11
    SUBI.B  #$7,D2   
NSUB11: 
    *MOVE.B  D2,(A1)
    MOVE.B  #4,D4
    MULS.W  D0,D4
    LSL.L   D4,D2
    OR.L    D2,D3
    ADDQ.B  #1,D0 
    ADDA.W  #1,A1          *increment pointer
    BRA     STRING_HEX_01   
    
    
*HEX TO STRING
*_____________
HEX_STRING:
    NOP
    RTS
    
    
*NOP SUBROUTINE
*______________
SR_NOP:
    NOP *DO STUFF HERE
    RTS   
    
    
*EXIT
*____
EXIT:
    NOP *REPLACE WITH EOF OUTPUT
    
    
*CONSTANTS AND PARAMETERS
*________________________
CR       EQU    $0D
LF       EQU    $0A
M_INPSTARTRANGE   DC.B    'Enter Start Range of Memory',CR,LF,0
M_INPENDRANGE     DC.B    'Enter End Range of Memory',CR,LF,0
M_INPINVALID      DC.B    'Input is invalid, try again',CR,LF,0
    ORG $500
    DC.L 8
    ORG $520
    DC.L 8
    END    START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
