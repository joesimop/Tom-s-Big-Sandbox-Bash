*-----------------------------------------------------------
* Title      :  Helpers
* Written by :  Joe Simopoulos
* Date       :  5/31/2023
* Description:  Contains helper, debug, and commonly used
*               functions
*-----------------------------------------------------------

*Functions

*Gets window dimensions and stores them in (technically) global variables
*No local variables or arguments
*Overwrites d0 and d1
GetWindowDimensions:
    
    *Get window dimensions
    move.l  #0, d1
    move.b  #GET_WINDOW_DIMENSIONS_TRAP, d0
    TRAP    #15
    
    *Move dimensions into variables
    move.w  d1, WINDOW_HEIGHT
    swap    d1
    move.w  d1, WINDOW_WIDTH
    
    rts

*Draws Debug Grid
*No local variables or arguments
DrawGrid:

    movem.l ALL_DATA_REG_X6, -(sp)
    
    *Set pen color to white
    move.l  #WHITE, d1
    move.b  #SET_PEN_COLOR, d0
    TRAP    #15
    
    *Initialize X Loop
    move.b #DRAW_LINE, d0
    
    move.w  WINDOW_WIDTH, d7
    clr.l   d2
    move.w  WINDOW_HEIGHT, d4
    clr.l   d1
    
    DRAW_X_GRID:
        
        addi.l  #TILE_SIZE, d1
        move.l  d1, d3
        
        TRAP    #15
        
        cmp.l   d1, d7
        bgt     DRAW_X_GRID 


    *Initialize Y Loop
    move.w  WINDOW_HEIGHT, d7
    clr.l   d2
    move.w  WINDOW_WIDTH, d3
    clr.l   d1
    
    DRAW_Y_GRID:
        
        addi.l  #TILE_SIZE, d2
        move.l  d2, d4
        
        TRAP    #15
        
        cmp.l   d2, d7
        bgt     DRAW_Y_GRID
        
    movem.l (sp)+, ALL_DATA_REG_X6
    rts


*Prints a value in d1, then a CR
*Takes one argument in d1
*Overwrites d0, d1
PrintNumber:
    
    move.b  #PRINT_NUM, d0
    TRAP    #15
    move.b  #PRINT_ASCII, d0
    move.b  #CR, d1
    TRAP    #15
    
    rts
    

*Takes in a tile value in d2 and converts it to FP
*d2: Coordinate in tile Space
TileToFpSpace:

    mulu    #TILE_SIZE, d2  ;Pixel Space
    asl.l   #FP_SPACE,  d2  ;Fixed Point Space
    
    rts
    
*Gets Delta time and stores into d6
*Overwrites d1, d2
GetDeltaTime:
    
    move.l  #DELTA_TIME_TRAP, d0
    TRAP    #15
    
    *Save current time
    move.l  d1, d2
    
    *Sub Prev time from current time.
    sub.l   PREV_TIME, d1
    
    *Move current time into prevtime
    move.l  d2, PREV_TIME
    
    *Save dt into d6
    move.l  d1, d6
    
    rts

*Trap calls to set pen color to black
*Overwrites d0, d1
SetPenColorToBlack:

    move.l  #BLACK, d1
    move.b  #SET_PEN_COLOR, d0
    TRAP    #15
    
    rts
    
*Data
WINDOW_WIDTH    ds.w    1
WINDOW_HEIGHT   ds.w    1
PREV_TIME       dc.l    0





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
