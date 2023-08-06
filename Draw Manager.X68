*-----------------------------------------------------------
* Title      :  Draw Manager
* Written by :  Joe Simopoulos
* Date       :  6/1/2023
* Description:  Manages who is being drawn and tile type
*               draw table.
*-----------------------------------------------------------

*Very similar to entity manager, entities will subscribe to be
*drawn. And the draw entities every frame. The offsets for the
*Entity Draw Table can be found under types in Global Macros

*-----------------------------------------------------------
*Draw Frame, in order
*Next Draw Offset:                          4  Bytes
*Entity Address Location:                   4  Bytes
*Draw Functiton Address:                    4  Bytes
*Total Bytes per Entity:                    12 Bytes
*-----------------------------------------------------------

*The first field contains the offset to the next drawn entity

*Draw Frame
DRAW_FRAME_SIZE         EQU 12
D_ENTITY_ADDRESS        EQU 4
D_DRAW_FUNCTION         EQU 8

*Draw Registers
DRAW_REGISTERS          REG d7/a2

*Functions

*Main Draw Loop
DrawGame:

    jsr     DrawEntities
    
    jsr     CheckMapBoundingBox
    
    move.b  CURSOR_OUTSIDE_MAP, d0
    bne     OUTSIDE_SPAWN_BLOCK_ZONE    ;If the cursor is outside the map, don't bother with any of the following
    
    move.w  TILE_X, d1
    jsr     CheckGroundIntersection
        
    tst.b   d7
    bne     OUTSIDE_SPAWN_BLOCK_ZONE    ;If the cursor is inside the ground
    
    move.b  BLOCK_PLACED, d0            ;If a block has been placed, user must wait for collision
    bne     FINISH_DRAW_LOOP
    
    move.b  #1, CAN_SPAWN_BLOCK         ;If we reach here, the user can place a block
    
    move.b  TILE_CHANGE, d0             ;No need for redraw unless tile has changed
    beq     FINISH_DRAW_LOOP
    
    move.b  INVAL_PREV_DRAWN_FLAG, d0   ;If flag isn't set, jump
    beq     INVAL_BLOCK_JUMP            ;Relevant to map reentrance from ground or outside
    
INVAL_PREV_DRAWN:

    *If reentering from ground or screen,
    *rewrite the previously drawn block
    
    move.w  PREV_DRAWN_BLOCK_X, d1
    move.w  PREV_DRAWN_BLOCK_Y, d2
    move.b  PREV_DRAWN_BLOCK, d0
    move.l  #InvalTileButNotGround, a5
    jsr     CallFunctionPerTileInBlock
    move.b  #0, INVAL_PREV_DRAWN_FLAG
    bra.s   DRAW_NEW_BLOCK
        
INVAL_BLOCK_JUMP:


    *If not reenterring, inval previous tile.
    move.w  PREV_TILE_X, d1
    move.w  PREV_TILE_Y, d2
    *Invals block
    move.b  PREV_DRAWN_BLOCK, d0
    move.l  #InvalTile, a5
    jsr     CallFunctionPerTileInBlock
    
DRAW_NEW_BLOCK:
    *Draws new block
    jsr     SetPenColorToBlack
    move.b  SELECTED_BLOCK, d0  
    move.w  TILE_X, d1
    move.w  TILE_Y, d2
    move.l  #DrawTileFromEntityId, a5
    jsr     CallFunctionPerTileInBlock
    
    move.b  SELECTED_BLOCK, PREV_DRAWN_BLOCK
    move.w  TILE_X, PREV_DRAWN_BLOCK_X
    move.w  TILE_Y, PREV_DRAWN_BLOCK_Y
    bra.s   FINISH_DRAW_LOOP
    
OUTSIDE_SPAWN_BLOCK_ZONE:
    move.b  #0, CAN_SPAWN_BLOCK
    

FINISH_DRAW_LOOP:
    
    jsr SwapBuffers
    rts



*Enables double buffering, and createst he head node for the buffer.
InitializeDrawManager:

    
    move.b	#DOUBLE_BUFFER_MODE, d1
    move.b	#DRAW_MODE_TRAP, d0
    TRAP	#15

    *This is necessary for the dynamic nature of the buffer.
    *It is essentially a "jump off" point for the functions
    *Just creates a fake sand tile that cannot be removed
    move.l  #SAND, d0
    move.l  #$AEAEAEAE, a2              ;Garbage pointer value
    jsr     SubscribeEntityToDrawManager
    
    *Don't include head in entity count
    sub.b   #1, (ENTITY_DRAW_COUNT)
    
    
    rts


*Initializes an entity's ability to be drawn on screen
*d0: Entity Type ID, a2: Entity Address Location
*Returns the draw frame pointer in a3, overwrites a1, d3
SubscribeEntityToDrawManager:

    jsr     GetDrawFunctionFromEntityId     ;Puts draw function in a1
    move.l  NEW_DRAW_FRAME_POINTER, a3
    move.l  #DRAW_FRAME_SIZE, d3
    jsr     AddLinkedListNode
    

    
    *Update entities to draw count and buffer pointer.
    addi.b  #1, (ENTITY_DRAW_COUNT)
    addi.l  #DRAW_FRAME_SIZE, (NEW_DRAW_FRAME_POINTER)
    
    
    rts

*Takes in a Draw Frame Pointer in a0, and stops it from being updated
*It still exists in memory, so it could be reinitialized.
*a0: Draw Frame Pointer
*Overwrites d0, a0, a1, a4
UnsubscribeEntityFromDrawManager:

    move.l  #DRAW_FRAME_SIZE, d0
    move.l  #NEW_DRAW_FRAME_POINTER, a3
    jsr     UnsubscribeItemFromLinkedList
    
    sub.b   #1, (ENTITY_DRAW_COUNT)
    rts


*Draws all entities in draw buffer.
*Takes no arguments
*Overwrites d7
DrawEntities:
    
    *If there are no entities, don't bother (helpful after entity removal)
    clr.l   d7
    move.b  ENTITY_DRAW_COUNT, d7
    beq     FINISH_ENTITY_DRAW
    
    subi.b  #1, d7
    
    *The draw frame size offsets for the head's next
    lea     DRAW_BUFFER , a2
    add.l   (a2), a2
    
    DRAW_ENTITIES_LOOP:
        
        
        *Get entity's address into a0
        move.l  D_ENTITY_ADDRESS(a2), a0
        jsr     GetEntityPos
        
        *Draw function could be anything, save registers
        movem.l DRAW_REGISTERS, -(sp)
        
        
        move.l   E_PIXEL_DISPLACEMENT(a0), d5    ;Inval Draw height
        
        add.l   #2, d5                           ;Inval the border
        
        *Inval Entity
        *Save Pos regs for drawing after inval
        movem.l POS_REGS, -(sp)
        
        lsr.l    #FP_SPACE, d2                   ;Put Y in pixel space
        sub.l    d5, d2                          ;Offset Y to inval position
        mulu     #TILE_SIZE, d1                  ;Put X into pixel space
        move.l   #TILE_SIZE+1, d4                ;Set the width
        jsr      InvalPixels
        
        *Restore Position Values
        movem.l (sp)+, POS_REGS
        
    CONTINUE_DRAW:
        
        *Save X Position and set pen to black
        move.w  d1, d5
        jsr     SetPenColorToBlack
        move.w  d5, d1
        
        *Call Draw Function
        move.l  D_DRAW_FUNCTION(a2), a2
        jsr     (a2)
        
        *Restore State
        movem.l (sp)+, DRAW_REGISTERS
        
        *Adds next location's offset to current address pointer
        add.l   (a2), a2
        
        dbra    d7,  DRAW_ENTITIES_LOOP
        
FINISH_ENTITY_DRAW:
        
        rts
        
*Moves new draw frame pointer back and resets entity count
*Note: We can just overwrite frame buffer
*Overwrites a6
ResetDrawManager:

    lea     DRAW_BUFFER, a6
    move.l  #DRAW_FRAME_SIZE, (a6)   ;Reset head pointer to next value
    add.l   #DRAW_FRAME_SIZE, a6     ;Offset for head
    
    move.l  a6, (NEW_DRAW_FRAME_POINTER)
    move.b  #0, ENTITY_DRAW_COUNT
    
    rts

*Gets Address of a draw function given an Entity Id
*d0: Entity Id
*Returns address in a1
GetDrawFunctionFromEntityId:

    lea     ENTITY_DRAW_TABLE, a1
    move.l  (a1, d0), a1
    rts
    
*Gets the draw color given the Entity ID in d0
*d0: Entity Tile ID
*Returns value in d0, Overwrites a0
GetColorFromEntityId:

    lea ENTITY_COLOR_TABLE, a0
    move.l  (a0, d0), d0
    
    rts


*Clears screen buffer
ClearScreen:
    
    move.l  #CLEAR_SCREEN_MAGIC_VALUE,d1
    move.b  #CLEAR_SCREEN_TRAP,d0
    TRAP    #15
	rts

*Switches between double buffers
SwapBuffers:

    move.b  #SWAP_BUFFERS_TRAP, d0
    TRAP    #15
	rts


*Data

ENTITY_DRAW_COUNT:      dc.b    0,0
DRAW_BUFFER             ds.b    3026         ;Max entities is 252 atm, * 12 bytes + 1 Draw Frame for head.
DRAW_BUFFER_END         dc.l    $FFFF        ;End of buffer indication
NEW_DRAW_FRAME_POINTER: dc.l    DRAW_BUFFER
ENTITY_DRAW_TABLE:      dc.l    DrawSandEntity, DrawStoneEntity, DrawWaterEntity
ENTITY_COLOR_TABLE:     dc.l    SAND_COLOR, STONE_COLOR, WATER_COLOR











































































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
