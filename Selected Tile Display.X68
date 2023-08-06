*-----------------------------------------------------------
* Title      :  Selected Tile Display
* Written by :  Joe Simopoulos
* Date       :  6/16/2023
* Description:  Updates the indicator of the 
*-----------------------------------------------------------



*Macros
BLOCK_INDICATOR_HEIGHT  EQU 389

*Function
UpdateBlockIndicator:

    moveq   #0, d0
    moveq   #0, d1
    moveq   #0, d2
    moveq   #0, d3
    moveq   #0, d4

    *Inval previous block
    move.b  CURRENTLY_SELECTED_BLOCK, d0
    lsl.l   #2, d0                           ;4 byte space
    lea     BLOCK_INDICATOR_X_POSITIONS, a0
    move.l  (a0, d0), d1
    
    *X Position is now in d1
    move.l  #BLOCK_INDICATOR_HEIGHT, d2      ;Pixel Space
    sub.l   #1, d2                           ;-1 for border
    move.l  #TILE_SIZE+1, d4                 ;+2 for border
    move.l  #TILE_SIZE+2, d5                 ;+2 for border
    jsr     InvalPixels
    
    jsr     DrawBlockIndicator
    
    rts
    
*Draw Block Indicator
DrawBlockIndicator:

    move.l  #BLOCK_INDICATOR_COLOR, d1
    move.b  #SET_FILL_COLOR, d0
    TRAP    #15

    move.b  SELECTED_BLOCK, d0
    move.b  d0, CURRENTLY_SELECTED_BLOCK
    lsl.l   #2, d0                           ;4 byte space
    lea     BLOCK_INDICATOR_X_POSITIONS, a0
    move.l  (a0, d0), d1
    
    move.l  d1, d3
    add.l   #TILE_SIZE, d3
    
    move.l  #BLOCK_INDICATOR_HEIGHT, d2
    move.l  d2, d4
    add.l   #TILE_SIZE, d4
    
    move.b  #DRAW_RECT, d0
    TRAP    #15
    
    rts

*Data
CURRENTLY_SELECTED_BLOCK:   dc.b    0,0

*X Positions in pixel space
BLOCK_INDICATOR_X_POSITIONS:

    dc.l    74, 194, 314, 434, 554

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
