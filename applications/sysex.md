# System Exclusive Folder

This MIDItools® stores up to 256 bytes of system exclusive data in non-volitile memory for storage. Use the System Exclusive folder to back up synth presets or undo edits to patches.

*Mouse over the buttons, LEDs, and potentiometer to see what they do.*
![hotfront2](../images/hotfront2.png) **HOW DO I...**

**...CAPTURE SYSTEM EXCLUSIVE DATA?**
Press the CAP(ture) key. The next System Exclusive message is captured. The DATA OVERFLOW LED lights if the folder overflows.
**
...REVIEW THE CONTENTS OF THE FOLDER?**
The contents of the folder can be reviewed at any time by using the +/- keys and/or VALUE fader to select the desired byte. Data are presented in the LCD.
**
...RETRANSMIT STORED DATA?**
Press the SEND key. The contents of the folder are transmitted.

**...CLEAR THE FOLDER?**
Press the CLEAR key. The contents of the folder are cleared and all parameters are reset.
**
...MONITOR THE STATUS OF THE FOLDER?**
The DATA PRESENT LED is lit when data is present in the folder. The length of the message in the folder is indicated in the LCD.

**...SAVE THE CONTENTS OF THE FOLDER?**
Data are saved automatically to non-volatile EEPROM.

**LCD Screen:**

When reviewing data,

\|Byte:bbb Data:hh\| where bbb=1-256 or "-",
\|Msg Length: ccc \| hh=00H-FFH or "-", ccc=0-255

When the CAP key is pressed,

```
|CAPTURING SYSEX |
| ...waiting |
```
When the SEND key is pressed,

```
|SENDING... |
| |
```
When the CLEAR key is pressed,

```
|CLEARING... |
| |
```
