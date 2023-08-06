
*-----------------------------------------------------------
* Title      :  Sandbox
* Written by :  Joe Simopoulos
* Date       :  5/31/2023
* Description:  Main File
*-----------------------------------------------------------

*-----------------------------------------------------------
* Controls: 
*           Left Mouse:     Drop Block/Select Block
*           Right Mouse:    Rotate Block
*           A Key:          Change Selected Block
*           D Key:          Change Selected Block 
*
*Game:
*           The goal is to match the Tom's Saucey Sandcastle, as
*           displayed on the left. Drop the blocks in your Mid-ass
*           space to the right. Once the sand castles match, a new
*           level will automatically load. Once all five levels are 
*           are completed, you will be rewarded. It is worth it, I promise.
*-----------------------------------------------------------

    
    INCLUDE "Global Macros.X68"

    ORG    $1000
    
START:                 

    *Init Game State
    jsr     InitializeDrawManager
    jsr     InitializePhysicsManager
    jsr     InitializeRandomNumber
    
PRE_TITLE_SCREEN:

    jsr     DrawLoadingScreen
    
    lea     TITLE_SCREEN_BMP, a0
    jsr     DrawBackground
   
    jsr     SwapBuffers
    
TITLE_SCREEN:

    jsr     GetInput
    
    move.b  MOUSE_LEFT_CLICK, d0
    beq     TITLE_SCREEN
    
    move.l  #START_BOUNDING_BOX, d0

    jsr     CheckBoundingBox            ;Returns bounding box state in d7

    tst.b   d7                      
    beq     TITLE_SCREEN            

    *Otherwise, Game time.
    jsr     DrawLoadingScreen
    
    lea     GAME_BG_BMP,a0
    jsr     DrawBackground
    
    move.l  #0, d0
    jsr     LoadLevel
    
    jsr     UpdateBlockIndicator
    
    jsr     SwapBuffers
    
    
GAME_LOOP:
        
    jsr     GetDeltaTime
    jsr     GetInput
    jsr     UpdatePhysicsEntities
    jsr     UpdateGameState
    jsr     DrawGame
  
    bra.s   GAME_LOOP
    
GAME_FINISHED:
    
    jsr     DrawLoadingScreen
    
    lea     PRE_END_SCREEN_BMP, a0
    jsr     DrawBackground
    
    jsr     SwapBuffers
    
    GAME_FINISHED_LOOP:
    
        jsr     GetInput
        
        move.b  MOUSE_LEFT_CLICK, d0
        beq     GAME_FINISHED_LOOP
        
    jsr     DrawLoadingScreen
    
    lea     END_SCREEN_BMP, a0
    jsr     DrawBackground
    
    jsr     SwapBuffers
    
    
 SIMHALT             ; halt simulator
    

*Imported Files 
    INCLUDE "RandomNumbers.X68"
    INCLUDE "Game State.X68"
    INCLUDE "Game State Log.X68"
    INCLUDE "Helpers.X68"
    INCLUDE "Actions.X68"
    INCLUDE "Block.X68"
    INCLUDE "Selected Tile Display.X68"
    INCLUDE "Input Handling.X68"
    INCLUDE "Draw Calls.X68"
    INCLUDE "Entity Manager.X68"
    INCLUDE "Draw Manager.X68"
    INCLUDE "Linked List.X68"
    INCLUDE "Stack.X68"
    INCLUDE "Physics Manager.X68"
    INCLUDE "Map.X68"
    INCLUDE "Bounding Box.X68"
    INCLUDE "Level.X68"
    INCLUDE "Bitmap.X68"
    
    

    END    START        ; last line of source






























































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
