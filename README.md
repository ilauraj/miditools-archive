# MIDItools Archive

A preserved archive of the documentation for **MIDItools®**, a line of MIDI
hardware kits produced by Electrovoce, LLC between 2001 and 2007. The products
are long discontinued; this repository exists so that the application notes,
manuals, schematics and firmware remain available.

MIDItools kits were used in personal studios and installations, and were paired
with the book *Digital Projects for Musicians* by Craig Anderton, Bob Moses and
Greg Bartlett to teach electronics and MIDI principles in classrooms. Two custom
MIDItools applications ran continuously in the Sound Lab at Seattle's Experience
Music Project.

## Contents

| Directory | |
|---|---|
| [`applications/`](applications/) | 26 application notes, each describing one MIDItool function |
| [`pages/`](pages/) | 7 pages from the original site |
| [`manuals/`](manuals/) | 17 PDF assembly and user manuals |
| [`firmware/`](firmware/) | 26 firmware images (Motorola S-record) and assembly source |
| [`images/`](images/) | 74 schematics, block diagrams, LCD readouts and product photos |

## Application notes

- [64 or 128 Output Driver Board](applications/64opd.md)
- [Channel Filter](applications/chanfilt.md)
- [Channel Mapper](applications/chanmap.md)
- [Channel Message Transmitter](applications/chanmsg.md)
- [Chord Player](applications/chordplr.md)
- [Controller Mapper](applications/contmap.md)
- [Controller Thinner](applications/contthin.md)
- [Custom Instrument](applications/custom.md)
- [CV-to-MIDI](applications/cvmidi.md)
- [Data Filter](applications/datafilt.md)
- [Data Monitor](applications/datamon.md)
- [Quad Ektagraphic Controller](applications/ektagraph.md)
- [Keyboard Mapper](applications/keymap.md)
- [MIDItools Messenger](applications/mtm.md)
- [Multi-Effector](applications/multeff.md)
- [MIDI Patch Bay](applications/patch.md)
- [Programmable Controllers](applications/progcont.md)
- [Relay Driver](applications/relaydrv.md)
- [Sequencer Helper](applications/seqhelp.md)
- [Sequencer Remote Control](applications/seqremote.md)
- [MIDI Show Controller](applications/showcont.md)
- [System Exclusive Folder](applications/sysex.md)
- [Tap Tempo Transmitter](applications/taptempo.md)
- [Tiny Tech](applications/tinytech.md)
- [Translating Randomizer](applications/transrand.md)
- [Universal Transmitter](applications/universal.md)

## Site pages

- [Applications](pages/apps.md)
- [Custom MIDI Design Solutions](pages/custom.md)
- [Downloads](pages/downloads.md)
- [MIDItools](pages/edu.md)
- [MIDItools](pages/tools.md)
- [User Projects](pages/userproj.md)

## Missing: assembly source

The hardware is built around the Motorola 68HC705C8. Compiled firmware is
included for all 25 tools, but **assembly source survives for only one** — the
Universal Transmitter (`00003-sw.asm`). Only that single `.asm` file was ever
published; the rest were kept locally and the originals have since been lost.

That surviving file also depends on a **shared MIDI runtime library**, referenced
through macros such as `IGNORE_IRQ_SWI_SPI` and `MIDI_ISR_LOOPBACK`. The library
was maintained separately and is not part of this archive either.

**I am still looking for both.** If you worked with MIDItools kits, corresponded
with Electrovoce, or have old backups from that era, I would be glad to hear from
you — please [open an issue](../../issues). Any of the following would be
valuable:

- Assembly source (`.asm`) for any tool other than `00003`
- The shared MIDI runtime library or its include file
- Build scripts, makefiles, or assembler configuration from the toolchain
- Any MIDItools documentation not already preserved here

Recovering the commented source would be far more useful than disassembly, which
can reproduce working code but not the original comments, labels or structure.

## About this archive

Converted from the original HTML site. Text became Markdown; manuals, firmware,
schematics and diagrams were kept in their original formats. Firmware files were
restored to their proper `.s19` extensions — the live site served them renamed to
`.txt` so that browsers would display rather than download them.

Diagrams that the original site opened in JavaScript popup windows are linked
inline here instead. Ordering and contact pages were omitted, as the products are
no longer sold, and email addresses belonging to third parties were removed.

## License

© 2001–2007 Electrovoce, LLC. See [LICENSE](LICENSE).
