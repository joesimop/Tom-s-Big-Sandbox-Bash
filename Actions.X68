*-----------------------------------------------------------
* Title      :  Actions
* Written by :  Joe Simopoulos
* Date       :  6/21/2023
* Description:  Holds the logic for actions that are made by the player.
*               Interfaces with the game state heavily. This is the layer
*               That primarily updates the game state.
*-----------------------------------------------------------

*Macros

*Functions

*Rotates between the possible blocks
*No arguments, however it overwrites d0-d2
UpdateBlockSelectionOnKey:

    move.b  CAN_SPAWN_BLOCK, d0         ;Only allow block swapping when you can spawn blocks
    beq     FINISH_SELECT_BLOCK_UPDATE
    
    move.b  SELECTED_BLOCK, d2          ;Save Selected block for later
    move.b  A_PRESS_STATE, d0
    
    tst.b   A_PRESS_STATE
    bne     DECREASE_SELECTED_BLOCK     ;IF THE A KEY IS PRESSED
    
    
    tst.b   D_PRESS_STATE
    bne     INCREASE_SELECTED_BLOCK     ;IF D KEY IS PRESSED
    
    rts
    
INCREASE_SELECTED_BLOCK

    moveq   #NUM_BLOCKS, d7
    cmp.b   SELECTED_BLOCK, d7
    beq     CYCLE_SELECTED_BLOCK_TO_ZERO
    add.b   #1, SELECTED_BLOCK
    bra.s   DRAW_UPDATED_BLOCK
    
CYCLE_SELECTED_BLOCK_TO_ZERO
    
    move.b  #0, SELECTED_BLOCK
    bra.s   DRAW_UPDATED_BLOCK
    
    
DECREASE_SELECTED_BLOCK

    tst.b   SELECTED_BLOCK
    beq     CYCLE_SELECTED_BLOCK_TO_FOUR
    sub.b   #1, SELECTED_BLOCK
    bra.s   DRAW_UPDATED_BLOCK
    
CYCLE_SELECTED_BLOCK_TO_FOUR

    move.b  #4, SELECTED_BLOCK
    
DRAW_UPDATED_BLOCK

    *Inval Previous block
    move.b  d2, d0          ;Move Previous selected block into d0
    move.w  TILE_X, d1
    move.w  TILE_Y, d2
    move.l  #InvalTile, a5
    jsr     CallFunctionPerTileInBlock
    
    *Draw new block
    jsr     SetPenColorToBlack
    move.b  SELECTED_BLOCK, d0
    move.b  d0, PREV_DRAWN_BLOCK
    move.w  TILE_X, d1
    move.w  TILE_Y, d2
    move.l  #DrawTileFromEntityId, a5
    jsr     CallFunctionPerTileInBlock
    
    jsr     UpdateBlockIndicator
    
FINISH_SELECT_BLOCK_UPDATE

    rts
    
    

*Checks to see if a block indicator has been clicked.
*If so, we select the block that the indicator represents
UpdateBlockSelectionOnClick:

    *First check if the click could have possible been
    *one of the indicators, so we don't have to check
    *every single indicator.
    move.b  #BLOCK_INDICATOR_WRAPPING_BOX, d0
    jsr     CheckBoundingBox
    
    tst.b   d7
    beq     FINISH_BLOCK_SELECTION_CHECK
    
    *L Block Selection Check
    move.b  #L_BLOCK_INDICATOR_BOX, d0
    jsr     CheckBoundingBox
    
    tst.b   d7
    beq     ZIG_ZAG_SELCTION_CHECK
    
    *Indicator was clicked
    move.b  #L_BLOCK, SELECTED_BLOCK
    bra.s   NEW_BLOCK_SELECTED
    
ZIG_ZAG_SELCTION_CHECK

    *Zig Zag Block Selection Check
    move.b  #ZIG_ZAG_BLOCK_INDICATOR_BOX, d0
    jsr     CheckBoundingBox
    
    tst.b   d7
    beq     LONG_SELCTION_CHECK
    
    *Indicator was clicked
    move.b  #ZIG_ZAG_BLOCK, SELECTED_BLOCK
    bra.s   NEW_BLOCK_SELECTED
    
LONG_SELCTION_CHECK

    *Long Block Selection Check
    move.b  #LONG_BLOCK_INDICATOR_BOX, d0
    jsr     CheckBoundingBox
    
    tst.b   d7
    beq     T_SELCTION_CHECK
    
    *Indicator was clicked
    move.b  #LONG_BLOCK, SELECTED_BLOCK
    bra.s   NEW_BLOCK_SELECTED
    
T_SELCTION_CHECK

    *T Block Selection Check
    move.b  #T_BLOCK_INDICATOR_BOX, d0
    jsr     CheckBoundingBox
    
    tst.b   d7
    beq     SQUARE_SELCTION_CHECK
    
    *Indicator was clicked
    move.b  #T_BLOCK, SELECTED_BLOCK
    bra.s   NEW_BLOCK_SELECTED
    
SQUARE_SELCTION_CHECK

    *T Block Selection Check
    *Must check last one, user could have clicked empty space.
    move.b  #SQUARE_BLOCK_INDICATOR_BOX, d0
    jsr     CheckBoundingBox
    
    tst.b   d7
    beq     FINISH_BLOCK_SELECTION_CHECK
    
    *Indicator was clicked
    move.b  #SQUARE_BLOCK, SELECTED_BLOCK
    
NEW_BLOCK_SELECTED

    jsr     UpdateBlockIndicator
    
FINISH_BLOCK_SELECTION_CHECK
    
    rts
    
*Checks if click is in the Reset Level button,
*if so, we will reset the level
*No arguments
*Overwrites d0, d7
ResetLevelOnClick:


    *Check Bounding Box
    move.b  #RESET_LEVEL_BOUNDING_BOX, d0
    jsr     CheckBoundingBox
    
    tst.b   d7
    beq     FINISH_RESET_LEVEL_CHECK
    
    *Check if there are even entities to clear.
    move.w  ENTITY_COUNT, d7
    tst.w   d7
    beq     FINISH_RESET_LEVEL_CHECK
    
    *Reset Level
    jsr     ResetMap
    jsr     ClearEntityBuffer
    jsr     ResetDrawManager
    jsr     ResetPhysicsManager
    jsr     ResetLogs
    
FINISH_RESET_LEVEL_CHECK
    
    rts
    


*Checks if a block is spawnable, if it is, spawns a block
*No arguments
*Overwrites many registers. Be cautionary with state.
SpawnBlock:
    
    move.b  CAN_SPAWN_BLOCK, d0
    beq     GAME_LOOP

    move.b  SELECTED_BLOCK, d0
    move.w  TILE_X, d1
    move.w  TILE_Y, d2     
    move.l  #CreateEntity, a5
    jsr     CallFunctionPerTileInBlock
    
    move.b  #1, BLOCK_PLACED
    move.b  #0, CAN_SPAWN_BLOCK
    jsr     LogBlockSpawn
    
    rts
    

*Rotates Block
*No arguments
*Overwrites d0
RotateBlock:

    *Check if cursor is outside map
    move.b  CURSOR_OUTSIDE_MAP, d0
    bne     RETURN_FROM_ROTATE_BLOCK

    *Inval Previous Rotation
    move.b SELECTED_BLOCK, d0
    move.w  TILE_X, d1
    move.w  TILE_Y, d2
    move.l  #InvalTile, a5
    jsr     CallFunctionPerTileInBlock

    move.b  SELECTED_BLOCK_ROTATION, d0
    
    tst.b   d0
    bne     NEXT_ROTATE
    
    move.b  #3, SELECTED_BLOCK_ROTATION
    bra.s   FINISH_ROTATE_BLOCK
    
NEXT_ROTATE

    sub.b   #1, SELECTED_BLOCK_ROTATION

FINISH_ROTATE_BLOCK
    
    *Draw new block
    jsr     SetPenColorToBlack
    move.b  SELECTED_BLOCK, d0
    move.w  TILE_X, d1
    move.w  TILE_Y, d2
    move.l  #DrawTileFromEntityId, a5
    jsr     CallFunctionPerTileInBlock

RETURN_FROM_ROTATE_BLOCK

    rts
    
*Undoes a move that was made by the player
UndoMoveOnKey:

        

    move.b  R_PRESS_STATE, d7
    beq     UNDO_MOVE_FINISH
    
    jsr     IsEntityLogEmpty
    tst.b   d7
    bne     UNDO_MOVE_FINISH

    jsr     DelogBlockSpawn                     ;Stores last selected block move in d1
    jsr     GetTileCountInBlock                 ;Gets the number of tiles in a block into d7
    sub.l   #1, d7                              ;For dbra
    
    UNDO_MOVE_LOOP:
    
        jsr     DelogEntityCollision            ;Stores entity's frame pointer in a2
        move.l  a2, a0
        jsr     GetEntityPos                    ;Stores entity's position into d1 and d2
        
        movem.l POS_REGS,-(sp)
        
        *Clear entity's map value
        move.l  #0, a0
        jsr     SetMapCoordinateValue
        
        movem.l (sp)+,POS_REGS
        
        *Decrease Ground Height
        jsr     GetGroundHeight
        add.l   #TILE_SIZE, d5
        jsr     SetGroundHeight
        
        *Update the Entity Manager
        jsr     ClearLastSpawnedEntity
        
        movem.w d7, -(sp)
        
        *Inval Tile
        jsr SmartInval
        
        movem.w (sp)+, d7
        
        dbra    d7, UNDO_MOVE_LOOP

UNDO_MOVE_FINISH:

    rts
        




















*Data




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
