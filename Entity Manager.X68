*-----------------------------------------------------------
* Title      :  Entity Manager
* Written by :  Joe Simopoulos
* Date       :  6/1/2023
* Description:  Contains all the data for entities, and the 
*               relevant functions for updating the entities
*-----------------------------------------------------------

*___________________________________________________________
*
*Entity Structure, in order:
*Unique ID:                                 2 Bytes
*Type:                                      2 bytes
*X_Position:                                4 Bytes
*Y_Position:                                4 Bytes
*Velocity:                                  4 Bytes
*Draw Instance in Manager:                  4 Bytes
*Pixels Displaced from last Physics udpate: 4 Bytes
*Status Flags:                              2 Bytes

*Total Bytes per Entity:                    26 Bytes
*____________________________________________________________

*Entity Macros
ENTITY_SIZE            EQU 26
E_TYPE                 EQU 2
E_X_POSITION           EQU 4
E_Y_POSITION           EQU 8
E_VELOCITY             EQU 12
E_DRAW_INSTANCE        EQU 16
E_PIXEL_DISPLACEMENT   EQU 20
E_STATUS_FLAGS         EQU 24

*SAVE STATE REGISTER
X_AND_Y_REGS           REG d1, d2


*Functions

*Contructs and entity and puts into buffer.
*d0: Entity Type ID, d1: X Position, d2: Y Position, d3: Draw Type
*Overwrites a2
CreateEntity:

    movem.l  X_AND_Y_REGS,-(sp)
    
    move.l  NEW_ENTITY_POINTER, a2
    
    *Move Unique ID into Buffer
    move.w  UNIQUE_ID_COUNTER, (a2)
    addi.w  #1, UNIQUE_ID_COUNTER
    
    *Move Tile Type into Buffer
    move.w  d0, E_TYPE(a2)
    
    *Move Positions into Buffer
    move.l  d1, E_X_POSITION(a2)
    jsr     TileToFpSpace                ;Move Y Position into FP_Space
    move.l  d2, E_Y_POSITION(a2)
    
    *Set Velocity to 0
    move.l  #0, E_VELOCITY(a2)
    
    *Move delay time into d5
    move.w  6(a3),d5
    *Subscribe to Draw Manager
    jsr     SubscribeEntityToDrawManager
    move.l  a3, E_DRAW_INSTANCE(a2)
    
    *Subscribe to Physics Manager
    jsr     SubscribeEntityToPhysicsManager
    
    *Zero out Pixel Displacement
    move.l  #0, E_PIXEL_DISPLACEMENT(a2)
    
    *Set Status Block, depending on tile type.
    *WILL SET LATER IF NECESSARY
    
    *Update Entity Count and New Entity Pointer
    addi.w  #1, (ENTITY_COUNT)
    addi.l  #ENTITY_SIZE, (NEW_ENTITY_POINTER)
    
    movem.l (sp)+,X_AND_Y_REGS
    
    rts

*Clears the entity buffer through the recorded count
ClearEntityBuffer:

    *Entity by Entity, for clarity
    lea     ENTITY_BUFFER, a2
    move.w  ENTITY_COUNT, d0
    sub.l   #1, d0
    
    CLEAR_ENTITY_LOOP:
        
        movem.l  d0/a2, -(sp)
        
        *Invals map
        move.l   E_X_POSITION(a2), d1
        move.l   E_Y_POSITION(a2), d2
        lsr.l    #FP_SPACE, d2                   ;Put Y in pixel space
        sub.l    #2, d2                          ;Border
        move.l   #TILE_SIZE+2, d5                ;Offset Y to inval position
        move.l   #TILE_SIZE+1, d4
        mulu     #TILE_SIZE, d1                  ;Put X into pixel space
        jsr      InvalPixels
        
        movem.l  (sp)+, d0/a2
        
        move.l  #0, (a2)
        move.l  #0, 4(a2)
        move.l  #0, 8(a2)
        move.l  #0, 12(a2)
        move.l  #0, 16(a2)
        move.l  #0, 20(a2)
        move.w  #0, 24(a2)
        
        add.l  #ENTITY_SIZE, a2
        
        dbra    d0, CLEAR_ENTITY_LOOP
    
    move.w  #0, ENTITY_COUNT
    move.l  #ENTITY_BUFFER, (NEW_ENTITY_POINTER)
    
    rts
    
*Removes the last spawned entity from the manager
ClearLastSpawnedEntity:

    sub.l   #ENTITY_SIZE, NEW_ENTITY_POINTER
    sub.w   #1, ENTITY_COUNT
    
    rts

*Returns the position of the address of an entity
*a0: Entity Address
*Returns X Position in d1 and Y Position in d2
GetEntityPos

    move.l  E_X_POSITION(a0), d1
    move.l  E_Y_POSITION(a0), d2
    
    rts
    
*Returns the position of the address of an entity
*a0: Entity Address
*Returns Velocity in d3
GetEntityVel

    move.l  E_VELOCITY(a0), d3
    
    rts

*Sets the Y Position and Velocity in FP_SPACE 
*a0: Entity Address, d2: Y Position, d3: Velocity
SetEntityYCoordAndVel:
    
    move.l  d2, E_Y_POSITION(a0)
    move.l  d3, E_VELOCITY(a0)
    
    rts
    
*Put entity address into a0
*Returns value in a1
GetEntityDrawInstance:

    move.l  E_DRAW_INSTANCE(a0), a1
    rts
    
*Gets the type of block, given an entity pointer
*a0: Entity pointer
*Returns value in d0
GetEntityBlockType:

    clr.l   d0
    move.w  E_TYPE(a0), d0
    rts


*Data
UNIQUE_ID_COUNTER:      dc.w    0
ENTITY_COUNT:           dc.w    0
ENTITY_BUFFER:          ds.b    6552            ;Comes from 26 bytes * 252 (max) entities
NEW_ENTITY_POINTER:     dc.l    ENTITY_BUFFER





































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
