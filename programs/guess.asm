*
*       Classic Number Guessing Game
*       @dadecoza December 2025
*
GETCH   EQU $E806       MIKBUG INEEE
PRINT   EQU $E809       MIKBUG PDATA1
CNTRL   EQU $E8DF       MIKBUG CONTRL
        ORG $E000
        LDAA  #42
        STAA  RND
START   JSR  RAND8
        LDAA RND
        CMPA #100
        BLO  SEED_OK
        SUBA #100
SEED_OK STAA TARGET
        LDX   #PROMPT
        JSR   PRINT
PLAY    LDX   #GUESS    MAIN LOOP
        JSR   PRINT
        JSR   GETCH     READ FIRST DIGIT
        SUBA  #'0'      CONVERT ASCII TO DIGIT
        STAA  TENS
        JSR   GETCH
        CMPA  #$0D      ENTER OR DIGIT?
        BNE   NOTCR
        LDAA  TENS      THIS IS SINGLE DIGIT GUESS MOVE TENS TO ONES
        STAA  ONES
        LDAA  #0
        STAA  TENS
        BRA   CR
NOTCR   SUBA  #'0'      AGAIN CONVERT ASCII TO DIGIT
        STAA  ONES
CR      LDAA  TENS
        ASLA            TENS*2
        STAA  TEMP
        LDAA  TENS
        ASLA
        ASLA
        ASLA            TENS*8
        ADDA  TEMP      TENS*10
        ADDA  ONES      +ONES
        TAB             B NOW HOLDS OUR GUESS
        LDAA  TARGET    AND A HOLDS THE ANSWER
        CBA             COMPARE B WITH A
        BEQ   EQUAL
        BLO   HIGH
        BHI   LOW
HIGH    LDX   #MSGHIGH
        BRA   SHOW
LOW     LDX   #MSGLOW
SHOW    JSR   PRINT
        BRA   PLAY
EQUAL   LDX   #MSGWIN
        JSR   PRINT
        JSR   GETCH
        CMPA  #'Y'
        BEQ   START
END     JMP   CNTRL
RAND8   LDAA RND
        LSRA
        BCC NOFB
        EORA #$B4
NOFB    STAA RND
        RTS
PROMPT  FCB $0A,$0D
        FCC "I'M THINKING OF A NUMBER BETWEEN 0 AND 99."
        FCB $04
GUESS   FCB $0A,$0D
        FCC "GUESS?"
        FCB $04
MSGHIGH FCB $0A,$0D
        FCC "TOO HIGH"
        FCB $04
MSGLOW  FCB $0A,$0D
        FCC "TOO LOW"
        FCB $04
MSGWIN  FCB $0A,$0D
        FCC "WINNER! PLAY AGAIN?"
        FCB $04
TENS    RMB 1
ONES    RMB 1
TEMP    RMB 1
TARGET  RMB 1
RND     RMB 1
        END START
