# Firmware

MIDItools hardware is built around the **Motorola 68HC705C8**, an 8-bit
microcontroller with 7.7 KB of user EPROM. Every tool in the product line runs
the same shared BIOS with a different application layered on top.

## How a tool is built

[`bios/MAIN.ASM`](bios/MAIN.ASM) is the build entry point. It `.INCLUDE`s the
BIOS modules in order, then exactly one application file, and ends by placing
the interrupt vectors — which must come last in the S-record or the Motorola EVM
rejects the image. To build a different tool, change the single application
`.INCLUDE` line.

The toolchain was the **2500AD 6805 assembler and linker, version 5.0**. That
assembler is not included here, and the archive has not been rebuilt — the
`.s19` images are the originals that shipped.

## The BIOS

| Module | |
|---|---|
| [`6805C8.ASM`](bios/6805C8.ASM) | Processor definitions, vectors, interrupt dispatch |
| [`MIDI.ASM`](bios/MIDI.ASM) | MIDI transmit and receive, queues, running status |
| [`MIDIrx.ASM`](bios/MIDIrx.ASM) | MIDI variant tuned for receive-heavy applications |
| [`MIDItx.ASM`](bios/MIDItx.ASM) | MIDI variant tuned for transmit-heavy applications |
| [`LCD.ASM`](bios/LCD.ASM) | Character LCD driver |
| [`LED.ASM`](bios/LED.ASM) | LED display and indicators |
| [`SW.ASM`](bios/SW.ASM) | Switch matrix scanning and debounce |
| [`TIMER.ASM`](bios/TIMER.ASM) | Timer interrupt and software timers |
| [`SPI.ASM`](bios/SPI.ASM) | SPI bus |
| [`ADC.ASM`](bios/ADC.ASM) | Analog-to-digital conversion |
| [`EEPROM.ASM`](bios/EEPROM.ASM) | Non-volatile parameter storage |
| [`STMACH.ASM`](bios/STMACH.ASM) | State machine framework |
| [`GREETING.ASM`](bios/GREETING.ASM) | Standard power-on LCD greeting |

The three MIDI modules are the same driver with different queue sizing; a tool
picks whichever suits its traffic. [`applications/TEMPLATE.ASM`](applications/TEMPLATE.ASM)
is the empty starting point for a new application.

## Tools

Source is organised one folder per tool. Compiled images sit in this directory,
alongside the ones the original site published.

| Tool | Source | Firmware |
|---|---|---|
| 00003 - Universal Transmitter | [`00003-universal-transmitter/`](applications/00003-universal-transmitter/) | [`00003-sw.s19`](00003-sw.s19) |
| 00004 - Channel Message Transmitter | [`00004-channel-message-transmitter/`](applications/00004-channel-message-transmitter/) | [`00004-sw.s19`](00004-sw.s19) |
| 00005 - Programmable Controllers | [`00005-programmable-controllers/`](applications/00005-programmable-controllers/) | [`00005-sw.s19`](00005-sw.s19) |
| 00006 - Tap Tempo Transmitter | [`00006-tap-tempo-transmitter/`](applications/00006-tap-tempo-transmitter/) | [`00006-sw.s19`](00006-sw.s19) |
| 00007 - Sequencer Remote Control | [`00007-sequencer-remote-control/`](applications/00007-sequencer-remote-control/) | [`00007-sw.s19`](00007-sw.s19) |
| 00008 - Data Monitor | [`00008-data-monitor/`](applications/00008-data-monitor/) | [`00008-sw.s19`](00008-sw.s19) |
| 00009 - Control Thinner | [`00009-control-thinner/`](applications/00009-control-thinner/) | [`00009-sw.s19`](00009-sw.s19) |
| 00010 - MIDI Show Controller | [`00010-midi-show-controller/`](applications/00010-midi-show-controller/) | [`00010-sw.s19`](00010-sw.s19) |
| 00011 - Channel Filter | [`00011-channel-filter/`](applications/00011-channel-filter/) | [`00011.s19`](00011.s19) |
| 00012 - Data Filter | [`00012-data-filter/`](applications/00012-data-filter/) | [`00012-sw.s19`](00012-sw.s19) |
| 00013 - Channel Mapper | [`00013-channel-mapper/`](applications/00013-channel-mapper/) | [`00013-sw.s19`](00013-sw.s19) |
| 00014 - Controller Mapper | [`00014-controller-mapper/`](applications/00014-controller-mapper/) | [`00014-sw.s19`](00014-sw.s19) |
| 00015 - Keyboard Mapper | [`00015-keyboard-mapper/`](applications/00015-keyboard-mapper/) | [`00015-sw.s19`](00015-sw.s19) |
| 00016 - Translating Randomizer | [`00016-translating-randomizer/`](applications/00016-translating-randomizer/) | [`00016-sw.s19`](00016-sw.s19) |
| 00017 - Multi-effector | [`00017-multi-effector/`](applications/00017-multi-effector/) | [`00017-sw.s19`](00017-sw.s19) |
| 00018 - Sequencer Helper | [`00018-sequencer-helper/`](applications/00018-sequencer-helper/) | [`00018-sw.s19`](00018-sw.s19) |
| 00019 - Chord Player | [`00019-chord-player/`](applications/00019-chord-player/) | [`00019-sw.s19`](00019-sw.s19) |
| 00020 - System Exclusive Folder | [`00020-system-exclusive-folder/`](applications/00020-system-exclusive-folder/) | — |
| 00021 - Custom Instrument | [`00021-custom-instrument/`](applications/00021-custom-instrument/) | [`00021-sw.s19`](00021-sw.s19) |
| 00022 - Relay Driver | [`00022-relay-driver/`](applications/00022-relay-driver/) | [`00022-sw.s19`](00022-sw.s19) |
| 00023 - MIDI Patch Bay | [`00023-midi-patch-bay/`](applications/00023-midi-patch-bay/) | [`00023-sw.s19`](00023-sw.s19) |
| 00042 - Tiny Tech | [`00042-tiny-tech/`](applications/00042-tiny-tech/) | [`00042-sw.s19`](00042-sw.s19) |
| 00130 - CV - MIDI 4+4 | [`00130-cv-midi-4-4/`](applications/00130-cv-midi-4-4/) | [`00130-sw.s19`](00130-sw.s19) |
| 00131 - Octal Relay Driver | [`00131-octal-relay-driver/`](applications/00131-octal-relay-driver/) | [`00131-sw.s19`](00131-sw.s19) |
| 00132 - Eight Pedal Custom Instrument | [`00132-eight-pedal-custom-instrument/`](applications/00132-eight-pedal-custom-instrument/) | [`00132-sw.s19`](00132-sw.s19) |
| 00134 - 2x32 Exclusive Relay Selector | [`00134-2x32-exclusive-relay-selector/`](applications/00134-2x32-exclusive-relay-selector/) | [`00134-sw.s19`](00134-sw.s19) |
| 00138 - 64 or 128 Output Driver | [`00138-64-or-128-output-driver/`](applications/00138-64-or-128-output-driver/) | [`00179-sw.s19`](00179-sw.s19) |
| 00139 - Quad Ektagraphic Projector | [`00139-quad-ektagraphic-projector/`](applications/00139-quad-ektagraphic-projector/) | [`00139-sw.s19`](00139-sw.s19) |
| 00162 - Generic Programmable Controller | [`00162-generic-programmable-controller/`](applications/00162-generic-programmable-controller/) | [`00162gen.s19`](00162gen.s19) |
| 00204 - Synthabeam II | [`00204-synthabeam-ii/`](applications/00204-synthabeam-ii/) | — |
| 00232 - MTC 7 | [`00232-mtc-7/`](applications/00232-mtc-7/) | [`mtc7.s19`](mtc7.s19) |
| 01153 - MT Sequencer | [`01153-mt-sequencer/`](applications/01153-mt-sequencer/) | [`romseq.s19`](romseq.s19), [`seqfinal.s19`](seqfinal.s19), [`seqtest.s19`](seqtest.s19) |
| 01321 - CV-to-MIDI | [`01321-cv-to-midi/`](applications/01321-cv-to-midi/) | [`01324-sw.s19`](01324-sw.s19) |

## Known gaps

- **`01286-sw.s19`** was published on the original site but no source for it
  survives, and nothing in the recovered tree refers to it.
- **Earlier revisions** of several tools existed in the development tree and are
  not reproduced here; each folder holds the shipped version.
- **`00204` (Synthabeam II)** has source but no compiled image — a note in the
  original folder pointed at a separate source-control system for the binary.
