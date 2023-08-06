*-----------------------------------------------------------
* Title      :  Game State Log
* Written by :  Joe Simopoulos
* Date       :  6/21/2023
* Description:  Keeps track of actions made by the player,
*               so that their actions can be undone
*-----------------------------------------------------------


*Functions

*Logs the selected block on a click event
LogBlockSpawn:

    move.b  SELECTED_BLOCK, d1
    move.l  BLOCK_LOG_HEAD, a1
    jsr     PushDataToStack
    
    move.l  a1, BLOCK_LOG_HEAD          ;Update Head pointer
    
    rts
    
*Logs the address of a entity who has collided
*a0: Entity Frame Address
LogEntityCollision:

    move.l  ENTITY_LOG_HEAD, a1
    jsr     PushAddressToStack
    
    move.l  a1, ENTITY_LOG_HEAD          ;Update Head pointer
    
    rts

*Gets rid of log and returns the logged value in d1
DelogBlockSpawn:
    
    move.l  BLOCK_LOG_HEAD, a1
    jsr     PopDataFromStack
    
    move.l  a1, BLOCK_LOG_HEAD          ;Update Head pointer
    
    rts

*Gets rid of an entity collision log and returns the entity
*frame's pointer in a2
DelogEntityCollision:

    move.l  ENTITY_LOG_HEAD, a1
    jsr     PopAddressFromStack
    
    move.l  a1, ENTITY_LOG_HEAD         ;UpdateHeadPointer
    
    rts

*Moves the heads back to zero
ResetLogs:

    move.l  #BLOCK_LOG_STACK, BLOCK_LOG_HEAD
    move.l  #ENTITY_LOG_STACK, ENTITY_LOG_HEAD
    
    rts
    
*Returns if the the Block Log is empty or not, in d7
IsEntityLogEmpty:

    move.l  #ENTITY_LOG_STACK, a0
    move.l  ENTITY_LOG_HEAD, a1
    jsr     IsStackEmpty
    
    rts
    
    

*Data
BLOCK_LOG_STACK:    ds.l    252                 ;Could have been byte sized, but long is implemented in stack
BLOCK_LOG_HEAD:     dc.l    BLOCK_LOG_STACK
ENTITY_LOG_STACK:   ds.l    252
ENTITY_LOG_HEAD     dc.l    ENTITY_LOG_STACK


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
