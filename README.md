# Antediluvian Chip8

A Chip8 emulator to get some practice in for making such things.

## Zig Version
Builds with zig 0.12.0

## Resources
chip8.com

Under resources/
* C8TECH10.HTM provdies some details on how the instructions should behave
* c8roms/ some chip8 roms to test with.
    * Guess writen by David Winter

### CHIP8 OpCodes
http://octo-ide.com

  N - is a nubmer between 0 and 15
 NN - is a number between 0 and 255
NNN - is an address between 0 and 4095
 vx and vy are registers (0-F)
  i is the memory index register
Instructions in marked rows may modify the vF register

-----------------------------------
Code | Octo Instruction | Comment |
-----------------------------------
00E0 | Clear            | |
00EE | return           | Exit a subroutine |
0NNN | Sys Addr         | jump to addr |
1NNN | jump NNN         | |
2NNN | NNN              | Call a subroutine |
3XNN | if vx != NN then | |
4XNN | if vx == NN then | |
5XY0 | if vx != vy then | |
6XNN | vx = NN          | |
7XNN | vx += NN         | |
8XY0 | vx = vy          | |
8XY1 | vx |= vy         | bitwise OR |
8XY2 | vx &= vy         | bitwise AND |
8XY3 | vx ^= vy         | bitwise XOR |
8XY4 | vx += vy         | vf = 1 on carry |
8XY5 | vx -= vy         | vf = 0 on borrow |
8XY6 | vx >> vy         | vf = old least significant bit |
8XY7 | vx =- vy         | vf = 0 on borrow |
8XYE | vx << vy         | vf = old most significant bit |
9XY0 | if vx == vy then | |
ANNN | i = NNN          | |
BNNN | jump0 NNN        | jump to address NNN + v0 |
CXNN | vx = random NN   | Random number 0-255 anded with NN, then stored in vx |
DXYN | sprite vx vy N   | vf = 1 on collision |
EX9E | if vx -key then  | Is a key not pressed? |
EXA1 | if vx key then   | Is a key pressed? |

FX07 | vx = delay       | |
FX0A | vx = key         | wait for keypress |
FX15 | delay = vx       | |
FX18 | buzzer = vx      | |
FX1E | i += vx          | |
FX29 | i = hex vx       | set i to a hex character |
FX33 | bcd vx           | decode vx into binary-coded decimal |
FX55 | save vx          | save v0-vx to i through i+x |
FX65 | load vx          | load v0-vx from i through i+x |
    
