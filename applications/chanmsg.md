# Channel Message Transmitter

The Channel Message Transmitter transmits an assortment of useful MIDI channel messages and allows you to change their values in REAL TIME.

Use the Channel Message Transmitter as a volume fader or control for pitch bend, pan, data entry, mod wheel, breath controller...

*Mouse over the buttons, LEDs, and potentiometer to see what they do.*
![hotfront2](../images/hotfront2.png)

**HOW DO I...**

<div>

**...SET THE TRANSMIT CHANNEL?**
Press the SETUP CHAN key. The MIDI transmit channel is selected using the +/- keys and/or the VALUE fader.

</div>

<div>

**...SELECT THE MESSAGE TYPE?**
Press the SETUP MSG key. The message type is selected using the +/- keys.

The following Channel Voice Message types can be selected for use:

</div>

<div>

Channel Voice Message Type
----------------------------------
Program Change
Pitch Bend
Channel Aftertouch
Modulation Wheel (Controller \#1)
Breath Controller (Controller \#2)
Foot Controller (Controller \#4)
Portamento Time (Controller \#5)
Data Entry (Controller \#6)
Main Volume (Controller \#7)
Balance (Controller \#8)
Pan (Controller \#10)
Expression (Controller \#11)

</div>

<div>

**...TRANSMIT DATA?**
Press the DATA key. MIDI messages (of the selected type) are transmitted each time the data value is modified with the +/- keys and/or the VALUE fader. The LCD gives complete message information.
Generated data are merged with incoming MIDI data.

**...READ THE DISPLAYED PITCH BEND VALUES?** Pitch bend values are transmitted in 128 discrete steps over the full range of possible values. The LCD shows this range as -64 to +63.

**LCD Screens:**

</div>

![chanmess](../images/chanmess.gif)

The cursor arrow points to the parameter that will be modified by the +/- keys and VALUE fader.

```
|CHANNEL nn| |CHANNEL nn|
|PROGRAM bbb| |PITCH BEND ppp|
```
```
|CHANNEL nn| |CHANNEL nn|
|AFTERTOUCH bbb| |MOD WHEEL bbb|
```
```
|CHANNEL nn| |CHANNEL nn|
|BREATH CTL bbb| |FOOT CTL bbb|
```
```
|CHANNEL nn| |CHANNEL nn|
|PORTAMENTO bbb| |DATA ENTRY bbb|
```
```
|CHANNEL nn| |CHANNEL nn|
|VOLUME bbb| |BALANCE bbb|
```
```
|CHANNEL nn| |CHANNEL nn|
|PAN bbb| |EXPRESSION bbb|
```
where nn=1-16, bbb=0-127, ppp=-64 to +63
