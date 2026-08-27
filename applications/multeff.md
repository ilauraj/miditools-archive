# Multi-Effector

The Multi-Effector MIDItool provides real time data compression, limiting, noise gating, and delay functions similar to an analog effects processor. Instead of processing analog signals, the Multi-Effector processes MIDI data to acheive the same effects.

Use the Multi-Effector as a velocity compressor, velocity limiter, delay device, velocity expander or bad note eliminator.

*Mouse over the buttons, LEDs, and potentiometer to see what they do.*
![hotfront2](../images/hotfront2.png) **HOW DO I...**

**...SET THE RECEIVE/RETRANSMIT CHANNEL?**
Press the SETUP CHAN key. The MIDI channel for receiving and retransmitting messages is set using the +/- keys and/or the VALUE fader. The range of MIDI channels is: 1-16, ALL, or NONE.
**
...SET THE GATE THRESHOLD?**
Press the EFFECTS GATE key. The gate threshold is set using the +/- keys and/or the VALUE fader. All notes received with a velocity less than this threshold will not be retransmitted. The GATE LED lights when a note is being gated.

**...SET THE LIMITER THRESHOLD?**
Press the EFFECTS LIMIT key. The limiter threshold is set using the +/- keys and/or the VALUE fader. All notes received with a velocity greater than this threshold will be retransmitted with the threshold velocity. The LIMIT LED lights when a note is being limited.

**...SET THE COMPRESSION RATIO?**
Press the EFFECTS CM/EX key. The compression ratio is set using the +/- keys and/or the VALUE fader. Values for compression are found at the bottom half of fader travel (lowest 64 positions). The COMPRESS LED lights when a note velocity is being compressed.
**
...SET THE EXPANSION RATIO?**
Press the EFFECTS CM/EX key. The expansion ratio is set using the +/- keys and/or the VALUE fader. Values for expansion are found at the top half of fader travel (highest 64 positions). The EXPAND LED lights when a note velocity is being expanded.


**...SET THE DELAY PARAMETERS?**
Press the EFFECTS DELAY key. The delayed note spacing is set with the NOTE key. The range of values is: 1,2,4,8,16, or 32; corresponding to whole, half, quarter, eighth, sixteenth, or thirty-second notes.
The decay algorithm is entered with the ALG key. The available decay algorithms are:

ALG Description
-------------------------------------------------------------
0 Delay generator OFF
1 Repeat note at same velocity (endless)
2 Divide velocity by 2 until v=0
3 Divide velocity by 4 until v=0
4 Divide velocity by 8 until v=0
5 Subtract 2 from velocity until v=0
6 Subtract 4 from velocity until v=0
7 Subtract 8 from velocity until v=0
8 Subtract 16 from velocity until v=0

The delay generator affects the last note played only.

**...SET THE TEMPO OF DELAYED NOTES?**
Press the SETUP TEMPO key. The tempo, in quarter notes per minute (QPM), of delayed notes is set using the +/- keys and/or the VALUE fader. The range of tempo values is 20-255 QPM.

**...KNOW THE PROCESSING ORDER?**
Each received note flows through the effects processors in the following order:

GATE ==\> COMP/EXP ==\> LIMITER ==\> DELAY

**LCD Screen:**

![multieff](../images/multieff.gif)

When the SETUP CHAN key is pressed,

\| MULTI-EFFECTOR \| where nnnn=1-16, " ALL",
\| CHANNEL: nnnn \| or "NONE"


When the SETUP TEMPO key is pressed,

\| MULTI-EFFECTOR \| where eee=20-255
```
| TEMPO: eee |
```
When any other key is pressed,

\| GAT zz LIM DL-A\| where bbb=0-127, cc=0-63,
\| bbb cc bbb rr d\| d=0-8, zz="EX" or "CM",
rr=1,2,4,8,16, or 32

The cursor arrow points to the parameter that will be
modified by the +/- keys and VALUE fader.
