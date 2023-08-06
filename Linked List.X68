*-----------------------------------------------------------
* Title      :  Linked List
* Written by :  Joe Simopoulos
* Date       :  6/2/2023
* Description:  Conslidates linked list functions for managers
*-----------------------------------------------------------

*Adds node to list
*d3: Data Frame Size a0: address of new frame,
*a1: Update Function address a2: Entity address location.
*Returns frame pointer in a3
AddLinkedListNode:
    
    *Provides the jump to the next node
    move.l   d3, (a3)
    
    *Move entity pointer into buffer
    move.l   a2, D_ENTITY_ADDRESS(a3)
    
    *Move Update function into buffer
    move.l   a1, D_DRAW_FUNCTION(a3)
    
    rts
    

*Removes and entity from being accessed in list, but doesn't remove the entity
*a0: Entity's List Address, d0: size of data a3: End of current buffer variable
UnsubscribeItemFromLinkedList:

    *Store entity's address into a4
    move.l  a0, a4
    
    *Get the pointer that the current node is pointing to
    *Zero out the offset, signals no more iterating.
    move.l  (a0), d1
    move.l  #0, (a0)    
    
    *Check if last
    add.l   d0, a0
    cmp.l   a3, a0
    bne     UNSUBSCRIBE_ENTITY_FROM_LIST
    
    sub.l   d0, (a3)
    bra.s   FINISH_LIST_UNSUBSCRIBE
    
    UNSUBSCRIBE_ENTITY_FROM_LIST:
    
        *Note: Previously I was searching for the next open value. Did not edge case this implementation
        *Store the address that the removed entity was pointing to into a4
        add.l d1, a4
        
        *Restore a0 to removed entity pointer
        sub.l   d0, a0
        
        FIND_PREV_ITEM_IN_LIST:
        
            sub.l   d0, a0
            
            *Check if prev is valid, otherwise continue
            tst.l   (a0)
            beq     FIND_PREV_ITEM_IN_LIST
        
        
        *At this point, the a0 is at the first valid address before the entity's position
        *and a4 is at the next valid entity's position. So...
        
        *Calculate offset jump
        sub.l   a0, a4
    
        *Put new offset into previous valid draw frame
        move.l  a4, (a0)
   
FINISH_LIST_UNSUBSCRIBE:


   rts

*Resets all values to zero in list 
*Note: just doin 12 bytes per frame, that is what we have.
*a0: Pointer to list, d1: Count
ClearLinkedList:

    CLEAR_LIST_LOOP:
    
        move.l #0, (a0)+
        move.l #0, (a0)+
        move.l #0, (a0)+
        
        dbra    d1, CLEAR_LIST_LOOP
        
    rts
        
        
                
        
        





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
