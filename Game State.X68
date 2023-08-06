*-----------------------------------------------------------
* Title      :   Game State
* Written by :   Joe Simopoulos
* Date       :   6/6/2023
* Description:   Keeps track of game state and variables needed
*                to run the game. Title, Loading and Game screen
*                Selection as well as level selection all go here.
*                Cursor display state, selected block is also kept track here.
*-----------------------------------------------------------

*Macros
TITLE_SCREEN_CODE:       EQU 0
LOADING_SCREEN_CODE:     EQU 1
GAME_SCREEN_CODE:        EQU 2

*Functions

*Game state updates that happen every frame
UpdateGameState:

    jsr     UpdateGameStateFromCollision
    jsr     UpdateBlockSelectionOnKey
    jsr     UndoMoveOnKey
    
    
    move.b  MOUSE_LEFT_CLICK, d0
    beq     CHECK_RIGHT_CLICK
    
    jsr     ResetLevelOnClick
    jsr     UpdateBlockSelectionOnClick
    jsr     SpawnBlock
    
    bra.s   FINISH_GAME_STATE_UPDATE
    
CHECK_RIGHT_CLICK

    move.b  MOUSE_RIGHT_CLICK, d0
    beq     FINISH_GAME_STATE_UPDATE
    
    jsr     RotateBlock
    
FINISH_GAME_STATE_UPDATE
    
    rts

    

*Creates a new level after one has been completed.
StartNewLevel:

    jsr     ResetMap
    jsr     ClearEntityBuffer
    jsr     ClearLevel
    jsr     ResetDrawManager
    jsr     ResetPhysicsManager
    jsr     ResetLogs
    
    
    jsr     GetRandomLevel
    move.b  d5, CURRENT_LEVEL
    moveq   #0, d0
    move.b  d5, d0
    jsr     LoadLevel
    
    move.b  #0, LEVEL_COMPLETE
    
    rts

*Checks if there was collision, and will decide to whether to check the map.
UpdateGameStateFromCollision:

    tst.b   COLLISION_FLAG
    beq     FINISH_COLLISION_UPDATE
    
    *Collision flag has been set
    
    *If the number of dropped blocks is the same as the number
    *of entities in the level...
    move.w  ENTITIES_IN_CURRENT_LEVEL, d1
    cmp.w   ENTITY_COUNT, d1
    bne     FINISH_COLLISION_UPDATE
    
    jsr     CheckLevel
    
    tst.b   LEVEL_COMPLETE
    beq     FINISH_COLLISION_UPDATE
    
    add.b   #1, LEVELS_COMPLETED
    cmp.b   #5, LEVELS_COMPLETED        ;If we have completed all the levels...
    beq     GAME_FINISHED               ;GAME_FINSIHED is in the main file, bad practice, but here we are.
    
    jsr     StartNewLevel
    
FINISH_COLLISION_UPDATE:
    
    move.b  #0, COLLISION_FLAG
    rts

*Returns 1 in d7 if the tile beneath the input tile or either
*one next to the beneath tile is intersecting with the ground
*d1: Tile X Position, d2: Tile Y Position
CheckGroundIntersection:

    moveq   #0, d7
    
    add.l   #2, d2                  ;Bring down two so we aren't checking equal to flag
    mulu    #TILE_SIZE, d2          ;Put into pixel space, as that's what the ground height is stored as
    jsr     GetGroundHeight         ;Stores ground height in d5.
    
    cmp.w   d2, d5                  ;Ground Height - Tile Height
    blt     GROUND_INTERSECTION     ;If the value is negative, there is an intersection
    
    *Special case for Long Tile
    move.b  SELECTED_BLOCK, d0
    cmp.b   #LONG_BLOCK, d0
    bne     THREE_GROUND_CHECK
    
    *Check for left block on Long Block
    sub.w   #2, d1
    jsr     GetGroundHeight
    
    cmp.w   d2, d5
    blt     GROUND_INTERSECTION
    
    add.w   #2, d1
    
THREE_GROUND_CHECK

    *Left Tile
    sub.w   #1, d1
    jsr     GetGroundHeight
    
    cmp.w   d2, d5
    blt     GROUND_INTERSECTION
    
    *Right Tile
    add.w   #2, d1
    jsr     GetGroundHeight
    
    cmp.w   d2, d5
    blt     GROUND_INTERSECTION
    
    move.b  CURSOR_IN_GROUND, d0
    bne     GROUND_EXIT
    
    rts
    
GROUND_EXIT:
    
    move.b  #0, CURSOR_IN_GROUND
    move.b  #1, INVAL_PREV_DRAWN_FLAG
    rts
    
GROUND_INTERSECTION:
    
    move.b  #1, CURSOR_IN_GROUND
    moveq   #1, d7
    rts

*Checks if cursor is in map, and updates game state variables accordingly
*No arguments
*Overwrites d0, d7
CheckMapBoundingBox:


    move.l  #MAP_BOUNDING_BOX, d0
    jsr     CheckBoundingBox

    tst.b   d7
    beq     OUTSIDE_MAP                         ;If the cursor is outside the map
    
    *If inside map, check for reentrance
    move.b  CURSOR_OUTSIDE_MAP, d0
    beq     MAP_BOUNDING_BOX_FINSIH
    
    *If we are here, then we have reentered the map
    move.b  #0, CURSOR_OUTSIDE_MAP
    move.b  #1, INVAL_PREV_DRAWN_FLAG
    rts
    
OUTSIDE_MAP:
    move.b  #1, CURSOR_OUTSIDE_MAP
    
MAP_BOUNDING_BOX_FINSIH:
    
    rts
    

    
*Returns a random level number in d5 that hasn't been played by user.
*No arguments
*Overwrites d0-d5, a0
GetRandomLevel:

    jsr     getRandomByteIntoD5
    divu    #4, d5                              ;Divide by number of randomly selctable levels
    lsr.l   #8, d5                              ;Get Remainder
    lsr.l   #8, d5

    lea     LEVELS_PLAYED_FLAGS, a0
    move.b  (a0, d5), d4       ;Get Randomly Selected Level flag into d4
    
    SELECT_LEVEL_LOOP:
    
        tst.b   d4
        beq     SELECT_LEVEL                    ;If the level hasn't been played, select it!
        
        *Otherwise:
        cmp.b   #3, d5                          ;Will have to rotate the level if it is at #3
        beq     SET_LEVEL_TO_ZERO
        
        *If not at three, add 1 and check next level flag
        add.b   #1, d5
        bra.s   CHECK_NEXT_AVAILABLE_LEVEL
        
    SET_LEVEL_TO_ZERO:
    
        move.b  #0, d5
        
    CHECK_NEXT_AVAILABLE_LEVEL:
    
        move.b (a0, d5), d4
        bra.s   SELECT_LEVEL_LOOP
        
SELECT_LEVEL
    
    *If we reach here, we have found a playable level
    move.b  #1, (a0, d5)                                ;Set the level flag to played
    add.b   #1, d5                                      ;The Level will be plus 1 since levels 1-4 are selectable
    
    rts

*Data
CURRENT_LEVEL:              dc.b 0
CURRENT_SCREEN:             dc.b LOADING_SCREEN_CODE
SELECTED_BLOCK:             dc.b L_BLOCK
SELECTED_BLOCK_ROTATION:    dc.b 0
COLLISION_FLAG:             dc.b 0
LEVEL_COMPLETE:             dc.b 0
LEVEL_IS_LOADED:            dc.b 0
CAN_SPAWN_BLOCK             dc.b 1
BLOCK_PLACED:               dc.b 0
PREV_DRAWN_BLOCK:           dc.b L_BLOCK
PREV_DRAWN_BLOCK_X:         dc.w 23         ;These values are initilized to we don't try to redraw @ 0,0 
PREV_DRAWN_BLOCK_Y:         dc.w 6          ;on first map entrance
INVAL_PREV_DRAWN_FLAG:      dc.b 0
CURSOR_IN_GROUND:           dc.b 0
CURSOR_OUTSIDE_MAP:         dc.b 1,0
LEVELS_COMPLETED:           dc.b 0
LEVELS_PLAYED_FLAGS:        dc.b 0,0,0,0,0





































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
