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
    CMP.L   A5,A6       *Check for End of Range
    BLT     EXIT        *Branch to Exit
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
            
N_CMPI:    
            CMP.W #$0, D1      *Check for ORI OPWORD. CHANGE HEX!
            BNE N_ORI
            JSR SR_ORI
            BRA MAINLOOP
            
N_ORI:      
            AND.W #$180,D1      * BITWISE AND TO CHECK IF = 111 = BCLR 
            CMP.W #$180,D1        *CHECK FOR  BCLR WORD
            BNE SR_DATA
            JSR SR_BCLR
            BRA MAINLOOP 

  
         
value0001
            JSR SR_DATA
            BRA MAINLOOP
            
value0010
            JSR SR_DATA
            BRA MAINLOOP
            
value0011
            JSR SR_DATA
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
            
N_NEG:
            LSR.W #8, D1        * SHIFT BY 8 IN D1(WORD STORED IN D1?)
            ANDI.W #7,D1        * BITWISE AND TO CHECK IF = 111 = LEA
            CMP.W #$7,D1   *Check for LEA OPWORD. CHANGE HEX!
            BNE N_LEA
            JSR SR_LEA
            BRA MAINLOOP
                       
N_LEA:      
            CMP.W #$0000,(A5)   *Check for JSR OPWORD. CHANGE HEX!
            BNE N_JSR
            JSR SR_JSR
            BRA MAINLOOP
                     
N_JSR:      
            ANDI.W #$0F00,D1    * BITWISE AND TO GET 2nd set of bits 11-8 position
            CMP.B #$E,D1        * CHECK IF THE BITS = E(1110) IF YES = JSR
            BNE  SR_DATA
            JSR SR_JSR           
            BRA MAINLOOP           
                        
            
value0101   MOVE.W (A5),D1                  
            LSR.W  #8,D1       * SHIFT BIT BY 8 TO ISOLATE LAST BIT 
            CMP.W #$1,D1       * COMPARE 1 TO THE LAST BIT IF = THEN SUBQ
            BNE SR_DATA        
            JSR SR_SUBQ
            BRA MAINLOOP
            
value0110   CMP.W #$0000,(A5)    *Check for BCS OPWORD. CHANGE HEX!
            BNE N_BCS
            JSR SR_BCS
            BRA MAINLOOP
            
N_BCS: 
            CMP.W #$0000,(A5)      *Check for BGE OPWORD. CHANGE HEX!
            BNE N_BGE
            JSR SR_BGE
            BRA MAINLOOP    

N_BGE:
            CMP.W #$0000,(A5)      *Check for BLT OPWORD. CHANGE HEX!
            BNE N_BLT
            JSR SR_BLT
            BRA MAINLOOP    

N_BLT:
            CMP.W #$0000,(A5)      *Check for BVC OPWORD. CHANGE HEX!
            BNE N_BVC
            JSR SR_BVC
            BRA MAINLOOP   

N_BVC:
            CMP.W #$0000,(A5)      *Check for BRA OPWORD. CHANGE HEX!
            BNE N_BRA
            JSR SR_BRA
            BRA MAINLOOP 

N_BRA:      
            *CMP.W #$0000,(A5)    
            BNE SR_DATA            *not sure where to branch with last opword
            JSR SR_BRA
            BRA MAINLOOP          
            
            
value0111
            JSR SR_DATA
            BRA MAINLOOP
            
value1000   MOVE.W (A5),D1
            LSR.W #8, D1        * SHIFT BY 8 IN D1(WORD STORED IN D1?)
            ANDI.W #7,D1        * BITWISE AND TO CHECK IF = 111 = DIVS
            CMP.W #$7,D1        *Check for DIVS OPWORD. 
            BNE N_DIVS
            JSR SR_DIVS
            BRA MAINLOOP
            
N_DIVS:     CMP.W #0,D1
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
                        
            JSR SR_DATA
            BRA MAINLOOP 
            

                      
value1001   CMP.W #0,D1
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
            BNE SR_DATA
            JSR SR_MULS
            BRA MAINLOOP
            
value1101   CMP.W #0,D1
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
            CMP.W #3,D1
            BEQ SR_ADDA            * IF 011 then ADD.B 
            CMP.W #7,D1
            BEQ SR_ADDA            * IF 111 then ADD.W -> < ea > V Dn -> Dn 
            JSR N_ADDA
         
N_ADDA:
            JSR SR_DATA
            BRA MAINLOOP                
            
                       
value1110   MOVE.W (A5),D1
            AND.W #$8,D1                   *CHECK LSL/LSR
            BEQ LSL_LSR
            JSR IS_ROL_ROR   
            BRA MAINLOOP
            
LSL_LSR     AND.W #$100,D1
            BEQ SR_LSL
            JSR SR_LSR
            



IS_ROL_ROR  AND.W #$18,D1                   *CHECK LSL/LSR
            BEQ ROL_ROR
            JSR ASL_ASR   
            

ROL_ROR     AND.W #$100,D1
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
    NOP *DO STUFF HERE
    RTS      
 
 
*MOVEA SUBROUTINE
*______________
SR_MOVEA:
    NOP *DO STUFF HERE
    RTS      
 
 
*MOVEM SUBROUTINE
*______________
SR_MOVEM:
    NOP *DO STUFF HERE
    RTS      
 
  
*ADD SUBROUTINE
*______________
SR_ADD:
    NOP *DO STUFF HERE
    RTS 
   
   
*ADDA SUBROUTINE
*______________
SR_ADDA:
    NOP *DO STUFF HERE
    RTS   
    
    
*SUB SUBROUTINE
*______________
SR_SUB:
    NOP *DO STUFF HERE
    RTS  


*SUBQ SUBROUTINE
*______________
SR_SUBQ:
    NOP *DO STUFF HERE
    RTS  


*CMP SUBROUTINE
*______________
SR_CMP:
    NOP *DO STUFF HERE
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
         ANDI.B #$C0,D2
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
         ANDI.B  #$38,D3 * BITMASK TO FIND EA MODE
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
        MOVE.L  #$434D5049,(A1) *MISSING TAB BECAUSE OVER 32 BITS!
        MOVEA.L A1,A2
        ADDA.W  #4,A2
        MOVE.B  #$0,(A2)
        TRAP    #15
        MOVE.L  D2,A4
        MOVEA.L CMPI_SIZE(A4),A4
        JSR     (A4)
        
        RTS    


*MULS SUBROUTINE
*______________
SR_MULS:
    NOP *DO STUFF HERE
    RTS    


*DIVS SUBROUTINE
*______________
SR_DIVS:
    NOP *DO STUFF HERE
    RTS  


*LEA SUBROUTINE
*______________
SR_LEA:
    NOP *DO STUFF HERE
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
    
    *BRANCH FOR <EA> MODE AND OUTPUT ARGUMENTS
        *No branching is necessary as there are no arguments for NOP
    
    *MOVE ADDRESS POINTER TO NEXT OPWORD
    ADDA.W  #2,A5
    
    *RTS
    RTS  
    
    
*OR SUBROUTINE
*______________
SR_OR:
    NOP *DO STUFF HERE
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
         ANDI.B  #$38,D3 * BITMASK TO FIND EA MODE
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
        
       **********
       * GET EA TO PRINT OUT
       **********

    RTS 
    
 
*EOR SUBROUTINE
*______________
SR_EOR:
    NOP *DO STUFF HERE
    RTS 

  
*LSR SUBROUTINE
*______________
SR_LSR:
    NOP *DO STUFF HERE
    RTS     

*LSL SUBROUTINE
*______________
SR_LSL:
    NOP *DO STUFF HERE
    RTS 


*ASR SUBROUTINE
*______________
SR_ASR:
    NOP *DO STUFF HERE
    RTS 
    

*ASL SUBROUTINE
*______________
SR_ASL:
    NOP *DO STUFF HERE
    RTS 


*ROL SUBROUTINE
*______________
SR_ROL:
    NOP *DO STUFF HERE
    RTS     
    
    
*ROR SUBROUTINE
*______________
SR_ROR:
    NOP *DO STUFF HERE
    RTS 
  
  
*BCS SUBROUTINE
*______________
SR_BCS:
    NOP *DO STUFF HERE
    RTS 
    

*BGE SUBROUTINE
*______________
SR_BGE:
    NOP *DO STUFF HERE
    RTS     
    
    
*BLT SUBROUTINE
*______________
SR_BLT:
    NOP *DO STUFF HERE
    RTS     
    
    
*BVC SUBROUTINE
*______________
SR_BVC:
    NOP *DO STUFF HERE
    RTS 
  
  
*BCLR SUBROUTINE
*______________
SR_BCLR:
    NOP *DO STUFF HERE
    RTS     
    
    
*BRA SUBROUTINE
*______________
SR_BRA:
    NOP *DO STUFF HERE
    RTS    
    
    
*JSR SUBROUTINE
*______________
SR_JSR:
    NOP *DO STUFF HERE
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


EA_DATA:
    RTS
EA_ADDR:
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
CR       EQU    $0D
LF       EQU    $0A
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


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
