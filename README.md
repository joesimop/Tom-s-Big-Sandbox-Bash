# Tom-s-Big-Sandbox-Bash
A Z80 assembly game complete with physics, collision, haiku's, and Tom himself!  

This was a game that I made during my internship at Iron Galaxy Studios.  
All systems and concepts were designed by me, for better or worse.  
All teaching _and_ goofing around was done by Tom Carbone.  
All help was from Utasb Das.  

## Setup
To play the game, you need an emulator, and I used a program called Easy68k.  
It is only available for Windows atm, here is the [download link]([url](http://www.easy68k.com/files/SetupEASy68K.exe)http://www.easy68k.com/files/SetupEASy68K.exe).

For non-Windows users, choose any other emulator, however, it is worth noting that
Easy68k allows for two-byte alignment. I am aware some Z80 systems, like the Sega Genisis, had four-byte alignment.
My program definitely relies on two-byte alignment, if it doesn't run, that is most likely why.

## Playing the Game
Simply open *Sandbox.X68* (my main file) in your emulator and run the program.  
In Easy68k this is achieved through F9 or the little play button on the top toolbar.  

The goal is to match Tom's Saucey Sandcastle on the left side of the screen by dropping
the available blocks at the bottom of the screen. There are five levels, see if you can
beat all of them!

## Controls
* ***Select Block***: A and D keys, or click the boxes above the respective block.
* ***Drop Block***: Left Click
* ***Rotate Block****: Right Click
* ***Undo Move***: R key
