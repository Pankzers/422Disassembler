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
    LEA INPSTART,A2
    MOVE.B  #30,D7
MAINBADRANGE:
    LEA M_INPSTARTRANGE,A1
    JSR USRINPUT
    LEA M_INPENDRANGE,A1
    LEA INPEND,A2
    JSR USRINPUT
    MOVEA.L (A5),A5
    MOVEA.L (A6),A6
    CMP.L A6,A5
    BGE MAINBADRANGE
    
MAINLOOP:
    CMP.B   #0,D7
    BEQ     MAINLOOP_HOLD
    CMP.L   A5,A6         *Check for End of Range
    BLT     EXIT          *Branch to Exit
    MOVE.W  (A5),D6       * Get and move instruction and increment
    
                   
    AND.W   #$F000,D6   *AND to get the first 4 bits
    MOVE.L  #10,D4
    LSR.L   D4,D6
    MOVE.L  D6,A0

    MOVE.L  table(A0),A0    *load address of jump point from table using OPCODE
    SUBI.B  #1,D7
    JMP     (A0)   *jump to corresponding section
                    
MAINLOOP_HOLD:
    MOVE.B  #14,D0      *output enter message
    LEA     M_HOLD,A1
    TRAP    #15
ENTER_HOLD:
    MOVE.B  #5,D0       *Wait for user to press enter
    TRAP    #15
    
    CMP.B   #$D,D1
    BNE     ENTER_HOLD
    
    MOVE.W  #$FF00,D1   *Clear Terminal
    MOVE.B  #11,D0
    TRAP    #15
    
    MOVE.B  #30,D7      *Reset Counter
    BRA MAINLOOP
    

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
            
            
value0000   MOVE.L (A5),D1     *Check for CMPI OPWORD. CHANGE HEX!
            ANDI.W #$C000,D1
            CMP.W #$C000, D1
            BNE N_CMPI
            JSR SR_CMPI
            BRA MAINLOOP
            
N_CMPI:     EOR.L D1,D1
            MOVE.W (A5),D1
            CMP.W #$0, D1      *Check for ORI OPWORD. CHANGE HEX!
            BNE N_ORI
            JSR SR_ORI
            BRA MAINLOOP
            
N_ORI:      EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$180,D1      * BITWISE AND TO CHECK IF = 111 = BCLR  
            CMP.W #$180,D1        *CHECK FOR  BCLR  WORD
            BNE N_BCLR
            JSR SR_BCLR
            BRA MAINLOOP 
N_BCLR:
            JSR SR_DATA
            BRA MAINLOOP

  
         
value0001
            MOVE.L (A5),D1
            JSR SR_MOVE                     *INSTRUCTION = MOVE.B
            BRA MAINLOOP
            
value0010
            MOVE.L (A5),D1
            AND.W #$40,D1
            CMP.W #$40,D1
            BNE N_MOVEA
            JSR SR_MOVEA                     *INSTRUCTION IS EITHER MOVE.L OR MOVEA.L
            BRA MAINLOOP
           
N_MOVEA     JSR SR_MOVE
            BRA MAINLOOP
            
            
value0011
            MOVE.L (A5),D1
            AND.W #$40,D1
            CMP.W #$40,D1
            BNE N_MOVEA_2        *INSTRUCTION IS MOVE.W OR MOVEA.W
            JSR SR_MOVEA
            BRA MAINLOOP
            
N_MOVEA_2   JSR SR_MOVE
            BRA MAINLOOP
            
value0100   CMP.W #$4E71,(A5)   *Check for NOP OPWORD
            BNE N_NOP
            JSR SR_NOP
            BRA MAINLOOP
            
N_NOP:
            CMP.W #$4E75,(A5)   *Check for RTS OPWORD
            BNE N_RTS
            JSR SR_RTS
            BRA MAINLOOP
            
N_RTS:
            EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$FF00,D1
            CMP.W #$4400,D1     *Check for NEG OPWORD
            BNE N_NEG
            JSR SR_NEG
            BRA MAINLOOP
            
N_NEG:      EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$1C0,D1        * BITWISE AND TO CHECK IF = 111 = LEA  
            CMP.W #$1C0,D1        *CHECK FOR  LEA WORD
            BNE N_LEA
            JSR SR_LEA
            BRA MAINLOOP
                       
N_LEA:      EOR.L D1,D1
            MOVE.W (A5),D1
            CMP.W #$E80,(A5)    *Check for JSR OPWORD.
            BNE N_JSR
            JSR SR_JSR
            BRA MAINLOOP
                     
N_JSR:      EOR.L D1,D1
            MOVE.W (A5),D1
            ANDI.W #$0F00,D1    * BITWISE AND TO GET 2nd set of bits 11-8 position
            CMP.B #$E,D1        * CHECK IF THE BITS = E(1110) IF YES = JSR
            BNE  N_JSR_02
            JSR SR_JSR           
            BRA MAINLOOP     
N_JSR_02:
            JSR SR_DATA
            BRA MAINLOOP      
                        
            
value0101   MOVE.W (A5),D1
            AND.W #$0100,D1
            CMP.W #$0100,D1
            BNE N_SUBQ
            JSR SR_SUBQ
            BRA MAINLOOP
N_SUBQ:
            JSR SR_DATA
            BRA MAINLOOP
            
value0110   EOR.L D1,D1
            MOVE.W (A5),D1
            CMP.W #$0000,(A5)    *Check for BCS OPWORD. CHANGE HEX!
            BNE N_BCS
            JSR SR_BCS
            BRA MAINLOOP
            
N_BCS:      EOR.L D1,D1
            MOVE.W (A5),D1
            CMP.W #$0000,(A5)      *Check for BGE OPWORD. CHANGE HEX!
            BNE N_BGE
            JSR SR_BGE
            BRA MAINLOOP    

N_BGE:      EOR.L D1,D1
            MOVE.W (A5),D1
            CMP.W #$0000,(A5)      *Check for BLT OPWORD. CHANGE HEX!
            BNE N_BLT
            JSR SR_BLT
            BRA MAINLOOP    

N_BLT:      EOR.L D1,D1
            MOVE.W (A5),D1
            CMP.W #$0000,(A5)      *Check for BVC OPWORD. CHANGE HEX!
            BNE N_BVC
            JSR SR_BVC
            BRA MAINLOOP   

N_BVC:      EOR.L D1,D1
            MOVE.W (A5),D1
            CMP.W #$0000,(A5)      *Check for BRA OPWORD. CHANGE HEX!
            BNE N_BRA
            JSR SR_BRA
            BRA MAINLOOP 

N_BRA:      
            *CMP.W #$0000,(A5)    
            BNE N_BRA_02            *not sure where to branch with last opword
            JSR SR_BRA
            BRA MAINLOOP
N_BRA_02:
                
            JSR SR_DATA            *not sure where to branch with last opword
            BRA MAINLOOP          
            
            
value0111
            JSR SR_DATA
            BRA MAINLOOP
            
value1000   
            MOVE.W (A5),D1
            AND.W #$1C0,D1      * BITWISE AND TO CHECK IF = 111 = DIVS  
            CMP.W #$1C0,D1        *CHECK FOR  DIVS WORD
            BEQ SR_DIVS
            JSR N_DIVS
            BRA MAINLOOP
            

N_DIVS:     
            CMP.W #6,D1
            BGT N_OR
            JSR SR_OR
            BRA MAINLOOP
            *THIS CODE SHOULD NOT BE ACCESSED IT IS BAD!
            CMP.W #0,D1
            BEQ SR_SUB           * IF 000 then OR.B 
            CMP.W #1,D1
            BEQ SR_SUB            * IF 001 then OR.W -> < ea > V Dn -> Dn 
            CMP.W #2,D1
            BEQ SR_SUB           * IF 010 then OR.L -> < ea > V Dn -> Dn 
            CMP.W #4,D1
            BEQ SR_SUB           * IF 100 then OR.B -> Dn V < ea > -> < ea > 
            CMP.W #5,D1
            BEQ SR_SUB           * IF 101 then OR.W -> Dn V < ea > -> < ea > 
            CMP.W #6,D1
            BEQ SR_SUB           * IF 110 then OR.L -> Dn V < ea > -> < ea > 
            
N_OR:            
            JSR SR_DATA
            BRA MAINLOOP 
            
                      
value1001   
            CMP.W #6,D1
            BGT N_SUB
            JSR SR_SUB
            BRA MAINLOOP
            *THIS CODE SHOULD NOT BE ACCESSED IT IS BAD!
            CMP.W #0,D1
            BEQ SR_SUB           * IF 000 then SUB.B 
            CMP.W #1,D1
            BEQ SR_SUB            * IF 001 then SUB.W -> < ea > V Dn -> Dn 
            CMP.W #2,D1
            BEQ SR_SUB           * IF 010 then SUB.L -> < ea > V Dn -> Dn 
            CMP.W #4,D1
            BEQ SR_SUB           * IF 100 then SUB.B -> Dn V < ea > -> < ea > 
            CMP.W #5,D1
            BEQ SR_SUB           * IF 101 then SUB.W -> Dn V < ea > -> < ea > 
            CMP.W #6,D1
            BEQ SR_SUB           * IF 110 then SUB.L -> Dn V < ea > -> < ea > 
            
N_SUB:
            JSR SR_DATA
            BRA MAINLOOP 

            
value1010
            JSR SR_DATA
            BRA MAINLOOP
            
value1011   MOVE.W (A5),D1
            AND.W #$0100,D1
            CMP.W #$0100,D1
            BLT CMP
            JSR SR_EOR
            BRA MAINLOOP
            
CMP:
        JSR SR_CMP
        BRA MAINLOOP            
         
                    
value1100
            MOVE.W (A5),D1
            AND.W #$1C0,D1      * BITWISE AND TO CHECK IF = 111 = MULS  
            CMP.W #$1C0,D1        *CHECK FOR  MULS WORD
            BNE N_MULS
            JSR SR_MULS
            BRA MAINLOOP
N_MULS:
            JSR SR_DATA
            BRA MAINLOOP
            

value1101   
            CMP.W #6,D1
            BGT N_ADD
            JSR SR_ADD
            BRA MAINLOOP
            *THIS CODE SHOULD NOT BE ACCESSED IT IS BAD!
            CMP.W #0,D1
            BEQ SR_ADD           * IF 000 then ADD.B 
            CMP.W #1,D1
            BEQ SR_ADD            * IF 001 then ADD.W -> < ea > V Dn -> Dn 
            CMP.W #2,D1
            BEQ SR_ADD           * IF 010 then ADD.L -> < ea > V Dn -> Dn 
            CMP.W #4,D1
            BEQ SR_ADD           * IF 100 then ADD.B -> Dn V < ea > -> < ea > 
            CMP.W #5,D1
            BEQ SR_ADD           * IF 101 then ADD.W -> Dn V < ea > -> < ea > 
            CMP.W #6,D1
            BEQ SR_ADD           * IF 110 then ADD.L -> Dn V < ea > -> < ea > 
                        
            JSR N_ADD
            
N_ADD:
            BRA N_ADDA
            *THIS CODE SHOULD NOT BE ACCESSED IT IS BAD!
            CMP.W #3,D1
            BEQ SR_ADDA            * IF 011 then ADD.B 
            CMP.W #7,D1
            BEQ SR_ADDA            * IF 111 then ADD.W -> < ea > V Dn -> Dn 
            JSR N_ADDA
         
N_ADDA: 
            JSR SR_DATA
            BRA MAINLOOP                
            
                       
value1110   
            JSR SR_DATA
            BRA MAINLOOP
            *THIS CODE SHOULD NOT BE ACCESSED IT IS BAD!
            MOVE.W (A5),D1
            AND.W #$8,D1                   *CHECK LSL/LSR
            BEQ LSL_LSR
            BRA IS_ROL_ROR   
            *BRA MAINLOOP
            
LSL_LSR     EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$100,D1
            BEQ SR_LSL
            JSR SR_LSR
            



IS_ROL_ROR  EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$18,D1                   *CHECK LSL/LSR
            BEQ ROL_ROR
            JSR ASL_ASR   
            

ROL_ROR     EOR.L D1,D1
            MOVE.W (A5),D1
            AND.W #$100,D1
            BEQ SR_ROL
            JSR SR_LSR

ASL_ASR
            
value1111
            JSR SR_DATA
            BRA MAINLOOP

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
    MOVEM.L D0-A6,-(sp)
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
    MOVEM.L (sp)+,D0-A6
    RTS
HEX_STRING_L_02:
    BRA     HEX_STRING_L_01


*NOP SUBROUTINE
*______________
SR_NOP:
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JSR to DATA and then RTS here.)
        *Reading OPWORD is pointless here, so it is skipped
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
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No branching is necessary as there are no arguments for NOP
    
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS   
 
 
*MOVE SUBROUTINE
*______________
SR_MOVE:
MOVE_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
MOVE_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2                                *UPDATE VALIDITY 
         ANDI.B #$C0,D2
         LSR.B  #4,D2
         LEA SR_DATA, A3
         CMPA.L MOVE_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_MOVE_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_MOVE_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094F5645,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$4500,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L MOVE_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS   
    
 
*MOVEA SUBROUTINE
*______________
SR_MOVEA:
MOVEA_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
MOVEA_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2                                *UPDATE VALIDITY 
         ANDI.B #$C0,D2
         LSR.B  #4,D2
         LEA SR_DATA, A3
         CMPA.L MOVEA_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_MOVEA_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_MOVEA_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094F5645,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$4541,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L MOVEA_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS   

 
*MOVEM SUBROUTINE
*______________
SR_MOVEM:
MOVEM_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
MOVEM_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2                                *UPDATE VALIDITY 
         ANDI.B #$C0,D2
         LSR.B  #4,D2
         LEA SR_DATA, A3
         CMPA.L MOVEM_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_MOVEM_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_MOVEM_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094F5645,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$454D,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L MOVEM_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS     
 
  
*ADD SUBROUTINE
*______________
SR_ADD:
ADD_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ADD_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                          *UPDATE VALIDITY
    LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L ADD_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_ADD_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_ADD_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09414444,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L ADD_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 

     
*ADDA SUBROUTINE
*______________
SR_ADDA:
ADDA_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ADDA_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2
         ANDI.B #$C0,D2                              *UPDATE VALIDITY
         LSR.B  #4,D2
         LEA SR_DATA, A3
         CMPA.L ADDA_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_ADDA_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_ADDA_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09414444,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$4100,(A2)     *Last value of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L CMPI_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS   
    
    
*SUB SUBROUTINE
*______________
SR_SUB:
SUB_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
SUB_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                          *UPDATE VALIDITY
    LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L SUB_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_SUB_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_SUB_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09535542,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L SUB_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 


*SUBQ SUBROUTINE
*______________
SR_SUBQ:
SUBQ_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
SUBQ_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2
         ANDI.B #$C0,D2                         *LIKELY NEED TO CHANGE THESE VALUES
         LSR.B  #4,D2                           *LIKELY NEED TO CHANGE SHIFT AMOUNT TOO
         LEA SR_DATA, A3
         CMPA.L SUBQ_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_SUBQ_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_SUBQ_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09535542,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$5100,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L SUBQ_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS    
        

*CMP SUBROUTINE
*______________
SR_CMP:
CMP_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
CMP_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                                   *UPDATE VALIDITY
    LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L CMP_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_CMP_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_CMP_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09435D50,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L CMP_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
 
 
*CMPI SUBROUTINE
*______________
SR_CMPI:
CMPI_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
CMPI_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2
         ANDI.B #$C0,D2                    *UPDATE VALIDITY
         LSR.B  #4,D2
         LEA SR_DATA, A3
         CMPA.L CMPI_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_CMPI_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_CMPI_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09434D50,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$4900,(A2)     *Last value of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L CMPI_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS    


*MULS SUBROUTINE
*______________
SR_MULS:
MULS_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
MULS_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2
         ANDI.B #$C0,D2                         *LIKELY NEED TO CHANGE THESE VALUES
         LSR.B  #4,D2                           *LIKELY NEED TO CHANGE SHIFT AMOUNT TOO??
         LEA SR_DATA, A3
         CMPA.L MULS_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_MULS_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_MULS_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$094D554C,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$5300,(A2)     *Last value of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L MULS_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS    
   

*DIVS SUBROUTINE
*______________
SR_DIVS:
DIVS_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
DIVS_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2
         ANDI.B #$C0,D2                         *LIKELY NEED TO CHANGE THESE VALUES
         LSR.B  #4,D2                           *LIKELY NEED TO CHANGE SHIFT AMOUNT TOO??
         LEA SR_DATA, A3
         CMPA.L DIVS_SIZE(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_DIVS_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_DIVS_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$09444956,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$5300,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L DIVS_SIZE(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS    


*LEA SUBROUTINE
*______________
SR_LEA:
LEA_EA   DC.L    SR_DATA,SR_DATA,EA_ADDRIND,SR_DATA,SR_DATA,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
     
    *NOT SURE ABOUT LAST 2 NAMES ON LIST!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$38,D2                     *VALIDATING FOR EAMODE BITS 
   * LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L LEA_EA(PC,D2),A3
    BEQ    SR_DATA
    ***BRA SR_LEA_OUT                  MOVED THIS UNDER EA CALCULATIONS ????
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
    BRA SR_LEA_OUT    
    ******************
    *PRINT OUT
    ******************
SR_LEA_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094C4541,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L LEA_EA(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 

*NEG SUBROUTINE
*______________
SR_NEG:
    *DEFINE RELEVANT LISTS
NEG_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
NEG_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W  #1,A2
    EOR.L   D2,D2
    MOVE.B  (A2),D2 *Size Code
    ANDI.B  #$C0,D2
    LSR.B   #4,D2
    LEA     SR_DATA,A3
    CMPA.L  NEG_SIZE(PC,D2),A3
    BEQ     SR_DATA
    
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *Bitmask EA Mode
    ANDI.B  #$07,D4 *Bitmask EA Register
    LSR.B   #1,D3
    
    CMP.B   #$1C,D3
    BNE     SR_NEG_NOT_111
    *MOVE.B  D4,D5
    *LSL.B   #2,D5
    ADD.B   D4,D3
    CMPA.L  NEG_EA(PC,D3),A3
    BEQ     SR_DATA
    BRA     SR_NEG_OUT
SR_NEG_NOT_111:
    CMPA.L  NEG_EA(PC,D3),A3
    BEQ     SR_DATA
SR_NEG_OUT:
        
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094E4547,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    *MOVE.B  #13,D0
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L NEG_SIZE(A4),A4
    JSR     (A4)
    MOVE.L  D3,A4
    MOVEA.L NEG_EA(A4),A4
    EOR.L   D5,D5
    JSR     (A4)
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No branching is necessary as there are no arguments for NOP
    
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15
    
    *RTS
    RTS  
    
    
*OR SUBROUTINE
*______________
SR_OR:
OR_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
OR_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                           *UPDATE VALIDITY
    LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L OR_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_OR_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_OR_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094F5220,(A1)   *PRINTS OUT OR IN ASCI, WITH SPACE AT END
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L OR_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
    

*ORI SUBROUTINE
*______________
SR_ORI:
ORI_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ORI_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2
    LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L ORI_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_ORI_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_ORI_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094F5249,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L ORI_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
    
 
*EOR SUBROUTINE
*______________
SR_EOR:
EOR_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
EOR_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2
    LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L EOR_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_EOR_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_EOR_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094F5249,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L EOR_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 

  
*LSR SUBROUTINE
*______________
SR_LSR:
LSR_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
LSR_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2
    LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L LSR_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_LSR_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_LSR_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094C5352,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L LSR_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
    

*LSL SUBROUTINE
*______________
SR_LSL:
LSL_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
LSL_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                      *UPDATE VALIDITY 
    LSR.B  #4,D2                 
    LEA SR_DATA, A3
    CMPA.L LSL_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_LSL_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_LSL_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$095C534C,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L LSL_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 



*ASR SUBROUTINE
*______________
SR_ASR:
ASR_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ASR_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                      *UPDATE VALIDITY 
    LSR.B  #4,D2                 
    LEA SR_DATA, A3
    CMPA.L ASR_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_ASR_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_ASR_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09415352,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L ASR_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
    

*ASL SUBROUTINE
*______________
SR_ASL:
ASL_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ASL_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                      *UPDATE VALIDITY 
    LSR.B  #4,D2                 
    LEA SR_DATA, A3
    CMPA.L ASL_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_ASL_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_ASL_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$0941534C,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L ASL_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 


*ROL SUBROUTINE
*______________
SR_ROL:
ROL_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ROL_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                      *UPDATE VALIDITY 
    LSR.B  #4,D2                 
    LEA SR_DATA, A3
    CMPA.L ROL_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_ROL_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_ROL_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09524F4C,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L ROL_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 

    
*ROR SUBROUTINE
*______________
SR_ROR:
ROR_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
ROR_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                      *UPDATE VALIDITY 
    LSR.B  #4,D2                 
    LEA SR_DATA, A3
    CMPA.L ROR_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_ROR_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_ROR_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09524F52,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L ROR_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 

  
*BCS SUBROUTINE
*______________
SR_BCS:
    NOP *DO STUFF HERE
    ADDA.W  #2,A5
    RTS 
    

*BGE SUBROUTINE
*______________
SR_BGE:
    NOP *DO STUFF HERE
    ADDA.W  #2,A5
    RTS     
    
    
*BLT SUBROUTINE
*______________
SR_BLT:
    NOP *DO STUFF HERE
    ADDA.W  #2,A5
    RTS     
    
    
*BVC SUBROUTINE
*______________
SR_BVC:
    NOP *DO STUFF HERE
    ADDA.W  #2,A5
    RTS 
  
  
*BCLR SUBROUTINE
*______________
SR_BCLR:
BCLR_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
        *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
         MOVEA.L A5,A2
         ADDA.W #1,A2
         EOR.L D2,D2
         MOVE.B (A2),D2
         ANDI.B #$38,D2                         *LIKELY NEED TO CHANGE THESE VALUES
         LSR.B  #1,D2                           *ONLY NEED TO SHIFT By 1
         LEA SR_DATA, A3
         CMPA.L BCLR_EA(PC,D2),A3
         BEQ    SR_DATA
         BRA SR_BCLR_OUT
         
        
        ******************
        *EA MODE CALCULATION
        ******************
         EOR.L   D3,D3
         EOR.L   D4,D4
         MOVE.B  (A2),D3 *Move OPWORD to D3
         MOVE.B  D3,D4   *MOVE OPWORD to D4
         ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
         ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
        ******************
        *PRINT OUT
        ******************
SR_BCLR_OUT        
        MOVE.L  A5,D1
        JSR     HEX_STRING_L
        LEA     STRHEXOUT,A1
        MOVE.B  #14,D0          *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
        TRAP    #15
        MOVE.L  #$0942434C,(A1) *Store hex value of ASCII output
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.W  #$5200,(A2)     *Last 2 values of ASCII (since 4 letter OP)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L BCLR_EA(A4),A4
        JSR     (A4)
        
        ADDA.W  #2,A5
        
        RTS    
 
    
    
*BRA SUBROUTINE
*______________
SR_BRA:
BRA_SIZE    DC.L    SIZE_BYTE,SIZE_WORD,SIZE_LONG,SR_DATA
BRA_EA      DC.L    EA_DATA,SR_DATA,EA_ADDRIND,EA_ADDRIND_PINC,EA_ADDRIND_PDEC,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$C0,D2                      *UPDATE VALIDITY 
    LSR.B  #4,D2                 
    LEA SR_DATA, A3
    CMPA.L BRA_SIZE(PC,D2),A3
    BEQ    SR_DATA
    BRA SR_BRA_OUT
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
        
    ******************
    *PRINT OUT
    ******************
SR_BRA_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$09425241,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L BRA_SIZE(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
  
    
    
*JSR SUBROUTINE                              *NOT SURE IF THIS IS RIGHT 
*______________
SR_JSR:
JSR_EA      DC.L    SR_DATA,SR_DATA,EA_ADDRIND,SR_DATA,SR_DATA,SR_DATA,SR_DATA,EA_ABS_LONG,EA_ABS_SHORT,SR_DATA,SR_DATA,SR_DATA 
     
    *NOT SURE ABOUT LAST 2 NAMES ON LIST!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JMP to DATA and then RTS to main.)
    MOVEA.L A5,A2
    ADDA.W #1,A2
    EOR.L D2,D2
    MOVE.B (A2),D2
    ANDI.B #$38,D2                     *VALIDATING FOR EAMODE BITS 
   * LSR.B  #4,D2
    LEA SR_DATA, A3
    CMPA.L JSR_EA(PC,D2),A3
    BEQ    SR_DATA
    ***BRA SR_JSR_OUT         MOVED THIS UNDER EA CALCULATIONS ????
    ********************
    *EA MODE CALCULATION
    ******************
    EOR.L   D3,D3
    EOR.L   D4,D4
    MOVE.B  (A2),D3 *Move OPWORD to D3
    MOVE.B  D3,D4   *MOVE OPWORD to D4
    ANDI.B  #$38,D3 *BITMASK TO FIND EA MODE
    ANDI.B  #$07,D4 *BITMASK TO FIND REGISTER VALUE
    BRA SR_JSR_OUT    
    ******************
    *PRINT OUT
    ******************
SR_JSR_OUT        
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return or Line Feed
    TRAP    #15
    MOVE.L  #$094F5249,(A1) 
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    TRAP    #15
    MOVE.L  D2,A4
    MOVEA.L JSR_EA(A4),A4
    JSR     (A4)
        
    ************************
    * GET EA TO PRINT OUT
    ************************
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    *OUTPUT FINAL CR,LF
    LEA STRHEXOUT,A1
    MOVE.B  #14,D0
    MOVE.L  #$0D0A0000,(A1)
    TRAP    #15

    RTS 
    
    
*RTS SUBROUTINE
*______________
SR_RTS:
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JSR to DATA and then RTS here.)
        *Reading OPWORD is pointless here, so it is skipped
        *As this must be exactly NOP to get here, no validation is necessary.
    
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0 *TRAP TASK 14, Output A1 with no Carriage Return of Line Feed
    TRAP    #15
    *MOVE.L  #$094E4F50,(A1)
    MOVE.L  #$09525453,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    MOVE.B  #13,D0
    TRAP    #15
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No branching is necessary as there are no arguments for NOP
    
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS       


*DATA SUBROUTINE
*_______________ 
SR_DATA:  
    *READ OP WORD AND CONFIRM VALIDITY (Otherwise JSR to DATA and then RTS here.)
        *Reading OPWORD is pointless here, so it is skipped
        *DATA requires no validation as it is, well Data.
    
    *OUTPUT MEMORY ADDRESS AND OPERATION NAME
    MOVE.L  A5,D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVE.B  #14,D0
    TRAP    #15             *Output Address
    MOVE.L  #$09444154,(A1)
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.L  #$41090000,(A2)
    TRAP    #15             *Output Operation name
    
    
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No EA for DATA, thus no branching here
    MOVE.W  (A5),D1
    SWAP    D1
    JSR     HEX_STRING_L
    LEA     STRHEXOUT,A1
    MOVEA.L A1,A2
    ADDA.W  #4,A2
    MOVE.B  #$0,(A2)
    MOVE.B  #13,D0
    TRAP    #15             *Output Invalid Data found at current working word to terminal
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS 


size_byte:
            LEA STRHEXOUT,A1
            MOVE.L  #$2E420900,(A1)
            MOVE.B  #14,D0
            TRAP    #15
            RTS
size_long:
            LEA STRHEXOUT,A1
            MOVE.L  #$2E4C0900,(A1)
            MOVE.B  #14,D0
            TRAP    #15
            RTS
size_word:
            LEA STRHEXOUT,A1
            MOVE.L  #$2E570900,(A1) 
            MOVE.B  #14,D0
            TRAP    #15
            RTS

*EFFECTIVE ADDRESSING MODE FOR DATA REGISTER DIRECT
*USES VALUE IN D5 TO CHOOSE 1ST or 2ND ARGUMENT, AND D6 TO OUTPUT COMMA AFTER.
EA_DATA:
    LEA STRHEXOUT,A1
    MOVE.W  (A5),D2
    CMP.B   #1,D5
    BEQ EA_DATA_2ND
    AND.W   #$0007,D2
    BRA EA_DATA_2
EA_DATA_2ND:
    AND.W   #$0E00,D2
    MOVE.B  #9,D1
    LSR.W   D1,D2

EA_DATA_2:
    MOVE.B  #$44,(A1)+
    *ADDA.W  #2,A1
    ADD.B   #$30,D2
    MOVE.B  D2,(A1)+
    *ADDA.W  #2,A1
    CMP.B   #1,D6
    BNE     EA_DATA_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_DATA_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    
    RTS
EA_ADDR:
    LEA STRHEXOUT,A1
    MOVE.W  (A5),D2
    CMP.B   #1,D5
    BEQ EA_ADDR_2ND
    AND.W   #$0007,D2
    BRA EA_ADDR_2
EA_ADDR_2ND:
    AND.W   #$0E00,D2
    MOVE.B  #9,D1
    LSR.W   D1,D2

EA_ADDR_2:
    MOVE.B  #$44,(A1)+
    *ADDA.W  #2,A1
    ADD.B   #$30,D2
    MOVE.B  D2,(A1)+
    *ADDA.W  #2,A1
    CMP.B   #1,D6
    BNE     EA_ADDR_NOCOMMA
    MOVE.B  #$2C,(A1)+
EA_ADDR_NOCOMMA
    MOVE.B  #0,(A1)
    MOVE.B  #14,D0
    LEA     STRHEXOUT,A1
    TRAP    #15
    
    RTS

EA_ADDRIND:
    RTS
EA_ADDRIND_PINC:
    RTS
EA_ADDRIND_PDEC:
    RTS
EA_ABS_LONG:
    RTS
EA_ABS_SHORT:
    RTS
EA_IMM:
    RTS
    
            
   
*EXIT
*____
EXIT:
    LEA     STRHEXOUT,A1
    MOVE.L  #$454F4600,(A1)
    MOVE.B  #14,D0
    TRAP    #15

    
    
*CONSTANTS AND PARAMETERS
*________________________
CR      EQU    $0D
LF      EQU    $0A
ASCII   DC.B    $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$41,$42,$43,$44,$45,$46
LONGNIBBLEMASK      DC.L    $F0000000
M_INPSTARTRANGE     DC.B    'Enter Start Range of Memory',CR,LF,0
M_INPENDRANGE       DC.B    'Enter End Range of Memory',CR,LF,0
M_INPINVALID        DC.B    'Input is invalid, try again',CR,LF,0
M_HOLD              DC.B    'Press Enter to scroll',0
    ORG     $500
    DC.L    8
    ORG     $520
    DC.L    8
    END     START










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~






