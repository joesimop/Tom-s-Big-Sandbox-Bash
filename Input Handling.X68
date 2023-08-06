*-----------------------------------------------------------
* Title      :  Input Handling
* Written by :  Joe Simopoulos
* Date       :  5/31/2023
* Description:  Gets and updates input values.
*-----------------------------------------------------------

*Macros
LEFT_MOUSE_STATE             EQU 0
RIGHT_MOUSE_STATE             EQU 1

*Gets mouse,'a', and 'd' inputs, flags tile change
*No arguments or local variables
*Overwrites d0-d2
GetInput:

    jsr GetMouseInput
    jsr MouseTileUpdate
    
    jsr GetKeyboardInput
    
    rts

*Functions

*Gets mouse coords and stores click coordinates
*Debounces mouse clicks as well.
*Puts mouse position into d1 and d2, x and y respectivley
*Overwrites d0-d3
GetMouseInput:
    
    moveq   #0, d1
    moveq   #MOUSE_READ, d0
    TRAP    #15
    
    *Check if mouse is clicked
    tst.l   d0
    beq     NO_MOUSE_INPUT
    
    *Check if debounce is set to 0, if it is, continue input checking.
    move.b   MOUSE_DEBOUNCE, d2
    beq      UPDATE_DEBOUNCED_CLICK
    
    *****NEW CLICK*****
    
    *Set Debounce State
    move.b  #0, MOUSE_DEBOUNCE
    
    *Check for left click
    btst    #LEFT_MOUSE_STATE, d0
    beq     RIGHT_CLICK
    move.b  #1, MOUSE_LEFT_CLICK
    bra.s   UPDATE_CLICK_VARIABLES
    
RIGHT_CLICK

    move.b  #1, MOUSE_RIGHT_CLICK
    
UPDATE_CLICK_VARIABLES
    
    *Update mouse click pixel coords
    move.w  d1, MOUSE_CLICK_X
    swap    d1
    move.w  d1, MOUSE_CLICK_Y
    
    *Put back in order for tile conversion
    swap    d1
    
    bra.s   MOUSE_FINISH
    
NO_MOUSE_INPUT
    move.b  #1, MOUSE_DEBOUNCE
    
UPDATE_DEBOUNCED_CLICK
    move.b  #0, MOUSE_LEFT_CLICK
    move.b  #0, MOUSE_RIGHT_CLICK
    
MOUSE_FINISH
    rts
    

*Gets the keyboard input for A and D, stores in variables
*Overwrites d0, d1
GetKeyboardInput:

    move.l  #KEY_INPUT_TRAP, d0
    move.l  #0<<24+'R'<<16+'A'<<8+'D', d1
    TRAP    #15
    
    tst.l   d1
    beq     NO_KEYBOARD_INPUT
    
    move.b  KEYBOARD_DEBOUNCE, d2
    beq     UPDATE_DEBOUNCED_PRESS
    
    move.b  #0, KEYBOARD_DEBOUNCE
    
    btst.l  #0, d1      ;Is 'D' pressed?
    beq     A_OR_R_PRESSED
    move.b  #1, D_PRESS_STATE
    bra.s   KEYBOARD_FINISH
    
A_OR_R_PRESSED

    btst.l  #8, d1
    beq     R_PRESSED
    move.b  #1, A_PRESS_STATE
    bra.s   KEYBOARD_FINISH
    
R_PRESSED
    move.b #1, R_PRESS_STATE
    bra.s   KEYBOARD_FINISH
    
NO_KEYBOARD_INPUT
    move.b  #1, KEYBOARD_DEBOUNCE
    
UPDATE_DEBOUNCED_PRESS
    move.b  #0, A_PRESS_STATE
    move.b  #0, D_PRESS_STATE
    move.b  #0, R_PRESS_STATE
    
    
KEYBOARD_FINISH
    
    rts
    
*Converts pixel coordinates to tile coordinates and flags tile change
*Takes the x coordinate into d1 and y coordinate  
MouseTileUpdate:
    
    ;Move y into d2, convert to tile coords
    move.l  d1, d2
    swap    d2
    jsr     PixelToTileSpace
    
    ;If x tile value has changed, flag
    cmp.w   TILE_X, d1
    bne     SET_CHANGE_FLAG
    
    ;If y tile has changed, flag
    cmp.w   TILE_Y, d2
    bne     SET_CHANGE_FLAG
    
    move.b  #0, TILE_CHANGE
    
    rts
    

*Sets TILE_CHANGE to 1 and updates tile variables
SET_CHANGE_FLAG:

    move.b  #1, TILE_CHANGE
    move.w  TILE_X, PREV_TILE_X
    move.w  TILE_Y, PREV_TILE_Y
    move.w  d1, TILE_X
    move.w  d2, TILE_Y
    
    rts
    
*Converts mouse position to tile location, and stores in d1, d2
*No local variables or arguments
*Overwrites d1, d2
PixelToTileSpace:
    
    *Clear upper word of d1 and d2
    andi.l  #$0000FFFF, d1
    andi.l  #$0000FFFF, d2
 
    divu    #TILE_SIZE, d1
    divu    #TILE_SIZE, d2
    
    *Clear Remainder
    andi.l  #$0000FFFF, d1
    andi.l  #$0000FFFF, d2
    
    rts

*Data
TILE_X              dc.w    0
TILE_Y              dc.w    0
PREV_TILE_X         dc.w    0
PREV_TILE_Y         dc.w    0
MOUSE_CLICK_X       dc.w    0
MOUSE_CLICK_Y       dc.w    0
A_PRESS_STATE       dc.b    0
D_PRESS_STATE       dc.b    0
R_PRESS_STATE       dc.b    0
TILE_CHANGE         dc.b    0
MOUSE_LEFT_CLICK    dc.b    0
MOUSE_RIGHT_CLICK   dc.b    0
MOUSE_DEBOUNCE      dc.b    1
KEYBOARD_DEBOUNCE   dc.b    0



















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
