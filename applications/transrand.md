# Translating Randomizer

The translating Randomizer randomly alters MIDI note numbers, program changes or velocity within a selectable range and in real time. It can also convert MIDI channel messages from one type to another.

Use it as a performance tool to create unusual soundscapes, add a real time pan or balance control to your keyboard, alter drum note velocities to add variety, convert aftertouch into pitch and volume changes, or just derive ideas from the happy accidents you create.

*Mouse over the buttons, LEDs, and potentiometer to see what they do.*
![hotfront2](../images/hotfront2.png) **HOW DO I...**

**...SET THE RECEIVE/RETRANSMIT CHANNEL?**
Press the SETUP CHAN key. The MIDI channel for both receiving and retransmitting messages is set using the +/- keys and/or the VALUE fader. The range of MIDI channels is: 1-16, ALL or NONE.

**...CHOOSE THE MODE OF OPERATION?**
Press the SETUP MODE key. The processor function is selected using the +/- keys. The available modes are:
Mode Description
--------------------------------------------------------------
0 Translating randomizer OFF
1 Randomize note numbers
2 Randomize velocity values
3 Randomize program change values
4 Translate channel aftertouch to negative bend
5 Translate channel aftertouch to positive bend
6 Translate channel aftertouch to volume
7 Translate pitch bend to pan
8 Translate pitch bend to balance
9 Translate modulation wheel to channel aftertouch

Mode 1 randomizes notes numbers received in Note On messages only. Therefore, most retransmitted notes will not have a corresponding Note Off message. Voices should be chosen with this in mind (e.g. use voices with natural decay).

Modes 4-6 and 9 use channel aftertouch only.

**...CONTROL THE DEGREE OF EACH EFFECT?**
Press the SETUP DEG key. The degree of each effect can be set using the +/- keys and/or the VALUE fader. The "degree" is used to modify messages, as follows:
Mode Description
------------------------------------------------------------
1-3 Sets window of possible values centered on the received value, with wraparound.

Mode 1 - Example A: Note=50 is received with Degree=31. The transmitted note will be a random number between 35-66.

Mode 1 - Example B: Note=110 is received with Degree=63. The transmitted note will be a random number between 79-127, or 0-14 (due to wraparound...).

4-5 Sets the degree of damping. The starting pitch bend value is 64. Therefore, data are divided by the value of:

\[(Degree+1)/2\], where Degree\>1

When Degree=0 or 1, the data are divided by 2. After dividing, the data are subtracted (Mode 4) or added (Mode 5) to the starting pitch bend value of 64.

6 Sets the minimum transmitted volume value

7-8 Sets the degree of damping. The data are first divided by \[Degree+1\]. The full range of new values is then centered around 64. The bend wheel center indent position corresponds to the center pan (Mode 7) or equal balance (Mode 8) position.

9 Sets degree of damping. The data are divided by \[Degree+1\] before being retransmitted.

**LCD Screen:**

![transran](../images/transran.gif)

The cursor arrow points to the parameter that will be modified by the +/- keys and VALUE fader.

\| CH MODE DEGREE\| where nnnn=1-16,"NONE" or
\|nnnn b ccc \| "ALL ", ccc=0,1,3,7,15,31,63
or 127, b=0-9
