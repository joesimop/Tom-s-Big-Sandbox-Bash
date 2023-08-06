ALL_REG                 REG     D0-D7/A0-A6

GET_TIME_COMMAND        equ     8


InitializeRandomNumber:

        jsr     seedRandomNumber
	clr.l	d5
        jsr     getRandomByteIntoD5
	clr.l	d5
        jsr     getRandomByteIntoD5
	clr.l	d5
        jsr     getRandomByteIntoD5
	clr.l	d5
        jsr     getRandomByteIntoD5
	clr.l	d5
        jsr     getRandomByteIntoD5
	clr.l	d5
        jsr     getRandomByteIntoD5
	clr.l	d5
        
        rts
        


seedRandomNumber
        movem.l ALL_REG,-(sp)           ;; What does this do?
        clr.l   d5
        move.b  #GET_TIME_COMMAND,d0    ;; What if you used the same seed?
        TRAP    #15

        move.l  d1,RANDOMVAL
        movem.l (sp)+,ALL_REG
        rts

getRandomByteIntoD5
        movem.l d0,-(sp)
        movem.l d1,-(sp)
        movem.l d2,-(sp)
        move.l  RANDOMVAL,d0
       	moveq	#$AF-$100,d1
       	moveq	#18,d2
Ninc0	
	add.l	d0,d0
	bcc	Ninc1
	eor.b	d1,d0
Ninc1
	dbf	d2,Ninc0
	
	move.l	d0,RANDOMVAL
	clr.l	d5
	move.b	d0,d5
	
        movem.l (sp)+,d2
        movem.l (sp)+,d1
        movem.l (sp)+,d0
        rts
        

getRandomLongIntoD6
        movem.l ALL_REG,-(sp)
        jsr     getRandomByteIntoD5
        move.b  d5,d4
        jsr     getRandomByteIntoD5
        lsl.l   #8,d4
        move.b  d5,d4
        jsr     getRandomByteIntoD5
        lsl.l   #8,d4
        move.b  d5,d4
        jsr     getRandomByteIntoD5
        lsl.l   #8,d4
        move.b  d5,d4
        move.l  d4,TEMPRANDOMLONG
        movem.l (sp)+,ALL_REG
        move.l  TEMPRANDOMLONG,d5
        rts


RANDOMVAL       ds.l    1
TEMPRANDOMLONG  ds.l    1









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
