# Landing page

The single page served at [electrovoce.com](https://electrovoce.com) and
[miditool.com](https://miditool.com). It replaced the original MIDItools site in
October 2026, after the site's content was preserved in this repository.

`index.html` is self-contained: the logo and the front-panel photograph are
embedded in the file itself. Deploying is a matter of copying that one file into
the document root of each domain — no build step on the server, no other files,
no dependencies beyond a webfont.

## The display

The page opens with the power-on greeting the hardware itself showed when you
switched it on: a MIDI connector streaming data that spells out "MIDItools", one
character at a time, with the final "s" walking into place.

Its twenty-one frames and their 100 ms timing are transcribed exactly from
[`firmware/bios/GREETING.ASM`](../firmware/bios/GREETING.ASM), rev 1.0, dated
29 August 1993. The display is drawn as a 16x2 character grid, the geometry of
the real module.

## Editing

Edit [`src/template.html`](src/template.html), never `index.html` — the latter is
generated and will be overwritten. Then:

```
python3 src/build.py
```

That inlines `src/logo.jpg` and `src/panel.jpg` and rewrites `index.html`.

The palette is the original site's own: black, white text, and `#DFB259` for
links, hovering to `#99CCFF`. The logo is the original MIDItools banner; the
photograph is the rack-mount front panel.
