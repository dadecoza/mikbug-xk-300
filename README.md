#  MIKBUG
## for the Intext XK-300 CPU trainer
This ROM should be installed in the user ROM socket U13 and will give you a 300baud UART interace that you can use with a FTDI adapter or a MAX232 module with a real serial terminal.

### Prerequisites 
* 2K ROM (2716) User ROM
* 1K RAM (2x MCM2114) User RAM

**Software**
* srecord tools
* 6800 assembler (https://github.com/JimInCA/motorola-6800-assembler)

### Memory Map
| Address | Usage |
|---|---|
| F800-FFFF | D5BUG mirror
| F000-F7FF | D5BUG Operating System
| E800-EFFF | This MIKBUG ROM (User ROM)
| - | Reserved
| E484-E487 | System PIA
| E480-E483 | User PIA (Serial IO bit-bang)
| E400-E483 | System RAM
| E000-E3FF | 1K User RAM
| 0080-DFFF | External BUS
| 0000-007F | Zero page used by MIKBUG

### User PIA connector pinouts
```
                U14
          +-------------+
          |o 1      24 o| +5v
TX (PA7)  |o 2      23 o|
RX (PB0)  |o 3      22 o|
          |o 4      21 o|
          |o 5      20 o|
          |o 6      19 o|
          |o 7      18 o|
          |o 8      17 o|
          |o 9      16 o|
          |o 10     15 o|
          |o 11     14 o|
          |o 12     13 o| GND
          +-------------+

```

### Terminal configuration
* Baud: 300
* Stop Bits: 1
* Parity: N
* Local echo / Half duplex: On

### Entering MIKBUG
Using the keypad enter E800 and press the `GO` button. The display will go blank and you will be presented with the `*` prompt on the terminal.

### Loading Programs into User RAM
There are four options to load programs into user RAM:

1. **Using the Keypad and 7-Segment Display**  
   Manually type the program using the keypad and observe the 7-segment display.

2. **Loading from Tape**  
   Press the `FS` key followed by the `P/L` key. The display will go blank while the program is loading. Once the loading is complete, the `-` prompt will appear on the 7-segment display.

3. **Typing the Program Using MIKBUG**  
   - At the `*` prompt, type the `M` key followed by the starting address (e.g., `E000`).  
   - The monitor will display the value at the specified address.  
   - Type the space key followed by the new hex value. The monitor will automatically move to the next address.  
   - Repeat this process for all addresses.  
   - When you finish entering the program, press the space key at the last address, followed by the Enter key, to return to the `*` prompt.

4. **Loading Over the Serial Terminal**  
   - At the `*` prompt in MIKBUG, press the `L` key.  
   - MIKBUG will wait for the file to be sent in S-record format.  
   - Once the file is successfully loaded, you will be returned to the `*` prompt.  
   - Be generous with the character TX delay in your terminal emulator; a 20ms delay should be safe.

### Running a Program from User RAM
Once the program is loaded into user RAM, specify the starting address by loading the high byte into `$0048` and the low byte into `$0049`.

1. At the `*` prompt, type `M` followed by `0048`. The monitor will display the value stored at that address.
2. To change the value, press the space key followed by the high byte (e.g., `E0`). The monitor will save the value and move to the next address.
3. At the next address, press the space key followed by the low byte (e.g., `00`). The monitor will again move to the next address.
4. Finally, press the space key followed by the Enter key to return to the `*` prompt.

You can now jump to the specified address by typing the `G` key.

Example:
```
*M 0048
*0048 3A  E0
*0049 AE  00
*004A 2E  

*G
HELLO WORLD
```

### Handy sub-routines
| Address | Description |
|---|---|
|E003| OUTEEE: Write the character in the `A` accumulator to the terminal display.
|E006| INEEE: Wait for a single character from the terminal and store it in the `A` accumulator.
|E009| PDATA1: Print data at the location stored in the `X` register and loop until $04 is reached.
|E00C| OUTHR: Output HEX right BCD digit.
|E00F| OUTHL: Output HEX left BCD digit.
|E012| OUT2HS: Output 2 HEX digits.


### Example program
```
    ORG $E000
PDATA EQU $E809
START:
    LDX #DATA
    JSR PDATA 
END BRA START

DATA	FCB $0A, $0D
        FCC "HELLO WORLD" 
        FCB $04
```