# Universal Transmitter

The Universal Transmitter transmits any one, two, or three byte message to receiving devices. You select the byte to be programmed with button one, two or three, then use the fader or the up/down keys to program the byte. Button six sends the message. Button 5 clears the message and button 7 inactivates any selected byte.

The Universal Transmitter is a great utility program. Use it to troubleshoot a device that's not responding, send SysEx messages, reset controller values, or send an All Notes Off panic message.

*Mouse over the buttons, LEDs, and potentiometer to see what they do.*
![hotfront2](../images/hotfront2.png) **HOW DO I...**

**...CONFIGURE A MESSAGE?**
A byte number is selected using the SELECT BYTE keys:
1, 2 or 3. The hex value of the selected byte is programmed using the +/- keys and/or the VALUE fader. The LCD gives the byte hex values.

**...INACTIVATE BYTES?**
After selecting the desired byte number, it can be inactivated by pressing the NULL key. Inactive bytes (indicated in the LCD by "--") are not transmitted. Pressing the +/- keys or moving the VALUE fader reactivates the byte.

**...SEND THE MESSAGE?**
Press the MESSAGE SEND key. Activated bytes are transmitted. The TRANSMITTING LED will flash. The message is merged with incoming MIDI data.

**...CLEAR THE MESSAGE?**
Press the MESSAGE CLEAR key. All three bytes are reset to their inactive state.

LCD Screen:

![univtrans](../images/univtrans.gif)

When configuring a message,

\|1:hh 2:hh 3:hh\| where hh=00H-FFH or "--",
\|Program Byte a \| a=1,2 or 3

When the CLEAR key is pressed:

```
|1:-- 2:-- 3:--|
|Message Reset...|
```
