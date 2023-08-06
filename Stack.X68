*-----------------------------------------------------------
* Title      :   Stack
* Written by :   Joe Simopoulos
* Date       :   6/21/2023
* Description:   Holds basic stack functionality
*-----------------------------------------------------------

*Macros


*Functions

*Adds a data value to the top of a stack
*d1: Value pushing to stakc, a1: Address of Head
PushDataToStack:

    move.l  d1, (a1)+
    rts
    
*Adds a address value to the top of a stack
*a0: Value pushing to stack, a1: Address of Head
PushAddressToStack:

    move.l  a0, (a1)+
    rts
    
*Pops data value from the top of a stack and puts into d1
*a1: Stack Head
PopDataFromStack:

    move.l  -(a1), d1
    rts
    
*Pops address value from the top of a stack and puts into a2
*a1: Stack Head
PopAddressFromStack:

    move.l  -(a1), a2
    rts
    
*Resets stack to original state
*a0: Stack Address, a1: Head Address Pointer
ResetStack:

    move.l  a0, (a1)
    rts
    
*Returns if a stack is empty
*a0: Stack Address Pointer, a1: Head Address
*Returns value in d7
IsStackEmpty:

    move.b  #0, d7
    
    cmp.l   a0, a1
    bne     STACK_EMPTY    
    
    add.b   #1, d7
    
STACK_EMPTY:
    
    rts

*Data

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
