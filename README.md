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
| [`firmware/`](firmware/) | 34 firmware images, the shared BIOS library, and assembly source for 33 tools |
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

## Firmware and source

The hardware is built around the **Motorola 68HC705C8**. Every tool runs the same
shared BIOS with a different application layered on top, assembled with the
2500AD 6805 assembler.

The original development tree was recovered in October 2026 and is included here
in full: the 33-tool application source, the complete BIOS library, and the
build entry point that shows exactly how an image was produced. See
[`firmware/README.md`](firmware/README.md) for the build process and a module-by-module
guide, and for the tool-to-source index.

Two gaps remain. No source survives for `01286-sw.s19`, which the original site
published and nothing in the recovered tree refers to. And the 2500AD assembler
itself is not included, so the archive has not been rebuilt from source — the
`.s19` images here are the originals that shipped. If you have either, or any
MIDItools material not preserved here, please [open an issue](../../issues).


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
