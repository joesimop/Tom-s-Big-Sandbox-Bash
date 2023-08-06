*-----------------------------------------------------------
* Title      :  Map
* Written by :  Joe Simopoulos
* Date       :  6/5/2023
* Description:  Contains map buffers and map update functions
*-----------------------------------------------------------

*Macros
MAP_X_OFFSET            EQU 17
BASE_GROUND_HEIGHT      EQU (19*TILE_SIZE)              ;This puts the the ground in pixel space.
                                                        ;so we don't have to multiply every frame in physics update


*Functions

*Puts an Entity Pointer into the map with given tile values
*a0: Entity Pointer, d1: X Tile Coordinate, d2: Y FP_SPACE Coordinate
*Overwrites d1, d2, a1
SetMapCoordinateValue:

    *Calculate buffer location
    jsr GetBufferLocation
    move.l  a0, (a1)
    
    rts
    
*Returns the entity pointer at a given map location
*d1: X Tile Coordinate, d2: Y FP_SPACE Coordinate
*Returns value in a0, overwrites a1, d1, d2
GetMapCoordinateValue:

    *Calculate buffer location
    jsr GetBufferLocation
    move.l  (a1), a0
    
    rts

*Returns the buffer pointer of a give location
*d1: X Tile Coordinate, d2: Y FP_SPACE Coordinate
*Returns value in a1
GetBufferLocation:

    lea MAP_BUFFER, a1

   *Get X Value into Map Space
    sub.l   #MAP_X_OFFSET, d1
    lsl.l   #2,  d1             ;4 Byte Space
    add.l   d1,  a1
    
    *Get Y Value into Map Space
    asr.l    #FP_SPACE,  d2                ;Pixel Space
    divu     #TILE_SIZE, d2                ;Tile  Space
    sub.l    #1, d2                        ;We sub one here to offset for the top border
    andi.l   #$0000FFFF, d2
    
    mulu     #MAP_WIDTH, d2                ;Y Tile Offset
    lsl.l    #2, d2                        ;4 Byte Space
    add.l    d2, a1
    
    rts
    
*Returns if there are entities in the surrounding tiles
*A "1" in a bit represents an entity occupying that posiiton.
*Bit 0: Right Border
*Bit 1: Bottom Border
*Bit 2: Top Border
*d1: X Tile Coordinate, d2: Y FP_SPACE Coordinate
*Return value is in d7
GetSurroundingEntityStates:

    jsr     GetBufferLocation       ;Get the Map Buffer Position into a1
    moveq   #0, d7
    
    *Right Border
    add.l   #4, a1
    cmp.l   #0, (a1)
    beq     CHECK_ENTITY_TO_LEFT
    
    ori.b   #1, d7             ;Set Bit 0 Flag

CHECK_ENTITY_TO_LEFT  
    
    sub.l   #8, a1
    cmp.l   #0, (a1)
    beq     CHECK_ENTITY_BELOW
    
    ori.b   #2, d7             ;Set Bit 1 Flag   
    
CHECK_ENTITY_BELOW

    move.l  #(MAP_WIDTH+1), d0  ;+1 to move back into original position
    lsl.l   #2, d0              ;4 Byte space
    add.l   d0, a1
    
    cmp.l   #0, (a1)
    beq     FINISH_ENTITY_STATE_CHECK
    
    ori.b    #4, d7            ;Set Bit 2 Flag
    
FINISH_ENTITY_STATE_CHECK

    rts

    
    
*Increase Ground Height by one, given an X Tile Coordinate
*d1: X Tile Coordinate, d5: New Tile Height in Pixel Space
*Overwrites d1, a6
SetGroundHeight:
    
    lea GROUND_BUFFER, a6
    
    move.l  d1, d0          ;Store X Tile Coordinate
    sub.w   #MAP_X_OFFSET, d0
    lsl.l   #2,  d0         ;4 Byte space
    move.l   d5, (a6, d0)   
    
    rts
    
*Returns the ground height of given X coordinate
*d1: X Tile Position
*Puts value in d5, Overwrites a6
GetGroundHeight:
    
    lea GROUND_BUFFER, a6
    
    move.l  d1, d0      ;Store X Tile Coordinate
    sub.w   #MAP_X_OFFSET, d0 
    lsl.l   #2,  d0     ;4 Byte space
    move.l  (a6, d0), d5
    
    rts

*Resets map values
ResetMap:
    
    jsr     ResetMapBuffer
    jsr     ResetGroundBuffer
    
    rts
    
*Zeroes out map buffer
*Overwrites d7, a6
ResetMapBuffer:
    
    moveq   #0, d6
    
    lea     MAP_BUFFER, a6
    move.l  #(MAP_WIDTH*MAP_HEIGHT), d7
    subi.l  #1, d7
    
    MAP_CLEAR_LOOP:
        
        move.l d6, (a6)+    
        dbra   d7, MAP_CLEAR_LOOP
        
    rts

*Stores #18 into each ground position
ResetGroundBuffer:

    move.l  #BASE_GROUND_HEIGHT, d6
    
    lea     GROUND_BUFFER, a6
    move.l  #MAP_WIDTH, d7
    subi.l  #1, d7
    
    GROUND_RESET_LOOP:
        
        move.l d6, (a6)+    
        dbra   d7, GROUND_RESET_LOOP
        
    rts
    
*Returns the X Coord of the lefmost entity that is also grounded
*No Arguments
*Returns value in d5, Overwrites d4-d5, a1
GetLeftMostGroundedEntityXCoord:


    *Go to the ground buffer then go backwards
    *The "<<2" is for 4 byte space
    lea     GROUND_BUFFER, a1
    sub.l   #MAP_WIDTH<<2, a1        ;Get through ground part of map
    sub.l   #MAP_WIDTH<<2, a1        ;Set to beginning of the first entity row
    
    move.b   #-1, d5
    
    GET_FIRST_ENTITY_LOOP:
    
        add.b   #1, d5
        move.l  (a1)+, d4
        
        tst.l   d4
        beq     GET_FIRST_ENTITY_LOOP
        
   *Othherwise we have hit the entity, and we can return
   rts
          
    
        

*Data
MAP_BUFFER:     dcb.l   MAP_WIDTH*(MAP_HEIGHT+1),0      ;The "+1" adds map values for the ground, which will just be 0
GROUND_BUFFER:  dcb.l   MAP_WIDTH,BASE_GROUND_HEIGHT 





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
