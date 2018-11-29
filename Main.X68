INPSTART    EQU $500
INPEND      EQU $520
    ORG    $1000
START:                

    LEA     M_INPSTARTRANGE, A1
    MOVE.B  #14,D0          *displays input message
    TRAP    #15
    
    LEA INPSTART, A1
    MOVE.B  #2,D0           *input location stored at A1, length in D1
    TRAP    #15
   
LOOP:
    CMP.B   #0,D1
    BLE     EXIT
    MOVE.B (A1),D2
    SUBI.B  #$30,D2     
    CMP.B   #$9,D2
    BLE     NSUB11
    SUBI.B #$7,D2
NSUB11: 
    MOVE.B  D2,(A1)
    SUBQ.B  #1,D1 
    ADDA.W  #1,A1          *increment pointer
    BRA     LOOP   

* MAIN PROGRAM LOOP
*__________________    
MAIN:
    LEA INPSTART,A6
    LEA INPSTART,A7
    
    LEA INPSTART,A2
    JSR USRINPUT
    LEA INPEND,A2
    JSR USRINPUT

MAINLOOP:
    CMP.L A6,A7     *Check for End of Range
    BGE EXIT            *Branch to Exit
    
    CMP.W #$4D71,(A1)   *Check for NOP OPWORD
    BNE NOT_NOP          *Branch to NOP Subroutine
    JSR SR_NOP
NOT_NOP:
    NOP                 *PUT NON VALID OPWORD HANDLING HERE!
    BRA MAINLOOP


* USER INPUT
* __________
USRINPUT:
    LEA M_INPSTARTRANGE,A1
    MOVE.B  #14,D0          *displays input message
    TRAP    #15
    BRA INPSTR
    
BADINPUT_START:
    LEA M_INPINVALID, A1
    MOVE.B #14,D0
    TRAP #15
    BRA INPSTR 

INPSTR:
    MOVEA.L A2,A1
    MOVE.B #2,D0
    TRAP #15

    NOP *Validate User Input stored in (A1)
        *Convert to Hex
    JSR STRING_HEX
    RTS
    
    
*STRING TO HEX
*_____________
STRING_HEX:
    NOP
    RTS
    
    
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
