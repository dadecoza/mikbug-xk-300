        NAM    MIKBUG
*      REV 009
*      COPYRIGHT 1974 BY MOTOROLA INC
*
*      MIKBUG (TM)
*
*      L  LOAD
*      G  GO TO TARGET PROGRAM
*      M  MEMORY CHANGE
*      F  PRINT/PUNCH DUMP
*      R  DISPLAY CONTENTS OF TARGET STACK
*            CC   B   A   X   P   S
PORTA   EQU   $E480
DDRA    EQU   $E481
PORTB   EQU   $E482
DDRB    EQU   $E483
*       OPT    MEMORY
        ORG    $E800
        
        JMP    START     E800
        JMP    OUTEEE    E803
        JMP    INEEE     E806
        JMP    PDATA1    E809
        JMP    OUTHR     E80C
        JMP    OUTHL     E80F
        JMP    OUT2HS    E812


LOAD    EQU    *
        LDAA   #@21
        BSR    OUTCH     OUTPUT CHAR

LOAD3   BSR    INCH
        CMPA   #'S
        BNE    LOAD3     1ST CHAR NOT (S)
        BSR    INCH      READ CHAR
        CMPA   #'9
        BEQ    LOAD21
        CMPA   #'1
        BNE    LOAD3     2ND CHAR NOT (1)
        CLR    CKSM      ZERO CHECKSUM
        BSR    BYTE      READ BYTE
        SUBA   #2
        STAA   BYTECT    BYTE COUNT
* BUILD ADDRESS
        BSR    BADDR
* STORE DATA
LOAD11  BSR    BYTE

        DEC    BYTECT
        BEQ    LOAD15    ZERO BYTE COUNT
        STAA   0,X       STORE DATA
        INX
        BRA    LOAD11

LOAD15  INC    CKSM
        BEQ    LOAD3
LOAD19  LDAA   #'?       PRINT QUESTION MARK
        BSR    OUTCH
LOAD21  EQU    *
C1      JMP    CONTRL

* BUILD ADDRESS
BADDR   BSR    BYTE      READ 2 FRAMES
        STAA   XHI
        BSR    BYTE
        STAA   XLOW
        LDX    XHI       (X) ADDRESS WE BUILT
        RTS

*INPUT BYTE (TWO FRAMES)
BYTE    BSR    INHEX     GET HEX CHAR
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        BSR    INHEX
        ABA
        TAB
        ADDB   CKSM
        STAB   CKSM
        RTS

OUTHL   LSRA            OUT HEX LEFT BCD DIGIT
        LSRA
        LSRA
        LSRA

OUTHR   ANDA   #$F       OUT HEX RIGHT BCD DIGIT
        ADDA   #$30
        CMPA   #$39
        BLS    OUTCH
        ADDA   #$7

* OUTPUT ONE CHAR
OUTCH   JMP    OUTEEE
INCH    JMP    INEEE

* PRINT DATA POINTED AT BY X-REG
PDATA2  BSR    OUTCH
        INX
PDATA1  LDAA   0,X
        CMPA   #4
        BNE    PDATA2
        RTS              STOP ON EOT

* CHANGE MENORY (M AAAA DD NN)
CHANGE  BSR    BADDR     BUILD ADDRESS
CHA51   LDX    #MCL
        BSR    PDATA1    C/R L/F
        LDX    #XHI
        BSR    OUT4HS    PRINT ADDRESS
        LDX    XHI
        BSR    OUT2HS    PRINT DATA (OLD)
        STX    XHI       SAYE DATA ADDRESS
        BSR    INCH      INPUT ONE CHAR
        CMPA   #$20
        BNE    CHA51     NOT SPACE
        BSR    BYTE      INPUT NEW DATA
        DEX
        STAA   0,X       CHANGE MEMORY
        CMPA   0,X
        BEQ    CHA51     DID CHANGE
        BRA    LOAD19    NOT CHANGED

* INPUT HEX CHAR
INHEX   BSR    INCH
        SUBA   #$30
        BMI    C1        NOT HEX
        CMPA   #$09
        BLE    IN1HG
        CMPA   #$11
        BMI    C1        NOT HEX
        CMPA   #$16
        BGT    C1        NOT HEX
        SUBA   #7
IN1HG   RTS

OUT2H   LDAA   0,X       OUTPUT 2 HEX CHAR
OUT2HA  BSR    OUTHL     OUT LEFT HEX CHAR
        LDAA   0,X
        INX
        BRA    OUTHR     OUTPUT RIGHT HEX CHAR AND R

OUT4HS  BSR    OUT2H     OUTPUT 4 HEX CHAR + SPACE
OUT2HS  BSR    OUT2H     OUTPUT 2 HEX CHAR + SPACE

OUTS    LDAA   #$20      SPACE
        BRA    OUTCH     (BSR & RTS)

* ENTER POWER  ON SEQUENCE
START   EQU    *
        LDS    #STACK
        STS    SP        INZ TARGET'S STACK PNTR
* INZ PIA
        JSR PIAINZ
CONTRL  LDS    #STACK    SET CONTRL STACK POINTER
        LDX    #MCLOFF

        BSR    PDATA1    PRINT DATA STRING

        BSR    INCH      READ CHARACTER
        TAB
        BSR    OUTS      PRINT SPACE
        CMPB   #'L
        BNE    *+5
        JMP    LOAD
        CMPB   #'M
        BEQ    CHANGE
        CMPB   #'R
        BEQ    PRINT     STACK
        CMPB   #'P
        BEQ    PUNCH     PRINT/PUNCH
        CMPB   #'G
        BNE    CONTRL
        LDS    SP        RESTORE PGM'S STACK PTR
        RTI              GO

* ENTER FROM SOFTWARE INTERRUPT
SFE     EQU    *
        STS    SP        SAVE TARGET'S STACK POINTER
* DECREMENT P-COUNTER
        TSX
        TST    6,X
        BNE    *+4
        DEC    5,X
        DEC    6,X

* PRINT CONTENTS OF STACK
PRINT   LDX    SP
        INX
        BSR    OUT2HS    CONDITION CODES
        BSR    OUT2HS    ACC-B
        BSR    OUT2HS    ACC-A
        BSR    OUT4HS    X-REG
        BSR    OUT4HS    P-COUNTER
        LDX    #SP
        BSR    OUT4HS    STACK POINTER
C2      BRA    CONTRL

* PUNCH DUMP
* PUNCH FROM BEGINNING ADDRESS (BEGA) THRU ENDING
* ADDRESS (ENDA)
*
MTAPE1  FCB    $D,$A,0,0,0,0,'S,'1,4 PUNCH FORMAT


PUNCH   EQU    *

        LDAA   #$12      TURN TTY PUNCH ON
        JSR    OUTCH     OUT CHAR  

        LDX    BEGA
        STX    TW        TEMP BEGINNING ADDRESS
PUN11   LDAA   ENDA+1
        SUBA   TW+1
        LDAB   ENDA
        SBCB   TW
        BNE    PUN22
        CMPA   #16
        BCS    PUN23
PUN22   LDAA   #15
PUN23   ADDA   #4
        STAA   MCONT     FRAME COUNT THIS RECORD
        SUBA   #3
        STAA   TEMP      BYTE COUNT THIS RECORD
* PUNCH C/R,L/F,NULL,S,1
        LDX    #MTAPE1
        JSR    PDATA1
        CLRB             ZERO CHECKSUM
* PUNCH FRAME COUNT
        LDX    #MCONT
        BSR    PUNT2     PUNCH 2 HEX CHAR
* PUNCH ADDRESS
        LDX    #TW
        BSR    PUNT2
        BSR    PUNT2
* PUNCH DATA
        LDX    TW
PUN32   BSR    PUNT2     PUNCH ONE BYTE (2 FRAMES)
        DEC    TEMP      DEC BYTE COUNT
        BNE    PUN32
        STX    TW
        COMB
        PSHB
        TSX
        BSR    PUNT2     PUNCH CHECKSUM
        PULB             RESTORE STACK
        LDX    TW
        DEX
        CPX    ENDA
        BNE    PUN11
        BRA    C2        JMP TO CONTRL

* PUNCH 2 HEX CHAR UPDATE CHECKSUM
PUNT2   ADDB   0,X       UPDATE CHECKSUM
        JMP    OUT2H     OUTPUT TWO HEX CHAR AND RTS


MCLOFF  FCB    $13       READER OFF
MCL     FCB    $D,$A,$14,0,0,0,'*,4 C/R,L/F,PUNCH


INEEE   PSHB
        STX   XTEMP
INWAIT
        LDAA   PORTB
        ANDA   #$01      CHECK PB0 FOR START BIT
        BNE    INWAIT    NO START BIT
        BSR    HDEL      WAIT HALF BIT TIME
        LDAB   #8        8 BITS TO RECEIVE
        CLRA             CLEAR A FOR RECEIVED CHARACTER
RCVBIT  BSR    DEL       WAIT FULL BIT TIME
        PSHA             SAVE PARTIAL CHARACTER
        LDAA   PORTB
        ANDA   #$01      GET BIT FROM PB0
        PULA             RESTORE PARTIAL CHARACTER
        BEQ    IN0       BIT IS 0        
        SEC              SET CARRY FOR ROR
        BRA    SHFTI
IN0     CLC              CLEAR CARRY FOR ROR
SHFTI   RORA             SHIFT BIT INTO MSB OF A
        DECB
        BNE    RCVBIT    GET NEXT BIT
        BSR    DEL       WAIT FOR STOP BIT
        SEC              SET CARRY = SUCCESS
        BRA    IOUT2
* END INEEE
OUTEEE  PSHB
        STX   XTEMP
        STAA  TMPC
        LDAA  #$00       START BIT (0)
        STAA  PORTA
        BSR   DEL
        LDAB  #8         8 DATA BITS
OUT1    LDAA  TMPC
        ANDA  #$01
        BEQ   OUT0
        LDAA  #$80
        STAA  PORTA
        BSR   DEL
        BRA   SHFTO
OUT0    LDAA  #$00
        STAA  PORTA
        BSR   DEL
SHFTO   LDAA  TMPC
        LSRA
        STAA  TMPC
        DECB
        BNE   OUT1
        LDAA  #$80       STOP BIT (1)
        STAA  PORTA
IOUT2   BSR   DEL
        LDX   XTEMP
        PULB
        RTS

DEL     LDX   #370       300 BAUD @ 894.886 KHZ CLOCK
DE      DEX
        BNE   DE
        RTS

HDEL    LDX   #185       HALF DELAY
HDE     DEX
        BNE   HDE
        RTS

PIAINZ  CLRA
        STAA   DDRA      ACCESS DDR
        LDAA   #$80      PA7 OUTPUT
        STAA   PORTA
        LDAA   #$04      SWITCH TO DATA REGISTER
        STAA   DDRA
        CLRA
        STAA   DDRB      ACCESS DDR B (ALL INPUTS)
        STAA   PORTB     DDR = $00 (ALL INPUTS)
        LDAA   #$04      SWITCH TO DATA REGISTER
        STAA   DDRB
        LDAA   #$80      IDLE HIGH ON PA7 (TX)
        STAA   PORTA
        RTS

        ORG    $0000     USER RAM INSIDE MC6802
BEGA    RMB    2         BEGINNING ADDR PRINT/PUNCH
ENDA    RMB    2         ENDING ADDR PRINT/PUNCH
SP      RMB    1         S-HIGH
        RMB    1         S-LOW
CKSM    RMB    1         CHECKSUM

BYTECT  RMB    1         BYTE COUNT
XHI     RMB    1         XREG HIGH
XLOW    RMB    1         XREG LOW
TEMP    RMB    1         CHAR COUNT (INADD)
TMPC    RMB    1         TEMP CHAR
TW      RMB    2         TEMP/
MCONT   RMB    1         TEMP
XTEMP   RMB    2         X-REG TEMP STORAGE
        RMB    49
STACK   RMB    1         STACK POINTER
        END    