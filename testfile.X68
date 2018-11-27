*-----------------------------------------------------------
* Title      : Disassembler Test Program
* Written by : Connor Browne
* Date       : 11/23/18
* Description: Used to test the disassembler program
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    MOVE.L $1111,A0
    MOVE.B #1,D0
    MOVE.B D0,D1
    MOVEA.L A0,A1
    MOVEA.B +(A0),A2
    
    
* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
