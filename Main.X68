INPSTART    EQU $500
INPEND      EQU $520
STRHEXOUT   EQU $540
BUFF        EQU $580
    ORG    $1000
START:                

* MAIN PROGRAM LOOP
* NOTES:
*   WARNING: A5, A6, and D7 MUST not be overwritten by subroutines. They are system reserved currently.
*__________________    
MAIN:
    LEA INPSTART,A5
    LEA INPEND,A6
    LEA BUFF, A3
    LEA INPSTART,A2
    LEA M_INPSTARTRANGE,A1
    JSR USRINPUT
    LEA M_INPENDRANGE,A1
    LEA INPEND,A2
    JSR USRINPUT
    MOVEA.L (A5),A5
    MOVEA.L (A6),A6
    
MAINLOOP:
    CMP.L   A5,A6       *Check for End of Range
    BLE     EXIT        *Branch to Exit
    *MOVEA.L A3,A4       * Buffer
    *MOVE.W  #$4D71,(A5) *Test!
    MOVE.W  (A5),D6       * Get and move instruction and increment
    
                   
    AND.W   #$F000,D6   *AND to get the first 4 bits
    MOVE.L  #10,D4
    LSR.L   D4,D6
    MOVE.L  D6,A0

    MOVE.L  table(A0),A0    *load address of jump point from table using OPCODE
    JMP     (A0)   *jump to corresponding section
                    
   

*----------------------------------------------------------
*Table that will use the 4 bits to jump to the correct instruction
*-----------------------------------------------------------
table       dc.l    value0000
            dc.l    value0001
            dc.l    value0010
            dc.l    value0011
            dc.l    value0100
            dc.l    value0101
            dc.l    value0110
            dc.l    value0111
            dc.l    value1000
            dc.l    value1001
            dc.l    value1010
            dc.l    value1011
            dc.l    value1100
            dc.l    value1101
            dc.l    value1110
            dc.l    value1111
            
            
value0000               *Check for CMPI OPWORD
value0001
value0010
value0011            
value0100   CMP.W #$4D71,(A5)   *Check for NOP OPWORD
            BNE N_NOP
            JSR SR_NOP
            BRA MAINLOOP
N_NOP:
            JSR SR_DATA
            BRA MAINLOOP
            
value0101
value0110
value0111
value1000
value1001
value1010
value1011
value1100
value1101
value1110
value1111

*---------------------------------------------------------------
*Set Text Buffer to Data can't disassemble instruction
*---------------------------------------------------------------


* USER INPUT
* __________
USRINPUT:
    MOVE.B  #14,D0          *displays input message
    TRAP    #15
    BRA     INPSTR
    
BADINPUT:
    LEA     M_INPINVALID, A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     INPSTR 

INPSTR:
    MOVEA.L A2,A1
    MOVE.B  #2,D0
    TRAP    #15

    CMP.B   #$0,(A1)
    BEQ     BADINPUT
    CMP.B   #6,D1
    BGT     BADINPUT
    MOVE.B  D1,D2
INPSTR_01:
    CMP.B   #0,D1
    BEQ     INPSTR_02
    CMP.B   #$46,(A1)
    BGT     BADINPUT
    CMP.B   #$30,(A1)
    BLT     BADINPUT
    SUBI.B  #1,D1
    ADDA.W  #1,A1
    BRA     INPSTR_01
INPSTR_02:    
    MOVEA.L A2,A1
    MOVE.B  D2,D1
    JSR STRING_HEX
    MOVE.L  (A1),D4
    CMP.L   #$1000,D4
    BLT     BADINPUT
    RTS
    
    
*STRING TO HEX
*PRECONDITIONS:
*   Memory location of string must be loaded into A1
*   Length of string must be loaded into D1
*REGISTERS USED:
*   D0,D1,D2,D3,D4,A1,A2
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
    MOVEA.L A2,A1
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
    LSL.L   #4,D3
    OR.L    D2,D3
    ADDQ.B  #1,D0 
    ADDA.W  #1,A1          *increment pointer
    BRA     STRING_HEX_01   
    
    
*HEX TO STRING LONG
*PRECONDITIONS:
*   Long Hex Address to be converted located in D1
*REGISTERS USED:
*   D1,D2,D3,D4,D5,A1,A2
*POSTCONDITIONS:
*   String conversion of Long Address Located at memory location $540
*NOTES:
*   CLEARS Two long lengths worth of memory at $540
*   Converts a Long Hex Address into a string for display
*_____________
HEX_STRING_L:
    MOVE.L  LONGNIBBLEMASK,D2
    MOVE.B  #8,D4
    LEA     STRHEXOUT,A2
    
HEX_STRING_L_01:
    MOVE.L  D2,D3 *Make a copy of the mask
    AND.L   D1,D3 *And the address with the copy of the mask, overwriting the mask
    MOVE.L  D4,D5
    SUBI.L  #1,D5
    MULS.W  #4,D5
    LSR.L   D5,D3 *Shift the resultant value to the LSB
    CMP.B   #$9,D3
    BLE     HEX_STRING_L_03
    ADDI.B  #$7,D3
HEX_STRING_L_03:
    ADDI.B  #$30,D3
    MOVE.B  D3,(A2)
    ROR.L   #4,D2 *Rotate the original mask
    SUBI.B  #1,D4 *Move the counter
    ADDA.W  #1,A2 *Move the address pointer
    CMP.B   #0,D4
    BNE     HEX_STRING_L_02
    MOVE.B  #$0,(A2)
    RTS
HEX_STRING_L_02:
    BRA     HEX_STRING_L_01
    
    
*NOP SUBROUTINE
*______________
SR_NOP:
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JSR to DATA and then RTS here.)
    MOVE.W  (A5),D1
    *As this must be exactly NOP to get here, no validation is necessary.
    
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return of Line Feed
    TRAP    #15
    MOVE.L  #$094E4F50,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    MOVE.B  #13,D0
    TRAP    #15
    
    *BRANCH FOR <EA> MODE AND READ EA INFO
    *No branching is necessary as there are no arguments for NOP
    
    *OUTPUT EA INFORMATION
    *No output is necessary here as there are no arguments for NOP
    
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS  


*DATA SUBROUTINE
*_______________ 
SR_DATA:  

    
*EXIT
*____
EXIT:
    NOP *REPLACE WITH EOF OUTPUT
    
    
*CONSTANTS AND PARAMETERS
*________________________
CR       EQU    $0D
LF       EQU    $0A
LONGNIBBLEMASK      DC.L    $F0000000
M_INPSTARTRANGE     DC.B    'Enter Start Range of Memory',CR,LF,0
M_INPENDRANGE       DC.B    'Enter End Range of Memory',CR,LF,0
M_INPINVALID        DC.B    'Input is invalid, try again',CR,LF,0
    ORG     $500
    DC.L    8
    ORG     $520
    DC.L    8
    END     START




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
