*-----------------------------------------------------------
* Title      :  Level
* Written by :  Joe Simopoulos
* Date       :  6/6/2023
* Description:  This file is soley for Tom's half of the screen.
*               Drawing the level, choosing the level, checking
*               the level, and storing the levels.
*-----------------------------------------------------------

*Macros


*Functions

*Completely instantiates a new level.
*This includes drawing the level and populating the Map Check Buffer.
*d0: Level Number
*Overwrites d1, d2, d3, a0, a2-a6
LoadLevel:

    tst.b   LEVEL_IS_LOADED
    beq     COPY_NEW_LEVEL
    
    *Otherwise, we need to clear the previous level's entity checker
    jsr ClearCheckLevelBuffer
    
COPY_NEW_LEVEL:

    *Address Loading
    move.b  d0, d3
    jsr GetLevelFromNumber
    jsr DisplayLevelName
    lea CURRENT_LEVEL_BUFFER_END, a3
    sub.l  #1, a3
    lea LEVEL_CHECK_BUFFER, a5
    
    jsr     SetPenColorToBlack
    
    *Zero Out necessary things
    move.w  #0, ENTITIES_IN_CURRENT_LEVEL
    clr.l   d0
    clr.l   d1
    clr.l   d2
    
    move.l  #MAP_HEIGHT, d2
    sub.b   #1, d2
    
    LOAD_LEVEL_Y_LOOP:
        
        move.l  #MAP_WIDTH, d1
        sub.b   #1, d1
        
        LOAD_LEVEL_X_LOOP:
        
        
            
            *a3 is the Current Level buffer
            *a4 is the Level Buffer
            
            *Check if its an air tile
            cmp.b   #$FF, (a4)
            beq     LEVEL_LOAD_CONTINUE
        
            *Copy Data from Level Buffer to Current Buffer
            move.b  (a4), d0                                ;Moves the entity ID into d0
            move.b  d0, (a3)
            
            *Move values into Check buffer
            move.b  d1, (a5)+
            move.b  d2, (a5)+
            move.b  d0, (a5)+
            
            *Save off registers
            move.l  d1, d5
            move.l  d2, d7
            
            *To put on the inside of the border
            add.l   #1, d1
            add.l   #1, d2
            
            *Draw Tile, X and Y coords should be in d1 and d2, respectivley
            jsr     DrawTileFromEntityId
            
            *Restore State from draw
            move.l  d5, d1
            move.l  d7, d2
            moveq   #0, d0
            
            *Update Number of entities in level
            add.w #1, ENTITIES_IN_CURRENT_LEVEL
            
            
       LEVEL_LOAD_CONTINUE:
            
             sub.l  #1, a3
             sub.l  #1, a4
             dbra   d1, LOAD_LEVEL_X_LOOP
       
       dbra  d2, LOAD_LEVEL_Y_LOOP
       
    move.b #1, LEVEL_IS_LOADED
    rts

*Checks to see if the level has been completed
*No arguments, Sets LEVEL_COMPLETE flag
*Overwrites d0-d4, d7, a6

*Local Variable: The X difference between the map and level
CheckLevel:

    lea     LEVEL_CHECK_BUFFER, a6
    clr.l   d7
    move.w  ENTITIES_IN_CURRENT_LEVEL, d7
    sub.b   #1, d7
    
    sub.l   #2, sp
    jsr     GetLevelMapOffset
    move.b  d5, (sp)
    
    clr.l   d1
    clr.l   d3
    
    CHECK_LEVEL_LOOP:
    
        *d2 gets translated to FP space every loop, have to reset
        clr.l   d2
        
        *Get info for one tile
        move.b  (a6)+, d1
        move.b  (a6)+, d2
        move.b  (a6)+, d3
        
        
        add.b   #MAP_X_OFFSET, d1     ;Translate X to X Map Coordinate
        add.b   (sp), d1              ;Add Map and Level Offset
        add.b   #1, d2                ;Translate down to match border

        
        *Convert Y Tile Coordinate to FP_SPACE
        jsr     TileToFpSpace
        
        *Gets the Player's Entity Pointer at those coords
        jsr     GetMapCoordinateValue
        
        *If there is no entity there, exit
        cmp.l   #0, a0
        beq     LEVEL_FAILED
        
        *Gets the block type 
        jsr     GetEntityBlockType
        
        cmp.b   d0, d3
        bne     LEVEL_FAILED
        
        dbra    d7, CHECK_LEVEL_LOOP
        
        *If we get here, the level is complete
        move.b  #1, LEVEL_COMPLETE
    
LEVEL_FAILED:

    
    add.l   #2, sp
    rts

*Returns the difference between the left-most, grounded blocks
*in the Level and Map.
*No Arguments
*Returns value in d5
GetLevelMapOffset:

    *Retrieves the LMGXCoord from the map, stores in d5
    jsr     GetLeftMostGroundedEntityXCoord
    jsr     GetLevelLeftMostGroundEntity
    
    sub.b   d4, d5                          ;The offset is now in d5
    
    rts
    
*Returns the X Coord of the leftmost, grounded entity in the level
*No arguments
*Returns value in d0, Overwrites a1, a4
GetLevelLeftMostGroundEntity:

    move.b  CURRENT_LEVEL, d0
    jsr     GetLevelFromNumber

    move.b  (a4), d4
    rts


*Redraws BMP over level buffer
*No arguments
*Overwrites a0, d7
ClearLevel:

    lea LEVEL_CHECK_BUFFER, a1
    move.w  ENTITIES_IN_CURRENT_LEVEL, d7
    sub.w   #1, d7
    
    CLEAR_LEVEL_LOOP:
    
        moveq   #0, d1
        moveq   #0, d2
        
        move.b   (a1), d1
        move.b  1(a1), d2
        
        *Border Offsets
        add.b   #1, d1
        add.b   #1, d2
        
        movem.l d7, -(sp)

        jsr     InvalTile
        
        movem.l (sp)+, d7
        
        add.l   #3, a1
        
        dbra.w  d7, CLEAR_LEVEL_LOOP
        
   rts
    


*Clears the check level buffer
*No Arguments
*Overwrites d1, a3
ClearCheckLevelBuffer:

    move.w  ENTITIES_IN_CURRENT_LEVEL, d1
    sub.w   #1, d1
    lea     LEVEL_CHECK_BUFFER, a3
    
    CLEAR_CHECK_BUFFER_LOOP:
    
        move.b  #0, (a3)+
        move.b  #0, (a3)+
        move.b  #0, (a3)+
        
        dbra    d1, CLEAR_CHECK_BUFFER_LOOP
        
   rts



*Returns the pointer to the beginning of the level in memory
*d0: Level Number
*Returns value in a4, Overwrites d0
GetLevelFromNumber:

    lea     LEVEL_ACCESS_BUFFER, a4
    lsl.l   #2, d0  ;4 byte space
    
    move.l  (a4, d0), a4
    sub.l   #1, a4
    
    rts
    
*Shows the level name underneath "Tom's Saucey Sandcastle"
*Takes the level number in as an argument in d3 and level end address in a4
*Overwrites most everything, calls BMP redraw
DisplayLevelName:

    movem.l d3/a4,-(sp)
    
    *Inval Area
    move.l  #90, d1
    move.l  #85, d2
    move.l  #20, d5
    move.l  #200, d4
    jsr     InvalPixels
    
    movem.l (sp)+, d3/a4
    
    *Set Up Test
    move.l  #LEVEL_NAME_POSITION, d1
    move.b  #SET_CURSOR_POSITION_TRAP, d0
    TRAP    #15
    
    move.l  #WATER_COLOR, d1
    move.l  #LEVEL_DISPLAY_FONT, d2
    move.   #SET_FONT_PROPERTIES, d0
    TRAP    #15
    
    move.l  #WHITE, d1
    move.b  #SET_FILL_COLOR, d0
    TRAP    #15
    
    *Load the name length
    moveq   #0, d1
    lea     LEVEL_NAME_LENGTHS, a0
    move.b  (a0, d3), d1
    
    *Move End Pointer back to the beginning of level name
    sub.l   d1, a4
    
    
    ;add.b   #1, d1                          ;Correct Length
    move.l  a4, a1                          ;Setup Trap
    move.b  #PRINT_STRING_WITH_LENGTH, d0
    TRAP    #15

    *Correctly align pointer to end of level data
    sub.l   #1, a4
    
    rts
    

*Data
ENTITIES_IN_CURRENT_LEVEL:      dc.w    0
CURRENT_LEVEL_BUFFER:           dcb.b   MAP_WIDTH*MAP_HEIGHT,$FF
CURRENT_LEVEL_BUFFER_END
LEVEL_CHECK_BUFFER:             dcb.b   MAP_WIDTH*MAP_HEIGHT*3,0
LEVEL_ACCESS_BUFFER:            dc.l    LEVEL_0_END,LEVEL_1_END,LEVEL_2_END,LEVEL_3_END,LEVEL_4_END
LEVEL_NAME_LENGTHS:             dc.b    10,16,11,11,3        ;Note that these lengths include the LeftMostXCoordByte

*Intro Level
Level_0:

	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $08, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $08, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $04, $FF, $00, $FF, $04, $FF, $08, $FF, $FF, $00, $FF, $FF 
	dc.b 	$00, $00, $00, $FF, $04, $00, $00, $FF, $08, $FF, $00, $04, $00, $FF
	
	dc.b    'The Basics'
	
	*The left most byte on the bottom row
	dc.b    0
	
LEVEL_0_END


*One Block Rotate Level
Level_1:

	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $04, $FF, $04, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $00, $04, $00, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $04, $04, $04, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $00, $00, $04, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $04, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF
	
	dc.b    'One Block Wonder'
	
	*The left most byte on the bottom row
	dc.b    5
	
LEVEL_1_END

*Pixel Ninja Level
Level_2:

	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $04, $FF, $04, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $04, $04, $04, $04, $04, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $04, $04, $04, $08, $04, $08, $08, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $04, $08, $08, $08, $08, $00, $04, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $08, $00, $00, $04, $00, $04, $00, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $04, $08, $08, $08, $08, $08, $08, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $08, $08, $08, $08, $08, $08, $08, $08, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $FF, $FF
	
	dc.b    'Pixel Ninja'
	
	*The left most byte on the bottom row
	dc.b    2
	
LEVEL_2_END

*Cat Level
Level_3:

	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $04, $FF, $FF, $FF, $FF, $FF, $04, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $FF, $04, $00, $FF, $FF, $FF, $00, $04, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $00, $00, $00, $FF, $FF, $FF, $00, $00, $00, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $00, $00, $04, $08, $04, $08, $04, $00, $00, $FF, $FF 
	dc.b 	$FF, $04, $04, $08, $08, $08, $00, $00, $00, $08, $08, $08, $04, $04 
	dc.b 	$FF, $04, $04, $08, $08, $08, $08, $04, $08, $08, $08, $08, $04, $04
	
	dc.b    'Peeking Cat'
	
	*The left most byte on the bottom row
	dc.b    1
	
LEVEL_3_END

*Tom Level
Level_4:

	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $04, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b 	$FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF
	dc.b 	$FF, $FF, $FF, $08, $08, $00, $04, $00, $04, $00, $08, $08, $FF, $FF
	dc.b 	$FF, $FF, $FF, $08, $08, $00, $04, $00, $04, $00, $08, $08, $FF, $FF 
	dc.b 	$FF, $FF, $08, $08, $08, $00, $00, $00, $00, $00, $08, $08, $08, $FF
	dc.b 	$FF, $FF, $08, $08, $08, $00, $00, $00, $00, $00, $08, $08, $08, $FF
	dc.b 	$FF, $FF, $08, $00, $00, $00, $04, $04, $04, $00, $00, $04, $08, $FF
	dc.b 	$FF, $FF, $08, $04, $08, $00, $04, $04, $04, $00, $08, $00, $08, $FF
	dc.b 	$FF, $FF, $08, $08, $08, $00, $04, $04, $04, $00, $08, $08, $08, $FF 
	dc.b 	$FF, $FF, $08, $08, $08, $00, $04, $04, $04, $00, $08, $08, $08, $FF
	dc.b 	$FF, $FF, $08, $08, $08, $00, $04, $04, $04, $00, $08, $08, $08, $FF 
	dc.b 	$FF, $FF, $08, $08, $08, $00, $00, $00, $00, $00, $08, $08, $08, $FF 
	dc.b 	$FF, $FF, $08, $08, $08, $00, $08, $08, $08, $00, $08, $08, $08, $FF 
	dc.b 	$FF, $FF, $08, $08, $08, $00, $08, $08, $08, $00, $08, $08, $08, $FF 
	dc.b 	$FF, $FF, $08, $08, $08, $00, $08, $08, $08, $00, $08, $08, $08, $FF 
	dc.b 	$FF, $FF, $08, $08, $04, $00, $08, $08, $08, $00, $04, $08, $08, $FF
	
	dc.b    'Tom'
	
	*The left most byte on the bottom row
	dc.b    2
	
LEVEL_4_END dc.b 0





























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
