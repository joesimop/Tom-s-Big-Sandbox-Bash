*-----------------------------------------------------------
* Title      :  Physics Manager
* Written by :  Joe Simopoulos
* Date       :  6/2/2023
* Description:  Mangaes who has physics being applied to them
*               and applies physics
*-----------------------------------------------------------

*-----------------------------------------------------------
*Physics Frame, in order
*Next Draw Offset:                          4  Bytes
*Entity Address Location:                   4  Bytes
*Update Functiton Address:                  4  Bytes
*Total Bytes per Entity:                    12 Bytes
*-----------------------------------------------------------


*Macros
*Physics Frame
PHYSICS_FRAME_SIZE  EQU 14
P_ENTITY_ADDRESS    EQU 4
P_UPDATE_FUNCTION   EQU 8
P_PHYSICS_DELAY     EQU 12


*Functions
InitializePhysicsManager:

    *Create node head.
    move.l  #$AEAEAEAE, a2              ;Garbage pointer value
    jsr     SubscribeEntityToPhysicsManager  
    
    subi.b  #1, (ENTITY_PHYSICS_COUNT)  ;Don't include head in count
    
    rts
 
*Initlializes and entity's ability to have physics applied to it.
*a2: Entity Address Locaton, d0: Delay Time Start
*Returns Fhysics Frame pointer in a3, overwrites d3
SubscribeEntityToPhysicsManager:


    move.l  #ApplyGravity, a1                  ;Puts draw function in a1
    move.l  NEW_PHYSICS_FRAME_POINTER, a3
    move.l  #PHYSICS_FRAME_SIZE, d3
    jsr     AddLinkedListNode
   
    *Note:  We are adding a delay time here, outside of the Linked List Add
    *       as it is outside the convention we established and it is for polish
    move.w  d5, P_PHYSICS_DELAY(a3)
    
    addi.b  #1, (ENTITY_PHYSICS_COUNT)
    addi.l  #PHYSICS_FRAME_SIZE, (NEW_PHYSICS_FRAME_POINTER)
    
    rts
    
*Iterates through entities and applies physics
*Takes no arguments
*Overwrites d, a3
UpdatePhysicsEntities:

    *If there are no entities, don't bother (helpful after entity removal)
    clr.l   d7
    move.b  ENTITY_PHYSICS_COUNT, d7
    beq     FINISH_PHYSICS_UPDATE
    
    subi.b  #1, d7
    
    *The draw frame size offsets for the head's next
    lea     PHYSICS_BUFFER , a2
    add.l   (a2), a2
    
    PHYSICS_UPDATE_LOOP:
    
        *Stores addition offset to next node in case current node gets unsubed
        move.l  (a2), d4
    
        *Check for delay time
        move.w  P_PHYSICS_DELAY(a2), d5
        bgt     UPDATE_PHYSICS_TIME_DELAY
        
        *Get entity's address into a0
        move.l  P_ENTITY_ADDRESS(a2), a0
        
        jsr GetEntityPos
        jsr GetEntityVel
        
        *After this function, d3 contains the updated y FP_SPACE position
        jsr     ApplyGravity
        
        jsr     DetectCollision
        
        *If Not Collided....
        tst.b   d0
        beq     CONTINUE_PHSYICS_LOOP
        
        *Resolve Collision
        jsr     ResolveCollision
        
        *Log Collision
        move.l  P_ENTITY_ADDRESS(a2), a0
        jsr     LogEntityCollision

        bra.s   CONTINUE_PHSYICS_LOOP
        
UPDATE_PHYSICS_TIME_DELAY

        jsr     UpdatePhysicsDelayTimer
        
CONTINUE_PHSYICS_LOOP

        *Adds next location's offset to current address pointer
        add.l   d4, a2
        dbra    d7, PHYSICS_UPDATE_LOOP
        
FINISH_PHYSICS_UPDATE:
        
        rts


*Passes the entity's physics frame address that want's to unsubscribe from being updated
*a0: Entity address
*Overwrites a0,a1,a4
UnsubscribeEntityPhysicsManager:

    
    move.l  #PHYSICS_FRAME_SIZE, d0
    move.l  #NEW_PHYSICS_FRAME_POINTER, a3
    jsr     UnsubscribeItemFromLinkedList
    
    sub.b   #1, (ENTITY_PHYSICS_COUNT)
    rts

    
*Moves physics frame pointer back and resets entity count
*We can just overwrite frame buffer
*Overwrites a6
ResetPhysicsManager:

    lea     PHYSICS_BUFFER, a6
    move.l  #PHYSICS_FRAME_SIZE, (a6)   ;Reset frame to point to next value
    add.l   #PHYSICS_FRAME_SIZE, a6     ;Offset for head
    
    move.l  a6, (NEW_PHYSICS_FRAME_POINTER)
    move.b  #0, ENTITY_PHYSICS_COUNT
    
    rts
    
    
*Data
ENTITY_PHYSICS_COUNT:      dc.b    0,0
PHYSICS_BUFFER             ds.b    3026             ;Max entities is 252 atm, * 12 bytes + 1 Draw Frame for head.
PHYSICS_BUFFER_END         dc.l    $FFFF            ;End of buffer indication
NEW_PHYSICS_FRAME_POINTER: dc.l    PHYSICS_BUFFER
PHYSICS_UNSUBSCRIBE_FLAG   dc.b    0,0

    INCLUDE "Physics Calls.X68"

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
