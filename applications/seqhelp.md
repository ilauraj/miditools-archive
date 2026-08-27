# Sequencer Helper

The Sequencer Helper converts a sequencer's output into useful MIDI processes such as volume fades, transposition and controller resets.

Use the Sequencer Helper to selectively transpose to a vocalist's range, change all velocities, change volume, fade in and out, or create a panic or mute button.

*Mouse over the buttons, LEDs, and potentiometer to see what they do.*
![hotfront2](../images/hotfront2.png) **HOW DO I...**

**...TRANSPOSE THE KEY SIGNATURE OF MY SEQUENCE?**
Press the TRANSPOSE KEY+ key to transpose the song 1/2 step higher. Press the TRANSPOSE KEY- key to transpose the song 1/2 step lower. The overall offset is given in the LCD. The KEY OFFSET LED lights for nonzero offsets.

Key transposition can be disabled for individual channels (see Sequencer Setup) to leave certain tracks unaltered.
**
...ADD AN OFFSET TO ALL SEQUENCE VELOCITY VALUES?**
Press the TRANSPOSE VEL+ key to add 1 to all note velocities. Press the TRANSPOSE VEL- key to subtract 1 from all note velocities. The overall offset is given in the LCD. The VEL OFFSET LED lights for nonzero offsets.

**...MUTE PLAYBACK OF MY SEQUENCE WITHOUT STOPPING IT?**
Press the MUTE key. Press the key again to restore playback. The MUTE LED lights when notes are muted. In addition, a message appears in the LCD when notes are being muted.

**...CONTROL THE OVERALL VOLUME?**
The VOLUME fader acts as a Master Volume control. All instrument voices are affected. Volume is scaled according to fader position. The VOLUME LED lights for all non-100% settings. Volume data are scaled from any received Volume data (Controller 7). In the absence of received Volume data, the control defaults to a value of 127 (maximum volume).

This fader allows controlled fade ins and outs.
**
...RESET THE LOCAL DEVICE PARAMETERS?**
Press the LOCAL RESET key to reset the following:

KEY OFFSET -----\> 0
VEL OFFSET -----\> 0
MUTE -----------\> OFF
VOLUME ---------\> 100%
KEY TRANSPOSE ---\> all channels enabled

**...RESET ALL CONTROLLERS?**
Pressing the RESET R-CTL key resets controllers 0-95 on all channels to a value of zero, except for the following special cases:

VOLUME (Ctl 7) -----\> 127
PAN (Ctl 10) -------\> 64
BALANCE (Ctl 8) ----\> 64

The Channel Mode Message, RESET ALL CONTROLLERS
(Controller 121), is also transmitted on each channel.

In addition to controller messages, the following parameters are restored to the indicated values:

PITCH BEND ---------\> MSB=64/LSB=0 (no bend)
CHANNEL AFTERTOUCH -\> 0
KEY AFTERTOUCH -----\> 0 (all notes)

**...TURN OFF ALL NOTES?**
Pressing the RESET PANIC key sends the following messages on all channels:

ALL NOTES OFF (Ctl 123 - Channel Mode Message) NOTE OFF (note numbers 0-127)

**...SET UP MY SEQUENCE FOR PROPER OPERATION?**
For proper operation of the master VOLUME fader, the sequencer should send the desired nominal volume settings (Controller 7) on each MIDI channel used.

The user can disable key transposition on channels 1-7 and 9-15 by sending controller messages as follows:

Controller \#48 - enables/disables channels 1-7
----------------------------------------------
Data Value ;
```
|bit 7|bit 6|bit 5|bit 4|bit 3|bit 2|bit 1|bit 0|
| 0 |ch 7 |ch 6 |ch 5 |ch 4 |ch 3 |ch 2 |ch 1 |
```
Controller \#16 - enables/disables channels 9-15
-----------------------------------------------
Data Value
```
|bit 7|bit 6|bit 5|bit 4|bit 3|bit 2|bit 1|bit 0|
| 0 |ch 15|ch 14|ch 13|ch 12|ch 11|ch 10|ch 9 |
```
A bit value of "1" disables key transposition on that channel.

**LCD Screen:**

![seqhelp](../images/seqhelp.gif)


\|Keys ddd Vel ddd\| where s="+" or "-", ddd=0-127,
\| message \| message="Loc Reset - WAIT",
"Ctl Reset - WAIT",
" PANIC! - WAIT " or "MUTE ON"
