*-----------------------------------------------------------
* Title      : Disassembler Test Program
* Written by : Connor Browne
* Date       : 11/23/18
* Description: Used to test the disassembler program
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* MOVE
    MOVE.L $1111,A0
    MOVE.B #1,D0
    MOVE.B D0,D1
* MOVEA    
    MOVEA.L A0,A1
    MOVEA.W -(A0),A2
* MOVEM    
    MOVEM.L A0-A2,$5000
    MOVEM.L $4980,A0-A2
* ADD and ADDA    
    ADD.B D0,D1
    ADDA.L A0,A1
* SUB and SUBA    
    SUB.B D0,D1
    SUBA.L A0,A1
* MULS    
    MULS.W #4,D0
    MULS.W #$0000FFFF,D0
* DIVS    
    MOVE.B #8,D0
    DIVS.W #2,D0
* LEA
    LEA.L $5000,A4    
* OR
    MOVE.L #$55555555,D2
    OR.L #$FFFFFFFF, D2
    OR.B #1,D2
    OR.L D2,(A0)
* ORI
    ORI.B #6,D2
    ORI.L #6,(A2)
* NEG
    NEG.L D2
    NEG.L (A2)
    NEG.B D2
* EOR
    
     
    
    
* Put variables and constants here

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
