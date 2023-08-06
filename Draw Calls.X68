    *-----------------------------------------------------------
* Title      :  Draw Calls
* Written by :  Joe Simopoulos
* Date       :  5/31/2023
* Description:  Contains the draw functions and data that
*               the Draw System references.
*-----------------------------------------------------------



*Draws a colored tile to the screen given the arguments
*d0: color, d1: X Tile Coordinate, d2: Y FP_SPACE Coordinate
*Overwrites d0-d4 and a2
DrawEntity:
    
    *Save X Coord
    move.w  d1, d3

    *Convert FP_SPACE to Tile Coord
    asr.l  #FP_SPACE, d2                ;Pixel Space
    
    
    move.l  d0, d1
    move.b  #SET_FILL_COLOR, d0
    TRAP    #15
    
    jsr     SetPenColorToBlack
    
    move.l  d3, d1
    andi.l  #$0000FFFF, d1
    andi.l  #$0000FFFF, d2

    
    *Gets bounds address
    lea     TILE_DRAW_TABLE, a2
    lsl.l   #4, d1              ;4 byte space and 4 bytes per pixel for x coord
    add.l   d1, a2
    
    
    *Setup X Coordinates
    move.l  (a2), d1
    add.l   #8, a2
    move.l  (a2), d3
    
    *Pixel Y Should already be in d2
    *Add box size for lower bound
    move.l  d2, d4
    add.l   #TILE_SIZE, d4
    
    move.b  #DRAW_RECT, d0
    TRAP    #15
    
    rts
    
*Draws a colored tile to tile space given the arguments
*d0: color, d1: X Tile Coordinate, d2: Y Tile Coordinate
*Overwrites d0-d4 and a2
DrawTileInTileSpace:

    move.w  d1, d3
    
    move.l  d0, d1
    move.b  #SET_FILL_COLOR, d0
    TRAP    #15
    
    move.l  d3, d1
    andi.l  #$0000FFFF, d1
    andi.l  #$0000FFFF, d2

    
    *Gets bounds address
    lea     TILE_DRAW_TABLE, a2
    lsl.l   #4, d1              ;4 byte space and 4 bytes per pixel for x coord
    add.l   d1, a2
    
    lsl.l   #5, d2             ;Multiplying by 32, only because 640/20 (width), so hard coded right now (but much faster)
    lsl.l   #4, d2             ;2 shifts per pixel + 2 shifts for 4 byte space
    add.l   d2, a2             

    
    move.l  (a2)+, d1
    move.l  (a2)+, d2
    move.l  (a2)+, d3
    move.l  (a2)+, d4
    
    move.b  #DRAW_RECT, d0
    TRAP    #15
    
    rts
    

*Draws Sand tile.
*d1: X Tile Coordinate, d2 Y FP_SPACE Coordinate
*Overwrites d0-d4, and a2
DrawSandEntity:
    
    move.l #SAND_COLOR, d0
    jsr DrawEntity

    rts
    
*Draws Stone tile.
*d1: X Tile Coordinate, d2 Y FP_SPACE Coordinate
*Overwrites d0-d4, and a2
DrawStoneEntity:
    
    move.l #STONE_COLOR, d0
    jsr DrawEntity

    rts

*Draws Stone tile.
*d1: X Tile Coordinate, d2 Y FP_SPACE Coordinate
*Overwrites d0-d4, and a2    
DrawWaterEntity:

    move.l  #WATER_COLOR, d0
    jsr     DrawEntity
    
    rts
    
*Draws a tile in tile space
*d0: Tile type, d1: Tile X Pos, d2: Tile Y Pos
DrawTileFromEntityId:

    jsr     GetColorFromEntityId
    jsr     DrawTileInTileSpace
    
    rts
    
    
SmartInvalYTileCoord:

    mulu    #TILE_SIZE, d2
    lsl.l   #FP_SPACE, d2
    
*Invals a Tile with the border in mind
*d1: X Tile Pos, d2: Y FP_SPACE Coord
SmartInval:

    *Get the state of the surrouning tiles
    movem.l POS_REGS, -(sp)
    jsr     GetSurroundingEntityStates
    movem.l (sp)+, POS_REGS
    
    
    mulu    #TILE_SIZE, d1      ;Pixel Space
    lsr.l   #FP_SPACE,  d2      ;Pixel Space
    add.l   #1, d1
    sub.l   #1, d2
    
    move.l  #TILE_SIZE-1, d4            ;Assume we won't inval the borders
    move.l  #TILE_SIZE, d5
    
    *Check Right Border
    btst.l  #0, d7  
    bne     INVAL_LEFT_SIDE
    
    add.l   #1, d4                      ;If there isn't an entity, inval border
    
INVAL_LEFT_SIDE

    btst.l  #1, d7
    bne     INVAL_BOTTOM_SIDE
    
    sub.l   #1, d1                      ;If there isn't an entity to the left, inval
    add.l   #1, d4
    
INVAL_BOTTOM_SIDE

    btst.l  #2, d7
    bne    SMART_INVAL_TILE
    
    add.l   #1, d5
    
SMART_INVAL_TILE:
   
    jsr     InvalPixels
    
    rts

*Takes in X Tile Pos, Y Tile Pos
*Draws the background over the removed pixels, but not the ground
*d1: X Tile Pos, d2: Y Tile Pos
InvalTileButNotGround:

    jsr     GetGroundHeight         ;Ground Height now in d5
    move.l  d5, d4                  ;Get into bitmap argument register
    sub.l   #TILE_SIZE, d4          ;This will move the ground to the tile above
                                    ;Helpful for whether to do a normal inval or not
    mulu    #TILE_SIZE, d1          ;Pixel Space
    mulu    #TILE_SIZE, d2          ;Pixel Space
    
    sub.l   d2, d4                  ;Ground Height - Tile Height
    ble     TILE_SUBMERGED          ;If it is negative or zero, the GH is completely above the ground tile, exit.
    
    *Otherwise we know we inval at least a part of the tile
    *If the value is greater than tile size, then we just do a normal inval
    cmp.l   #TILE_SIZE, d4
    blt     GROUND_AWARE_INVAL
    
    *Otherwise, we are invaling a whole tile, so proceed as normal
    
    move.l  #(TILE_SIZE+1), d4  ;For Border
     
     
*If we jump here, d4 already contains the proper inval height.
GROUND_AWARE_INVAL

    move.l  #(TILE_SIZE+1), d5
    sub.l   #1, d2
    jsr     InvalPixels

TILE_SUBMERGED

    rts



*Takes in X Tile Pos, Y Tile Pos
*Draws the background over the removed pixels
*d1: X Tile Pos, d2: Y Tile Pos
InvalTile:
    
    mulu    #TILE_SIZE, d1      ;Pixel Space
    mulu    #TILE_SIZE, d2      ;Pixel Space
    move.l  #(TILE_SIZE+1), d5  ;+1 for border
    move.l  #(TILE_SIZE+1), d4  ;For Border
    sub.l   #1, d2              ;-1 for border
    
    jsr     InvalPixels
    
    rts
    
*Takes in X Pixel Pos, Y Pixel Pos and the height of the inval
*Draws background in designated area
*d1: X Tile Pos, d2: Y Tile Pos, d4:Inval width in pixels, d5: Inval height in pixels
InvalPixels:
    
    lea     GAME_BG_BMP, a0
    sub.l   #28,  sp
    move.l  d1,   BMP_ARG1(sp)
    move.l  d2,   BMP_ARG2(sp)
    move.l  d4,   BMP_ARG3(sp)
    move.l  d5,   BMP_ARG4(sp)
    move.l  d1,   BMP_ARG5(sp)
    move.l  d2,   BMP_ARG6(sp)
    add.l   #4, sp
    jsr     DrawBitmap
    
    add.l   #24, sp
    
    rts

*Draws the loading screen    
DrawLoadingScreen:

    jsr ClearScreen
    
    lea     LOADING_TEXT, a1
    move.w  #10, d1
    move.b  #0, d0
    TRAP    #15
    
    jsr SwapBuffers
    
    rts

    
*Draws a 640 X 480 image with the data pointer stored in a0
*a0: BMP Pointer
DrawBackground:

    sub.l   #28,  sp
    move.l  #0,   BMP_ARG1(sp)
    move.l  #0,   BMP_ARG2(sp)
    move.l  #640, BMP_ARG3(sp)
    move.l  #480, BMP_ARG4(sp)
    move.l  #0,   BMP_ARG5(sp)
    move.l  #0,   BMP_ARG6(sp)
    add.l   #4, sp
    jsr     DrawBitmap
    
    add.l   #24, sp
    rts

*LOCALS FOR COLLLISION REDRAW:
X_COORD             EQU 0
Y_COORD             EQU 4
ENTITY_POINTER      EQU 8
ENTITY_DRAW_POINTER EQU 12


*Checks for below entity below, if there is one, it redraws it,
*if not, we inval. Then we draw the tile above it.
*a0: Current Entity Pointer, a1: Current Draw Pointer
*d1: X Tile Coord, d2: Y FP Coord
*Local Variable Count: 4
RedrawCollision:


    *Set up locals
    sub.l   #16, sp
    move.l  d1, X_COORD(sp)
    move.l  d2, Y_COORD(sp)
    move.l  a0, ENTITY_POINTER(sp)
    move.l  a1, ENTITY_DRAW_POINTER(sp)
    

    *Get Entity Below Resolved Entity
    add.l   #(TILE_SIZE<<FP_SPACE), d2      ;Get entity below current entity
    jsr     GetMapCoordinateValue
    cmp.l   #0, a0
    bne     REDRAW_ENTITY_BELOW             ;If there is an entity below, we want to redraw it
    
   
    *Restore State
    move.l  X_COORD(sp), d1
    move.l  Y_COORD(sp), d2
    
    
    lsr.l   #FP_SPACE,  d2                  ;Pixel Space
    divu    #TILE_SIZE, d2                  ;Tile Space
    add.l   #1, d2                          ;Tile Underneath current tile
    jsr     InvalTile
    
    bra.s    FINISH_COLLISION_DRAW
    
REDRAW_ENTITY_BELOW:

        
    jsr     GetEntityDrawInstance           ;Stores Draw instance in a1
    jsr     GetEntityPos                    ;Get Below Entity's draw pos.
    
    move.l  D_DRAW_FUNCTION(a1), a3         ;Call Below Entity's Draw function
    jsr     (a3)
    
    
    
FINISH_COLLISION_DRAW:

    *Restore State
    move.l  X_COORD(sp), d1
    move.l  Y_COORD(sp), d2
    move.l  ENTITY_DRAW_POINTER(sp), a1
        
    *Draw the Entity in the resolved position
    move.l  D_DRAW_FUNCTION(a1), a3         ;Call Below Entity's Draw function
    jsr     (a3)

    *Unsubscribe the entity
    move.l  ENTITY_DRAW_POINTER(sp), a0    
    jsr     UnsubscribeEntityFromDrawManager
    
    *Sometimes, the collision can draw over Block Indicator, 
    *So just redraw for the sake of polish.
    jsr     DrawBlockIndicator
    
    *Restore to SP to return address
    add.l   #16, sp
    rts
    
*Data
LOADING_TEXT:   dc.b 'Loading...',$FF,0
    

TILE_DRAW_TABLE:
	 dc.l	0,	0,	20,	20
	 dc.l	20,	0,	40,	20
	 dc.l	40,	0,	60,	20
	 dc.l	60,	0,	80,	20
	 dc.l	80,	0,	100,	20
	 dc.l	100,	0,	120,	20
	 dc.l	120,	0,	140,	20
	 dc.l	140,	0,	160,	20
	 dc.l	160,	0,	180,	20
	 dc.l	180,	0,	200,	20
	 dc.l	200,	0,	220,	20
	 dc.l	220,	0,	240,	20
	 dc.l	240,	0,	260,	20
	 dc.l	260,	0,	280,	20
	 dc.l	280,	0,	300,	20
	 dc.l	300,	0,	320,	20
	 dc.l	320,	0,	340,	20
	 dc.l	340,	0,	360,	20
	 dc.l	360,	0,	380,	20
	 dc.l	380,	0,	400,	20
	 dc.l	400,	0,	420,	20
	 dc.l	420,	0,	440,	20
	 dc.l	440,	0,	460,	20
	 dc.l	460,	0,	480,	20
	 dc.l	480,	0,	500,	20
	 dc.l	500,	0,	520,	20
	 dc.l	520,	0,	540,	20
	 dc.l	540,	0,	560,	20
	 dc.l	560,	0,	580,	20
	 dc.l	580,	0,	600,	20
	 dc.l	600,	0,	620,	20
	 dc.l	620,	0,	640,	20
	 dc.l	0,	20,	20,	40
	 dc.l	20,	20,	40,	40
	 dc.l	40,	20,	60,	40
	 dc.l	60,	20,	80,	40
	 dc.l	80,	20,	100,	40
	 dc.l	100,	20,	120,	40
	 dc.l	120,	20,	140,	40
	 dc.l	140,	20,	160,	40
	 dc.l	160,	20,	180,	40
	 dc.l	180,	20,	200,	40
	 dc.l	200,	20,	220,	40
	 dc.l	220,	20,	240,	40
	 dc.l	240,	20,	260,	40
	 dc.l	260,	20,	280,	40
	 dc.l	280,	20,	300,	40
	 dc.l	300,	20,	320,	40
	 dc.l	320,	20,	340,	40
	 dc.l	340,	20,	360,	40
	 dc.l	360,	20,	380,	40
	 dc.l	380,	20,	400,	40
	 dc.l	400,	20,	420,	40
	 dc.l	420,	20,	440,	40
	 dc.l	440,	20,	460,	40
	 dc.l	460,	20,	480,	40
	 dc.l	480,	20,	500,	40
	 dc.l	500,	20,	520,	40
	 dc.l	520,	20,	540,	40
	 dc.l	540,	20,	560,	40
	 dc.l	560,	20,	580,	40
	 dc.l	580,	20,	600,	40
	 dc.l	600,	20,	620,	40
	 dc.l	620,	20,	640,	40
	 dc.l	0,	40,	20,	60
	 dc.l	20,	40,	40,	60
	 dc.l	40,	40,	60,	60
	 dc.l	60,	40,	80,	60
	 dc.l	80,	40,	100,	60
	 dc.l	100,	40,	120,	60
	 dc.l	120,	40,	140,	60
	 dc.l	140,	40,	160,	60
	 dc.l	160,	40,	180,	60
	 dc.l	180,	40,	200,	60
	 dc.l	200,	40,	220,	60
	 dc.l	220,	40,	240,	60
	 dc.l	240,	40,	260,	60
	 dc.l	260,	40,	280,	60
	 dc.l	280,	40,	300,	60
	 dc.l	300,	40,	320,	60
	 dc.l	320,	40,	340,	60
	 dc.l	340,	40,	360,	60
	 dc.l	360,	40,	380,	60
	 dc.l	380,	40,	400,	60
	 dc.l	400,	40,	420,	60
	 dc.l	420,	40,	440,	60
	 dc.l	440,	40,	460,	60
	 dc.l	460,	40,	480,	60
	 dc.l	480,	40,	500,	60
	 dc.l	500,	40,	520,	60
	 dc.l	520,	40,	540,	60
	 dc.l	540,	40,	560,	60
	 dc.l	560,	40,	580,	60
	 dc.l	580,	40,	600,	60
	 dc.l	600,	40,	620,	60
	 dc.l	620,	40,	640,	60
	 dc.l	0,	60,	20,	80
	 dc.l	20,	60,	40,	80
	 dc.l	40,	60,	60,	80
	 dc.l	60,	60,	80,	80
	 dc.l	80,	60,	100,	80
	 dc.l	100,	60,	120,	80
	 dc.l	120,	60,	140,	80
	 dc.l	140,	60,	160,	80
	 dc.l	160,	60,	180,	80
	 dc.l	180,	60,	200,	80
	 dc.l	200,	60,	220,	80
	 dc.l	220,	60,	240,	80
	 dc.l	240,	60,	260,	80
	 dc.l	260,	60,	280,	80
	 dc.l	280,	60,	300,	80
	 dc.l	300,	60,	320,	80
	 dc.l	320,	60,	340,	80
	 dc.l	340,	60,	360,	80
	 dc.l	360,	60,	380,	80
	 dc.l	380,	60,	400,	80
	 dc.l	400,	60,	420,	80
	 dc.l	420,	60,	440,	80
	 dc.l	440,	60,	460,	80
	 dc.l	460,	60,	480,	80
	 dc.l	480,	60,	500,	80
	 dc.l	500,	60,	520,	80
	 dc.l	520,	60,	540,	80
	 dc.l	540,	60,	560,	80
	 dc.l	560,	60,	580,	80
	 dc.l	580,	60,	600,	80
	 dc.l	600,	60,	620,	80
	 dc.l	620,	60,	640,	80
	 dc.l	0,	80,	20,	100
	 dc.l	20,	80,	40,	100
	 dc.l	40,	80,	60,	100
	 dc.l	60,	80,	80,	100
	 dc.l	80,	80,	100,	100
	 dc.l	100,	80,	120,	100
	 dc.l	120,	80,	140,	100
	 dc.l	140,	80,	160,	100
	 dc.l	160,	80,	180,	100
	 dc.l	180,	80,	200,	100
	 dc.l	200,	80,	220,	100
	 dc.l	220,	80,	240,	100
	 dc.l	240,	80,	260,	100
	 dc.l	260,	80,	280,	100
	 dc.l	280,	80,	300,	100
	 dc.l	300,	80,	320,	100
	 dc.l	320,	80,	340,	100
	 dc.l	340,	80,	360,	100
	 dc.l	360,	80,	380,	100
	 dc.l	380,	80,	400,	100
	 dc.l	400,	80,	420,	100
	 dc.l	420,	80,	440,	100
	 dc.l	440,	80,	460,	100
	 dc.l	460,	80,	480,	100
	 dc.l	480,	80,	500,	100
	 dc.l	500,	80,	520,	100
	 dc.l	520,	80,	540,	100
	 dc.l	540,	80,	560,	100
	 dc.l	560,	80,	580,	100
	 dc.l	580,	80,	600,	100
	 dc.l	600,	80,	620,	100
	 dc.l	620,	80,	640,	100
	 dc.l	0,	100,	20,	120
	 dc.l	20,	100,	40,	120
	 dc.l	40,	100,	60,	120
	 dc.l	60,	100,	80,	120
	 dc.l	80,	100,	100,	120
	 dc.l	100,	100,	120,	120
	 dc.l	120,	100,	140,	120
	 dc.l	140,	100,	160,	120
	 dc.l	160,	100,	180,	120
	 dc.l	180,	100,	200,	120
	 dc.l	200,	100,	220,	120
	 dc.l	220,	100,	240,	120
	 dc.l	240,	100,	260,	120
	 dc.l	260,	100,	280,	120
	 dc.l	280,	100,	300,	120
	 dc.l	300,	100,	320,	120
	 dc.l	320,	100,	340,	120
	 dc.l	340,	100,	360,	120
	 dc.l	360,	100,	380,	120
	 dc.l	380,	100,	400,	120
	 dc.l	400,	100,	420,	120
	 dc.l	420,	100,	440,	120
	 dc.l	440,	100,	460,	120
	 dc.l	460,	100,	480,	120
	 dc.l	480,	100,	500,	120
	 dc.l	500,	100,	520,	120
	 dc.l	520,	100,	540,	120
	 dc.l	540,	100,	560,	120
	 dc.l	560,	100,	580,	120
	 dc.l	580,	100,	600,	120
	 dc.l	600,	100,	620,	120
	 dc.l	620,	100,	640,	120
	 dc.l	0,	120,	20,	140
	 dc.l	20,	120,	40,	140
	 dc.l	40,	120,	60,	140
	 dc.l	60,	120,	80,	140
	 dc.l	80,	120,	100,	140
	 dc.l	100,	120,	120,	140
	 dc.l	120,	120,	140,	140
	 dc.l	140,	120,	160,	140
	 dc.l	160,	120,	180,	140
	 dc.l	180,	120,	200,	140
	 dc.l	200,	120,	220,	140
	 dc.l	220,	120,	240,	140
	 dc.l	240,	120,	260,	140
	 dc.l	260,	120,	280,	140
	 dc.l	280,	120,	300,	140
	 dc.l	300,	120,	320,	140
	 dc.l	320,	120,	340,	140
	 dc.l	340,	120,	360,	140
	 dc.l	360,	120,	380,	140
	 dc.l	380,	120,	400,	140
	 dc.l	400,	120,	420,	140
	 dc.l	420,	120,	440,	140
	 dc.l	440,	120,	460,	140
	 dc.l	460,	120,	480,	140
	 dc.l	480,	120,	500,	140
	 dc.l	500,	120,	520,	140
	 dc.l	520,	120,	540,	140
	 dc.l	540,	120,	560,	140
	 dc.l	560,	120,	580,	140
	 dc.l	580,	120,	600,	140
	 dc.l	600,	120,	620,	140
	 dc.l	620,	120,	640,	140
	 dc.l	0,	140,	20,	160
	 dc.l	20,	140,	40,	160
	 dc.l	40,	140,	60,	160
	 dc.l	60,	140,	80,	160
	 dc.l	80,	140,	100,	160
	 dc.l	100,	140,	120,	160
	 dc.l	120,	140,	140,	160
	 dc.l	140,	140,	160,	160
	 dc.l	160,	140,	180,	160
	 dc.l	180,	140,	200,	160
	 dc.l	200,	140,	220,	160
	 dc.l	220,	140,	240,	160
	 dc.l	240,	140,	260,	160
	 dc.l	260,	140,	280,	160
	 dc.l	280,	140,	300,	160
	 dc.l	300,	140,	320,	160
	 dc.l	320,	140,	340,	160
	 dc.l	340,	140,	360,	160
	 dc.l	360,	140,	380,	160
	 dc.l	380,	140,	400,	160
	 dc.l	400,	140,	420,	160
	 dc.l	420,	140,	440,	160
	 dc.l	440,	140,	460,	160
	 dc.l	460,	140,	480,	160
	 dc.l	480,	140,	500,	160
	 dc.l	500,	140,	520,	160
	 dc.l	520,	140,	540,	160
	 dc.l	540,	140,	560,	160
	 dc.l	560,	140,	580,	160
	 dc.l	580,	140,	600,	160
	 dc.l	600,	140,	620,	160
	 dc.l	620,	140,	640,	160
	 dc.l	0,	160,	20,	180
	 dc.l	20,	160,	40,	180
	 dc.l	40,	160,	60,	180
	 dc.l	60,	160,	80,	180
	 dc.l	80,	160,	100,	180
	 dc.l	100,	160,	120,	180
	 dc.l	120,	160,	140,	180
	 dc.l	140,	160,	160,	180
	 dc.l	160,	160,	180,	180
	 dc.l	180,	160,	200,	180
	 dc.l	200,	160,	220,	180
	 dc.l	220,	160,	240,	180
	 dc.l	240,	160,	260,	180
	 dc.l	260,	160,	280,	180
	 dc.l	280,	160,	300,	180
	 dc.l	300,	160,	320,	180
	 dc.l	320,	160,	340,	180
	 dc.l	340,	160,	360,	180
	 dc.l	360,	160,	380,	180
	 dc.l	380,	160,	400,	180
	 dc.l	400,	160,	420,	180
	 dc.l	420,	160,	440,	180
	 dc.l	440,	160,	460,	180
	 dc.l	460,	160,	480,	180
	 dc.l	480,	160,	500,	180
	 dc.l	500,	160,	520,	180
	 dc.l	520,	160,	540,	180
	 dc.l	540,	160,	560,	180
	 dc.l	560,	160,	580,	180
	 dc.l	580,	160,	600,	180
	 dc.l	600,	160,	620,	180
	 dc.l	620,	160,	640,	180
	 dc.l	0,	180,	20,	200
	 dc.l	20,	180,	40,	200
	 dc.l	40,	180,	60,	200
	 dc.l	60,	180,	80,	200
	 dc.l	80,	180,	100,	200
	 dc.l	100,	180,	120,	200
	 dc.l	120,	180,	140,	200
	 dc.l	140,	180,	160,	200
	 dc.l	160,	180,	180,	200
	 dc.l	180,	180,	200,	200
	 dc.l	200,	180,	220,	200
	 dc.l	220,	180,	240,	200
	 dc.l	240,	180,	260,	200
	 dc.l	260,	180,	280,	200
	 dc.l	280,	180,	300,	200
	 dc.l	300,	180,	320,	200
	 dc.l	320,	180,	340,	200
	 dc.l	340,	180,	360,	200
	 dc.l	360,	180,	380,	200
	 dc.l	380,	180,	400,	200
	 dc.l	400,	180,	420,	200
	 dc.l	420,	180,	440,	200
	 dc.l	440,	180,	460,	200
	 dc.l	460,	180,	480,	200
	 dc.l	480,	180,	500,	200
	 dc.l	500,	180,	520,	200
	 dc.l	520,	180,	540,	200
	 dc.l	540,	180,	560,	200
	 dc.l	560,	180,	580,	200
	 dc.l	580,	180,	600,	200
	 dc.l	600,	180,	620,	200
	 dc.l	620,	180,	640,	200
	 dc.l	0,	200,	20,	220
	 dc.l	20,	200,	40,	220
	 dc.l	40,	200,	60,	220
	 dc.l	60,	200,	80,	220
	 dc.l	80,	200,	100,	220
	 dc.l	100,	200,	120,	220
	 dc.l	120,	200,	140,	220
	 dc.l	140,	200,	160,	220
	 dc.l	160,	200,	180,	220
	 dc.l	180,	200,	200,	220
	 dc.l	200,	200,	220,	220
	 dc.l	220,	200,	240,	220
	 dc.l	240,	200,	260,	220
	 dc.l	260,	200,	280,	220
	 dc.l	280,	200,	300,	220
	 dc.l	300,	200,	320,	220
	 dc.l	320,	200,	340,	220
	 dc.l	340,	200,	360,	220
	 dc.l	360,	200,	380,	220
	 dc.l	380,	200,	400,	220
	 dc.l	400,	200,	420,	220
	 dc.l	420,	200,	440,	220
	 dc.l	440,	200,	460,	220
	 dc.l	460,	200,	480,	220
	 dc.l	480,	200,	500,	220
	 dc.l	500,	200,	520,	220
	 dc.l	520,	200,	540,	220
	 dc.l	540,	200,	560,	220
	 dc.l	560,	200,	580,	220
	 dc.l	580,	200,	600,	220
	 dc.l	600,	200,	620,	220
	 dc.l	620,	200,	640,	220
	 dc.l	0,	220,	20,	240
	 dc.l	20,	220,	40,	240
	 dc.l	40,	220,	60,	240
	 dc.l	60,	220,	80,	240
	 dc.l	80,	220,	100,	240
	 dc.l	100,	220,	120,	240
	 dc.l	120,	220,	140,	240
	 dc.l	140,	220,	160,	240
	 dc.l	160,	220,	180,	240
	 dc.l	180,	220,	200,	240
	 dc.l	200,	220,	220,	240
	 dc.l	220,	220,	240,	240
	 dc.l	240,	220,	260,	240
	 dc.l	260,	220,	280,	240
	 dc.l	280,	220,	300,	240
	 dc.l	300,	220,	320,	240
	 dc.l	320,	220,	340,	240
	 dc.l	340,	220,	360,	240
	 dc.l	360,	220,	380,	240
	 dc.l	380,	220,	400,	240
	 dc.l	400,	220,	420,	240
	 dc.l	420,	220,	440,	240
	 dc.l	440,	220,	460,	240
	 dc.l	460,	220,	480,	240
	 dc.l	480,	220,	500,	240
	 dc.l	500,	220,	520,	240
	 dc.l	520,	220,	540,	240
	 dc.l	540,	220,	560,	240
	 dc.l	560,	220,	580,	240
	 dc.l	580,	220,	600,	240
	 dc.l	600,	220,	620,	240
	 dc.l	620,	220,	640,	240
	 dc.l	0,	240,	20,	260
	 dc.l	20,	240,	40,	260
	 dc.l	40,	240,	60,	260
	 dc.l	60,	240,	80,	260
	 dc.l	80,	240,	100,	260
	 dc.l	100,	240,	120,	260
	 dc.l	120,	240,	140,	260
	 dc.l	140,	240,	160,	260
	 dc.l	160,	240,	180,	260
	 dc.l	180,	240,	200,	260
	 dc.l	200,	240,	220,	260
	 dc.l	220,	240,	240,	260
	 dc.l	240,	240,	260,	260
	 dc.l	260,	240,	280,	260
	 dc.l	280,	240,	300,	260
	 dc.l	300,	240,	320,	260
	 dc.l	320,	240,	340,	260
	 dc.l	340,	240,	360,	260
	 dc.l	360,	240,	380,	260
	 dc.l	380,	240,	400,	260
	 dc.l	400,	240,	420,	260
	 dc.l	420,	240,	440,	260
	 dc.l	440,	240,	460,	260
	 dc.l	460,	240,	480,	260
	 dc.l	480,	240,	500,	260
	 dc.l	500,	240,	520,	260
	 dc.l	520,	240,	540,	260
	 dc.l	540,	240,	560,	260
	 dc.l	560,	240,	580,	260
	 dc.l	580,	240,	600,	260
	 dc.l	600,	240,	620,	260
	 dc.l	620,	240,	640,	260
	 dc.l	0,	260,	20,	280
	 dc.l	20,	260,	40,	280
	 dc.l	40,	260,	60,	280
	 dc.l	60,	260,	80,	280
	 dc.l	80,	260,	100,	280
	 dc.l	100,	260,	120,	280
	 dc.l	120,	260,	140,	280
	 dc.l	140,	260,	160,	280
	 dc.l	160,	260,	180,	280
	 dc.l	180,	260,	200,	280
	 dc.l	200,	260,	220,	280
	 dc.l	220,	260,	240,	280
	 dc.l	240,	260,	260,	280
	 dc.l	260,	260,	280,	280
	 dc.l	280,	260,	300,	280
	 dc.l	300,	260,	320,	280
	 dc.l	320,	260,	340,	280
	 dc.l	340,	260,	360,	280
	 dc.l	360,	260,	380,	280
	 dc.l	380,	260,	400,	280
	 dc.l	400,	260,	420,	280
	 dc.l	420,	260,	440,	280
	 dc.l	440,	260,	460,	280
	 dc.l	460,	260,	480,	280
	 dc.l	480,	260,	500,	280
	 dc.l	500,	260,	520,	280
	 dc.l	520,	260,	540,	280
	 dc.l	540,	260,	560,	280
	 dc.l	560,	260,	580,	280
	 dc.l	580,	260,	600,	280
	 dc.l	600,	260,	620,	280
	 dc.l	620,	260,	640,	280
	 dc.l	0,	280,	20,	300
	 dc.l	20,	280,	40,	300
	 dc.l	40,	280,	60,	300
	 dc.l	60,	280,	80,	300
	 dc.l	80,	280,	100,	300
	 dc.l	100,	280,	120,	300
	 dc.l	120,	280,	140,	300
	 dc.l	140,	280,	160,	300
	 dc.l	160,	280,	180,	300
	 dc.l	180,	280,	200,	300
	 dc.l	200,	280,	220,	300
	 dc.l	220,	280,	240,	300
	 dc.l	240,	280,	260,	300
	 dc.l	260,	280,	280,	300
	 dc.l	280,	280,	300,	300
	 dc.l	300,	280,	320,	300
	 dc.l	320,	280,	340,	300
	 dc.l	340,	280,	360,	300
	 dc.l	360,	280,	380,	300
	 dc.l	380,	280,	400,	300
	 dc.l	400,	280,	420,	300
	 dc.l	420,	280,	440,	300
	 dc.l	440,	280,	460,	300
	 dc.l	460,	280,	480,	300
	 dc.l	480,	280,	500,	300
	 dc.l	500,	280,	520,	300
	 dc.l	520,	280,	540,	300
	 dc.l	540,	280,	560,	300
	 dc.l	560,	280,	580,	300
	 dc.l	580,	280,	600,	300
	 dc.l	600,	280,	620,	300
	 dc.l	620,	280,	640,	300
	 dc.l	0,	300,	20,	320
	 dc.l	20,	300,	40,	320
	 dc.l	40,	300,	60,	320
	 dc.l	60,	300,	80,	320
	 dc.l	80,	300,	100,	320
	 dc.l	100,	300,	120,	320
	 dc.l	120,	300,	140,	320
	 dc.l	140,	300,	160,	320
	 dc.l	160,	300,	180,	320
	 dc.l	180,	300,	200,	320
	 dc.l	200,	300,	220,	320
	 dc.l	220,	300,	240,	320
	 dc.l	240,	300,	260,	320
	 dc.l	260,	300,	280,	320
	 dc.l	280,	300,	300,	320
	 dc.l	300,	300,	320,	320
	 dc.l	320,	300,	340,	320
	 dc.l	340,	300,	360,	320
	 dc.l	360,	300,	380,	320
	 dc.l	380,	300,	400,	320
	 dc.l	400,	300,	420,	320
	 dc.l	420,	300,	440,	320
	 dc.l	440,	300,	460,	320
	 dc.l	460,	300,	480,	320
	 dc.l	480,	300,	500,	320
	 dc.l	500,	300,	520,	320
	 dc.l	520,	300,	540,	320
	 dc.l	540,	300,	560,	320
	 dc.l	560,	300,	580,	320
	 dc.l	580,	300,	600,	320
	 dc.l	600,	300,	620,	320
	 dc.l	620,	300,	640,	320
	 dc.l	0,	320,	20,	340
	 dc.l	20,	320,	40,	340
	 dc.l	40,	320,	60,	340
	 dc.l	60,	320,	80,	340
	 dc.l	80,	320,	100,	340
	 dc.l	100,	320,	120,	340
	 dc.l	120,	320,	140,	340
	 dc.l	140,	320,	160,	340
	 dc.l	160,	320,	180,	340
	 dc.l	180,	320,	200,	340
	 dc.l	200,	320,	220,	340
	 dc.l	220,	320,	240,	340
	 dc.l	240,	320,	260,	340
	 dc.l	260,	320,	280,	340
	 dc.l	280,	320,	300,	340
	 dc.l	300,	320,	320,	340
	 dc.l	320,	320,	340,	340
	 dc.l	340,	320,	360,	340
	 dc.l	360,	320,	380,	340
	 dc.l	380,	320,	400,	340
	 dc.l	400,	320,	420,	340
	 dc.l	420,	320,	440,	340
	 dc.l	440,	320,	460,	340
	 dc.l	460,	320,	480,	340
	 dc.l	480,	320,	500,	340
	 dc.l	500,	320,	520,	340
	 dc.l	520,	320,	540,	340
	 dc.l	540,	320,	560,	340
	 dc.l	560,	320,	580,	340
	 dc.l	580,	320,	600,	340
	 dc.l	600,	320,	620,	340
	 dc.l	620,	320,	640,	340
	 dc.l	0,	340,	20,	360
	 dc.l	20,	340,	40,	360
	 dc.l	40,	340,	60,	360
	 dc.l	60,	340,	80,	360
	 dc.l	80,	340,	100,	360
	 dc.l	100,	340,	120,	360
	 dc.l	120,	340,	140,	360
	 dc.l	140,	340,	160,	360
	 dc.l	160,	340,	180,	360
	 dc.l	180,	340,	200,	360
	 dc.l	200,	340,	220,	360
	 dc.l	220,	340,	240,	360
	 dc.l	240,	340,	260,	360
	 dc.l	260,	340,	280,	360
	 dc.l	280,	340,	300,	360
	 dc.l	300,	340,	320,	360
	 dc.l	320,	340,	340,	360
	 dc.l	340,	340,	360,	360
	 dc.l	360,	340,	380,	360
	 dc.l	380,	340,	400,	360
	 dc.l	400,	340,	420,	360
	 dc.l	420,	340,	440,	360
	 dc.l	440,	340,	460,	360
	 dc.l	460,	340,	480,	360
	 dc.l	480,	340,	500,	360
	 dc.l	500,	340,	520,	360
	 dc.l	520,	340,	540,	360
	 dc.l	540,	340,	560,	360
	 dc.l	560,	340,	580,	360
	 dc.l	580,	340,	600,	360
	 dc.l	600,	340,	620,	360
	 dc.l	620,	340,	640,	360
	 dc.l	0,	360,	20,	380
	 dc.l	20,	360,	40,	380
	 dc.l	40,	360,	60,	380
	 dc.l	60,	360,	80,	380
	 dc.l	80,	360,	100,	380
	 dc.l	100,	360,	120,	380
	 dc.l	120,	360,	140,	380
	 dc.l	140,	360,	160,	380
	 dc.l	160,	360,	180,	380
	 dc.l	180,	360,	200,	380
	 dc.l	200,	360,	220,	380
	 dc.l	220,	360,	240,	380
	 dc.l	240,	360,	260,	380
	 dc.l	260,	360,	280,	380
	 dc.l	280,	360,	300,	380
	 dc.l	300,	360,	320,	380
	 dc.l	320,	360,	340,	380
	 dc.l	340,	360,	360,	380
	 dc.l	360,	360,	380,	380
	 dc.l	380,	360,	400,	380
	 dc.l	400,	360,	420,	380
	 dc.l	420,	360,	440,	380
	 dc.l	440,	360,	460,	380
	 dc.l	460,	360,	480,	380
	 dc.l	480,	360,	500,	380
	 dc.l	500,	360,	520,	380
	 dc.l	520,	360,	540,	380
	 dc.l	540,	360,	560,	380
	 dc.l	560,	360,	580,	380
	 dc.l	580,	360,	600,	380
	 dc.l	600,	360,	620,	380
	 dc.l	620,	360,	640,	380
	 dc.l	0,	380,	20,	400
	 dc.l	20,	380,	40,	400
	 dc.l	40,	380,	60,	400
	 dc.l	60,	380,	80,	400
	 dc.l	80,	380,	100,	400
	 dc.l	100,	380,	120,	400
	 dc.l	120,	380,	140,	400
	 dc.l	140,	380,	160,	400
	 dc.l	160,	380,	180,	400
	 dc.l	180,	380,	200,	400
	 dc.l	200,	380,	220,	400
	 dc.l	220,	380,	240,	400
	 dc.l	240,	380,	260,	400
	 dc.l	260,	380,	280,	400
	 dc.l	280,	380,	300,	400
	 dc.l	300,	380,	320,	400
	 dc.l	320,	380,	340,	400
	 dc.l	340,	380,	360,	400
	 dc.l	360,	380,	380,	400
	 dc.l	380,	380,	400,	400
	 dc.l	400,	380,	420,	400
	 dc.l	420,	380,	440,	400
	 dc.l	440,	380,	460,	400
	 dc.l	460,	380,	480,	400
	 dc.l	480,	380,	500,	400
	 dc.l	500,	380,	520,	400
	 dc.l	520,	380,	540,	400
	 dc.l	540,	380,	560,	400
	 dc.l	560,	380,	580,	400
	 dc.l	580,	380,	600,	400
	 dc.l	600,	380,	620,	400
	 dc.l	620,	380,	640,	400
	 dc.l	0,	400,	20,	420
	 dc.l	20,	400,	40,	420
	 dc.l	40,	400,	60,	420
	 dc.l	60,	400,	80,	420
	 dc.l	80,	400,	100,	420
	 dc.l	100,	400,	120,	420
	 dc.l	120,	400,	140,	420
	 dc.l	140,	400,	160,	420
	 dc.l	160,	400,	180,	420
	 dc.l	180,	400,	200,	420
	 dc.l	200,	400,	220,	420
	 dc.l	220,	400,	240,	420
	 dc.l	240,	400,	260,	420
	 dc.l	260,	400,	280,	420
	 dc.l	280,	400,	300,	420
	 dc.l	300,	400,	320,	420
	 dc.l	320,	400,	340,	420
	 dc.l	340,	400,	360,	420
	 dc.l	360,	400,	380,	420
	 dc.l	380,	400,	400,	420
	 dc.l	400,	400,	420,	420
	 dc.l	420,	400,	440,	420
	 dc.l	440,	400,	460,	420
	 dc.l	460,	400,	480,	420
	 dc.l	480,	400,	500,	420
	 dc.l	500,	400,	520,	420
	 dc.l	520,	400,	540,	420
	 dc.l	540,	400,	560,	420
	 dc.l	560,	400,	580,	420
	 dc.l	580,	400,	600,	420
	 dc.l	600,	400,	620,	420
	 dc.l	620,	400,	640,	420
	 dc.l	0,	420,	20,	440
	 dc.l	20,	420,	40,	440
	 dc.l	40,	420,	60,	440
	 dc.l	60,	420,	80,	440
	 dc.l	80,	420,	100,	440
	 dc.l	100,	420,	120,	440
	 dc.l	120,	420,	140,	440
	 dc.l	140,	420,	160,	440
	 dc.l	160,	420,	180,	440
	 dc.l	180,	420,	200,	440
	 dc.l	200,	420,	220,	440
	 dc.l	220,	420,	240,	440
	 dc.l	240,	420,	260,	440
	 dc.l	260,	420,	280,	440
	 dc.l	280,	420,	300,	440
	 dc.l	300,	420,	320,	440
	 dc.l	320,	420,	340,	440
	 dc.l	340,	420,	360,	440
	 dc.l	360,	420,	380,	440
	 dc.l	380,	420,	400,	440
	 dc.l	400,	420,	420,	440
	 dc.l	420,	420,	440,	440
	 dc.l	440,	420,	460,	440
	 dc.l	460,	420,	480,	440
	 dc.l	480,	420,	500,	440
	 dc.l	500,	420,	520,	440
	 dc.l	520,	420,	540,	440
	 dc.l	540,	420,	560,	440
	 dc.l	560,	420,	580,	440
	 dc.l	580,	420,	600,	440
	 dc.l	600,	420,	620,	440
	 dc.l	620,	420,	640,	440
	 dc.l	0,	440,	20,	460
	 dc.l	20,	440,	40,	460
	 dc.l	40,	440,	60,	460
	 dc.l	60,	440,	80,	460
	 dc.l	80,	440,	100,	460
	 dc.l	100,	440,	120,	460
	 dc.l	120,	440,	140,	460
	 dc.l	140,	440,	160,	460
	 dc.l	160,	440,	180,	460
	 dc.l	180,	440,	200,	460
	 dc.l	200,	440,	220,	460
	 dc.l	220,	440,	240,	460
	 dc.l	240,	440,	260,	460
	 dc.l	260,	440,	280,	460
	 dc.l	280,	440,	300,	460
	 dc.l	300,	440,	320,	460
	 dc.l	320,	440,	340,	460
	 dc.l	340,	440,	360,	460
	 dc.l	360,	440,	380,	460
	 dc.l	380,	440,	400,	460
	 dc.l	400,	440,	420,	460
	 dc.l	420,	440,	440,	460
	 dc.l	440,	440,	460,	460
	 dc.l	460,	440,	480,	460
	 dc.l	480,	440,	500,	460
	 dc.l	500,	440,	520,	460
	 dc.l	520,	440,	540,	460
	 dc.l	540,	440,	560,	460
	 dc.l	560,	440,	580,	460
	 dc.l	580,	440,	600,	460
	 dc.l	600,	440,	620,	460
	 dc.l	620,	440,	640,	460
	 dc.l	0,	460,	20,	480
	 dc.l	20,	460,	40,	480
	 dc.l	40,	460,	60,	480
	 dc.l	60,	460,	80,	480
	 dc.l	80,	460,	100,	480
	 dc.l	100,	460,	120,	480
	 dc.l	120,	460,	140,	480
	 dc.l	140,	460,	160,	480
	 dc.l	160,	460,	180,	480
	 dc.l	180,	460,	200,	480
	 dc.l	200,	460,	220,	480
	 dc.l	220,	460,	240,	480
	 dc.l	240,	460,	260,	480
	 dc.l	260,	460,	280,	480
	 dc.l	280,	460,	300,	480
	 dc.l	300,	460,	320,	480
	 dc.l	320,	460,	340,	480
	 dc.l	340,	460,	360,	480
	 dc.l	360,	460,	380,	480
	 dc.l	380,	460,	400,	480
	 dc.l	400,	460,	420,	480
	 dc.l	420,	460,	440,	480
	 dc.l	440,	460,	460,	480
	 dc.l	460,	460,	480,	480
	 dc.l	480,	460,	500,	480
	 dc.l	500,	460,	520,	480
	 dc.l	520,	460,	540,	480
	 dc.l	540,	460,	560,	480
	 dc.l	560,	460,	580,	480
	 dc.l	580,	460,	600,	480
	 dc.l	600,	460,	620,	480
	 dc.l	620,	460,	640,	480



















































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
