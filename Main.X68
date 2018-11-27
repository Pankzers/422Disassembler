INPSTART  EQU $500
INPEND    EQU $550  
    ORG    $1000
START:                

    LEA     MESSAGE1, A1
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
                           

* Put variables and constants here

EXIT:
CR       EQU    $0D
LF       EQU    $0A
MESSAGE1 DC.B   'Enter ASCII value to be converted to HEX',CR,LF,0
    ORG $500
    DC.L 8

    END    START        ; last line of source     

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
