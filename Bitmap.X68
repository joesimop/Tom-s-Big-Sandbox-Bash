*-----------------------------------------------------------
* Title      : Bitmap Subroutine
* Written by : Joseph Simopoulos
* Date       :
* Description: Draws a 32-bit bitmap to the screen.
* The arguments for the Draw Bitmap subroutine are:
*   - Pointer to .bmp file (NOT a pointer to the pixel data)
*   - Top, Left corner (x,y) of the bitmap chunk you want to display
*   - Width and Height of the bitmap chunk you want to display
*   - Top, Left corner (x,y) on the output screen to display your chunk
*-----------------------------------------------------------

*Changed registers by DRAW_BMP call
DRAW_BMP_USED_REGISTERS     REG d0-d2/a0-a1

*BMP Header Offsets
PIXEL_DATA_LOCATION_OFFSET  EQU $0A ;4 Bytes
BMP_WIDTH_OFFSET            EQU $12 ;4 Bytes
BMP_HEIGHT_OFFSET           EQU $16 ;4 Bytes
BMP_BIT_MODE_OFFSET         EQU $1C ;2 Bytes

*Constants
BIT_MODE_24                 EQU $1800
BIT_MODE_32                 EQU $2000

*Graphics Trap Codes
DRAW_PIXEL_CODE             EQU 82
SET_PEN_COLOR_CODE          EQU 80

*Local Variable offsets
LOCAL1                      EQU 0
LOCAL2                      EQU 4
LOCAL3                      EQU 8
LOCAL4                      EQU 12

*Argument offsets
BMP_ARG1                      EQU 4
BMP_ARG2                      EQU 8
BMP_ARG3                      EQU 12
BMP_ARG4                      EQU 16
BMP_ARG5                      EQU 20
BMP_ARG6                      EQU 24
ARG7                      EQU 28
ARG8                      EQU 32



*Arguments with associated registers or stack offsets from RA
*Address Pointer: a0 
*Y start in bmp:                  BMP_ARG6
*X start in bmp:                  BMP_ARG5 
*Height to draw:                  BMP_ARG4
*Width to draw:                   BMP_ARG3
*Y draw position in screen space: BMP_ARG2
*X draw position in screen space: BMP_ARG1
*Argument Count: 6

*Local Variables with associated offset:
*Max Height:              LOCAL1
*Max Width:               LOCAL2
*Address Pointer Updater: LOCAL3
*Local Variable Count:  2
DrawBitmap:

*Initialization
    
    ;movem DRAW_BMP_USED_REGISTERS, REGISTER_STORE


    *Calculate first drawing position
    move.l  BMP_ARG2(sp), d2        ;Y pos
    add.l   BMP_ARG4(sp), d2        
    move.l  BMP_ARG1(sp), d3        ;X pos
    
    *Calculate X Bound
    move.l  BMP_ARG3(sp), d4        ;X Bound
    add.l   BMP_ARG1(sp), d4
    
    *Counter
    move.l  BMP_ARG4(sp), d5
    sub.l   #1, d5
    

    *Intialize Local Variables
    sub.l  #12, sp

    *Move height into local variables
    move.l BMP_HEIGHT_OFFSET(a0), d7
    jsr LTOB_LW
    move.l d7, LOCAL1(sp)
    
    *Move width into local variable
    move.l BMP_WIDTH_OFFSET(a0), d7
    jsr LTOB_LW
    move.l d7, LOCAL2(sp)
    
    
    *Gets pixel location offset and stores into a2
    move.l  a0, a2
    move.l  PIXEL_DATA_LOCATION_OFFSET(a2), d7
    jsr LTOB_LW
    add.l   d7, a2
    
    
DRAW_BMP_32:

    *Offsets the address pointer so it begins drawing at correct address (because we are drawing "up")
    move.l  LOCAL1(sp), d7      ;Get height of bmp
    sub.l   (BMP_ARG4+12)(sp),  d7  ;Subtract draw height          
    mulu    (LOCAL2+2)(sp), d7  ;Multiply by width need the plus 2 to offset to word
    lsl.l   #2, d7              ;Long word space
    add.l   d7, a2
    
   *Offsets bitmap chunk
    move.l (BMP_ARG5+12)(sp), d7
    lsl.l   #2, d7
    add.l   d7, a2
    
    *Y coord
    move.l (BMP_ARG6+12)(sp), d7
    mulu    (LOCAL2+2)(sp), d7
    lsl.l   #2, d7
    sub.l   d7, a2
    
    *Address pointer incrementer
    move.l LOCAL2(sp), d7    ;Get Width of bmp into d5
    sub.l  (BMP_ARG3+12)(sp), d7     ;subtract drawing width from total width
    lsl.l  #2, d7            ;Long word space
    move.l d7, LOCAL3(sp)    
    bra.s   LOOP_32

UPDATE_Y_32:

     subi.l  #1, d2
     add.l   LOCAL3(sp), a2
    

LOOP_32:

    *GET PEN COLOR
    move.l  (a2)+, d1
    lsr.l   #8, d1
    
    
    *SET PEN COLOR
    move.b  #SET_PEN_COLOR_CODE, d0
    TRAP    #15
    
    *DRAW PIXEL
    move.w  d3, d1
    move.b  #DRAW_PIXEL_CODE, d0
    TRAP    #15
    
    addi    #1, d3
    cmp.l   d4, d3
    bne     LOOP_32

*NEW_LINE:
    
    move.l  (BMP_ARG1+12)(sp), d3
    dbra    d5, UPDATE_Y_32

*DONE:

    add.l   #12, sp
    rts


*Changes from little to big endianess
*Expects values to be in d7, will return value in d7 
LTOB_LW:
    
    rol.w #8, d7
    swap  d7
    rol.w #8, d7
    
    rts

REGISTER_STORE  ds.l    15

GAME_BG_BMP         INCBIN "Game-BG.bmp"
TITLE_SCREEN_BMP    INCBIN "TITLE_SCREEN.bmp"
PRE_END_SCREEN_BMP  INCBIN "PreEndScreen.bmp"
END_SCREEN_BMP      INCBIN "EndScreen.bmp"

    END    START        ; last line of source












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
