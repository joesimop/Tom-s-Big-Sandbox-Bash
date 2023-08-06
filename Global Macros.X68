*-----------------------------------------------------------
* Title      :  GLOBAL MACROS
* Written by :  Joe Simopoulos
* Date       :  5/31/2023
* Description:  Contains important values to be used by
*               the whole progam.
*-----------------------------------------------------------

FP_SPACE                     EQU 8

TILE_SIZE    EQU 20
TILE_SIZE_FP EQU TILE_SIZE<<FP_SPACE

*TRAP COMMANDS
GET_WINDOW_DIMENSIONS_TRAP   EQU 33
SET_PEN_COLOR                EQU 80
SET_FILL_COLOR               EQU 81
DRAW_LINE                    EQU 84
MOUSE_READ                   EQU 61
PRINT_NUM                    EQU 3
PRINT_ASCII                  EQU 6
DRAW_RECT                    EQU 87
DOUBLE_BUFFER_MODE           EQU 17
DRAW_MODE_TRAP               EQU 92
SWAP_BUFFERS_TRAP            EQU 94
CLEAR_SCREEN_TRAP            EQU 11
SET_CURSOR_POSITION_TRAP     EQU 11
DELTA_TIME_TRAP              EQU 8
KEY_INPUT_TRAP               EQU 19
PRINT_STRING                 EQU 10
PRINT_STRING_WITH_LENGTH     EQU 1
SET_PEN_WIDTH                EQU 93
SET_FONT_PROPERTIES          EQU 21

*Colors
WHITE                        EQU $00FFFFFF
RED                          EQU $000000FF
GREEN                        EQU $0000FF00
BLUE                         EQU $00FF0000
BLACK                        EQU $00000000
TRANSPARENT                  EQU $A0000000
SAND_COLOR                   EQU $0080D2E2
STONE_COLOR                  EQU $00808080
WATER_COLOR                  EQU $00B85E00
BLOCK_INDICATOR_COLOR        EQU RED

*Register savers
ALL_REG                      REG d0-d7/a0-a6
ALL_DATA_REG                 REG d0-d7
ALL_DATA_REG_X6              REG d0-d5,d7
POS_REGS                     REG d1-d2/a2



*Entity Ids
SAND                         EQU 0
STONE                        EQU 4
WATER                        EQU 8

*Block Ids
L_BLOCK                      EQU $00
ZIG_ZAG_BLOCK                EQU $01
LONG_BLOCK                   EQU $02
T_BLOCK                      EQU $03
SQUARE_BLOCK                 EQU $04
NUM_BLOCKS                   EQU 4          ;Note: this is -1 for proper indexing calcs

*MISC
LEVEL_DISPLAY_FONT           EQU $01090005
LEVEL_NAME_POSITION          EQU $00000C06
MAP_WIDTH                    EQU 14
MAP_HEIGHT                   EQU 18
MAP_SIZE                     EQU MAP_WIDTH*MAP_HEIGHT
CLEAR_SCREEN_MAGIC_VALUE     EQU $FF00
LF                           EQU $0A
CR                           EQU $0D






























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
