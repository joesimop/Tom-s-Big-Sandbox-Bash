*-----------------------------------------------------------
* Title      :  Bounding Box
* Written by :  Joe Simopoulos
* Date       :  6/6/2023
* Description:  Contains a bounding box check function and 
*               macros for certain bouding boxes.
*-----------------------------------------------------------

*Note: I did it this way to save cycles and registers.
*Not the ideal way of doing it.
*8 bytes for each table entry (4 borders * 2 bytes/border)

*Macros
MAP_BOUNDING_BOX:                 EQU 0
START_BOUNDING_BOX:               EQU 8
RESET_LEVEL_BOUNDING_BOX:         EQU 16
L_BLOCK_INDICATOR_BOX:            EQU 24
ZIG_ZAG_BLOCK_INDICATOR_BOX:      EQU 32
LONG_BLOCK_INDICATOR_BOX:         EQU 40
T_BLOCK_INDICATOR_BOX:            EQU 48
SQUARE_BLOCK_INDICATOR_BOX:       EQU 56
BLOCK_INDICATOR_WRAPPING_BOX:     EQU 64      

*Functions

*Checks given bounding box in d0.
*d0: Bounding Box Table Index
*Returns either 0 or 1 in d7, overwrites a6
CheckBoundingBox:

    *Align table
    lea BOUNDING_BOXES, a6
    add.l   d0, a6
    
    move.w  TILE_X, d1
    move.w  TILE_Y, d2
    
    *Left Bound
    cmp.w  (a6), d1
    blt     NOT_IN_BOX
    
    *Top Bound
    cmp.w   2(a6), d2
    blt     NOT_IN_BOX
    
    *Right Bound
    cmp.w   4(a6), d1
    bgt     NOT_IN_BOX
    
    *Bottom Bound
    cmp.w   6(a6), d2
    bgt     NOT_IN_BOX
    
    moveq   #1, d7
    rts
    
NOT_IN_BOX:

    moveq   #0, d7
    rts

*Data

*FORMATTED: LEFT BOUND, TOP BOUND, RIGHT BOUND, BOTTOM BOUND (inclusive)
BOUNDING_BOXES: dc.w  18,  2, 29, 16      ;Game Screen
                dc.w   1, 19, 13, 22      ;Start Button
                dc.w  13, 22, 18, 24      ;Reset Level Button
                dc.w   3, 19,  4, 20      ;L Block Indicator Box
                dc.w   9, 19, 10, 20      ;Zig Zag Block Indicator Box
                dc.w  15, 19, 16, 20      ;Long Block Indicator Box
                dc.w  21, 19, 22, 20      ;T Block Indicator Box
                dc.w  27, 19, 28, 20      ;Square Block Indicator Box
                dc.w   0, 19, 31, 20      ;Indicator Wrapping Box









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
