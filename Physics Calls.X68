*-----------------------------------------------------------
* Title      :  Physics Calls
* Written by :  Joe Simopoulos
* Date       :  6/2/2023
* Description:  Contains the physics calls for physics manager
*-----------------------------------------------------------

*Macros
GRAVITY     EQU 15


*Functions

*Applies gravity to a given entity
*a0: Entity Address, d2: Y FP_SPACE coordinate, d3: Velocity in FP_SPACE
*Overwrites d5, d3
ApplyGravity:

    *d6 contains delta time.
    move.l  d6, d5
    mulu    #GRAVITY, d5
    add.l   d5, d3
    add.l    d3, d2
  
    *Update YCoord and Veloctiy in Entity
    jsr SetEntityYCoordandVel
    
    *Store Pixel Displacement into Entity
    lsr.l   #FP_SPACE, d3                   ;Pixel Space
    move.l  d3, E_PIXEL_DISPLACEMENT(a0)
    
    rts


*Returns 1 in d7 if there was a collision, 0 otherwise
*d1: X Tile Position, d2:  Y FP_SPACE coordinate
*Overwrites d6
DetectCollision:
    
    *Stores ground height in d5, in pixel space
    jsr GetGroundHeight
    
    *Puts Y Coord into pixel space
    asr.l   #FP_SPACE, d2
    
    sub.l   d5, d2
    blt     NO_COLLISION
    
    *Collision
    move.l  #1, d0
    rts
    
NO_COLLISION:
    
    move.l  #0, d0
    rts
        
        
*Resolves Collision
*a0: Entity Pointer, a2: Physics Frame Pointer
*d1: X Tile Coordinate, d5: Old Ground Height in Pixel Space
ResolveCollision:

    *Save Call Loop State
    movem.l d4-d7/a2, -(sp)
    
    *Calculate new ground height
    sub.l   #TILE_SIZE, d5
    jsr     SetGroundHeight
    
    *Set new position and velocity for entity
    move.l  d5, d2
    lsl.l   #FP_SPACE, d2        ;Get back into FP_SPACE
    move.l  #0, d3
    jsr     SetEntityYCoordAndVel
    
    *Update map value
    jsr     SetMapCoordinateValue
    
    *Unsubscribe the entity from the physics manager
    move.l  a2, a0
    jsr     UnsubscribeEntityPhysicsManager
    
    *We need to do one last Draw Update before Unsubscribing, put'em in place
    
    *Get Draw Entity state
    move.l  P_ENTITY_ADDRESS(a2), a0
    jsr     GetEntityDrawInstance           ;Draw instance is now in a1
    jsr     GetEntityPos                    ;Entity Pos is now in d1, d2
    
    jsr     RedrawCollision
    
    
    *Set Collision Flag
    move.b  #1, COLLISION_FLAG
    move.b  #0, BLOCK_PLACED
    
    *Restore Call Loop State
    movem.l (sp)+, d4-d7/a2
    
    rts
    
    
*Subtracts the elapsed time in d6 from an entity's wait timer
*d5: Entity Wait Timer
UpdatePhysicsDelayTimer:
    
    sub.w   d6, d5
    move.w  d5, P_PHYSICS_DELAY(a2)
    
    rts
    
    
    
    


















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
