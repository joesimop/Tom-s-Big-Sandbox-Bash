*-----------------------------------------------------------
* Title      :  Block
* Written by :  Joe Simopoulos
* Date       :  6/15/2023
* Description:  Contains the logic and helper functions for 
*               performing block operations.
*-----------------------------------------------------------

*Macros
BLOCK_LOOP_REGS    REG d7/a3-a5

*Functions

*Takes a function pointer and excecutes that function for each tile in the block
*a5: Block Function Pointer, d1: X Tile Coord, d2: Y Tile Coord
CallFunctionPerTileInBlock:

    *Make room for locals, the X and Y positions
    sub.l   #4, sp
    move.w  d1, (sp)
    move.w  d2, 2(sp)
    
    
    jsr     GetBlockFromTable
    
    *At this point, the block length is in d7 and the block pointer is in a3
    sub.b   #1, d7          ;Sub 1 for dbra
    
    BLOCK_FUNCTION_LOOP:
    
        *Setup block origin and type
        move.w (sp), d1
        move.w 2(sp), d2
        moveq  #0, d0

        add.w    (a3), d1              ;Add X Offset
        add.w   2(a3), d2              ;Add Y Offset
        move.w  4(a3), d0              ;Get block type
        
        *Protect Loop Variables
        movem.w BLOCK_LOOP_REGS, -(sp) 
        
        *Excectue Given Function
        jsr     (a5)
        
        *Restore Counter
        movem.w (sp)+, BLOCK_LOOP_REGS
        
        ;Next Offset and loop
        add.l   #8, a3
        dbra    d7, BLOCK_FUNCTION_LOOP
        
        
   add.l #4, sp
   rts
     
        

*Returns the pointer to the Block Id value in d0, in a3
*Stores block length in d7 as well.
*d0: Block Value
*Overwrites d0, d3, d7, a3
GetBlockFromTable:

    ;Align to draw specs table
    lea     BLOCK_DRAW_SPECS, a3
    lsl.w   #2, d0                  ;4 byte space 
    add.w   d0, a3
    
    
    clr.l   d3
    move.w  (a3), d3                ;Load BLOCK_DRAW_TABLE offset into d3
    lsl.l   #1, d3                  ;Word space
    clr.l   d7
    move.w  2(a3), d7               ;Load block length into d7
    
    lea     BLOCK_DRAW_TABLE, a3
    add.l   d3, a3
    
    jsr     GetBlockRotation

    rts
    
*Takes in the size of the block minus 1 in d7 and calculates
*the memory offset to get the block rotation
*d7: Block Size, a3: Start of the Selected Block's Data
GetBlockRotation:

    moveq   #0, d0
    move.b  SELECTED_BLOCK_ROTATION, d0
    
    move.l  d7, d1                      ;1x --> Tile space
    lsl.l   #2, d1                      ;4x --> 4 bytes per tile entry
    
    mulu    d1, d0                      ;Get Rotaion offset
    lsl.l   #1, d0                      ;Word Space
    
    add.l   d0, a3                      ;Byte offset to rotation
    
    rts

*Takes in a Block ID in d1 and returns the number of tiles in that block in d2
*d0: Block ID
*Overwrites d1,a1
GetTileCountInBlock:

    ;Align to draw specs table
    lea     BLOCK_DRAW_SPECS, a1
    lsl.w   #2, d1                  ;4 byte space 
    add.w   d1, a1
    
    move.w  2(a1), d7               ;Load block length into d2
    
    rts

*Data

BLOCK_DRAW_SPECS:
    
    *The Contents of this table is a block's:
    *Memory Offset from BLOCK_DRAW_TABLE
    *The number of tile in the block
    
    *L block:
    dc.w    0,4
    *Zig-Zag Block:
    dc.w    64, 5
    *Long Block
    dc.w    144, 4
    *T  Block
    dc.w    208, 4
    *Square Block
    dc.w    272, 4
    

BLOCK_DRAW_TABLE:

    *Contains block offsets from center and block type.
    
    *L block ----------------------------------------------------------------------------------------------
    
    *Rotation 0
    dc.w     0,-1,SAND, 24
    dc.w     0, 0,SAND, 10
    dc.w     0, 1,SAND, 0
    dc.w    -1,-1,STONE,20
    
    *Rotation 1
    dc.w   -1, 0,SAND,  0
    dc.w    0, 0,SAND,  10
    dc.w    1, 0,SAND,  14
    dc.w    1,-1,STONE, 18
    
    *Rotation 2
    dc.w    0, 1,SAND,  0
    dc.w    0, 0,SAND,  10
    dc.w    0,-1,SAND,  20
    dc.w    1, 1,STONE, 4
    
    *Rotation 3
    dc.w     1, 0,SAND,  18
    dc.w     0, 0,SAND,  14
    dc.w    -1, 0,SAND,  10
    dc.w    -1, 1,STONE, 0
    
    *Zig Zag Block ----------------------------------------------------------------------------------------------
    
    *Rotation 0
    dc.w    -1, 0, SAND,  10
    dc.w    -1, 1, STONE, 0
    dc.w     0, 1, SAND,  4
    dc.w     1, 1, SAND,  8
    dc.w     1, 0, STONE, 14
    
    *Rotation 1
    dc.w     0,-1, SAND,  24
    dc.w    -1,-1, STONE, 20
    dc.w    -1, 0, SAND,  10
    dc.w    -1, 1, SAND,  0
    dc.w     0, 1, STONE, 4
    
    *Rotation 2
    dc.w     1, 0, SAND,  4
    dc.w     1,-1, STONE, 18
    dc.w     0,-1, SAND,  14
    dc.w    -1,-1, SAND,  10
    dc.w    -1, 0, STONE, 0
    
    *Rotation 3
    dc.w     0, 1, SAND,  0
    dc.w     1, 1, STONE, 4
    dc.w     1, 0, SAND,  10
    dc.w     1,-1, SAND,  24
    dc.w     0,-1, STONE, 20
    
    *Long Block ----------------------------------------------------------------------------------------------
    
    *Rotation 0
    dc.w     0,  1, WATER,  0
    dc.w     0,  0, WATER,  4
    dc.w     0, -1, WATER,  8
    dc.w     0, -2, WATER,  12
    
    *Rotation 1
    dc.w    -2,  0, WATER,  0
    dc.w    -1,  0, WATER,  4
    dc.w     0,  0, WATER,  8
    dc.w     1,  0, WATER,  12
    
    *Rotation 2
    dc.w     0,  1, WATER,  0
    dc.w     0,  0, WATER,  4
    dc.w     0, -1, WATER,  8
    dc.w     0, -2, WATER,  12
    
    *Rotation 3
    dc.w    -2,  0, WATER,  0
    dc.w    -1,  0, WATER,  4
    dc.w     0,  0, WATER,  8
    dc.w     1,  0, WATER,  12
    
    *T Block ----------------------------------------------------------------------------------------------
    
    *Rotation 0
    dc.w     0,  0, STONE,  10
    dc.w    -1,  1, SAND,   0
    dc.w     0,  1, SAND,   4
    dc.w     1,  1, SAND,   8
    
    *Rotation 1
    dc.w     0,  0, STONE,  14
    dc.w    -1, -1, SAND,   20
    dc.w    -1,  0, SAND,   10
    dc.w    -1,  1, SAND,   0
    
    *Rotation 2
    dc.w     0,  0, STONE,  0
    dc.w     1, -1, SAND,   18
    dc.w     0, -1, SAND,   14
    dc.w    -1, -1, SAND,   10
    
    *Rotation 2
    dc.w     0,  0, STONE,  10
    dc.w     1,  1, SAND,   0
    dc.w     1,  0, SAND,   14
    dc.w     1, -1, SAND,   20

    *Square Block ----------------------------------------------------------------------------------------------
    
    *Rotation 0
    dc.w    -1,  0, STONE,  10
    dc.w     0,  0, STONE,  14
    dc.w    -1,  1, STONE,   0
    dc.w     0,  1, STONE,   4
    
    *Rotation 1
    dc.w    -1,  -1, STONE,  10
    dc.w     0,  -1, STONE,  14
    dc.w    -1,   0, STONE,   0
    dc.w     0,   0, STONE,   4
    
    *Rotation 2
    dc.w     0, -1, STONE,  10
    dc.w     1, -1, STONE,  14
    dc.w     0,  0, STONE,   0
    dc.w     1,  0, STONE,   4
    
    *Rotation 3
    dc.w     0,  0, STONE,  10
    dc.w     1,  0, STONE,  14
    dc.w     0,  1, STONE,   0
    dc.w     1,  1, STONE,   4













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
