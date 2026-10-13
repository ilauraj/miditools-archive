#!/usr/bin/env python3
"""Rebuild the landing page as a single self-contained file.

Reads template.html, inlines logo.jpg and panel.jpg as data URIs, and writes
../index.html. Run after editing template.html; never edit index.html directly.
"""
import base64
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent / "index.html"


def data_uri(name: str) -> str:
    return "data:image/jpeg;base64," + base64.b64encode((HERE / name).read_bytes()).decode()


html = (HERE / "template.html").read_text()
html = html.replace("__LOGO__", data_uri("logo.jpg")).replace("__PANEL__", data_uri("panel.jpg"))
assert "__LOGO__" not in html and "__PANEL__" not in html, "placeholder left unreplaced"
OUT.write_text(html)
print(f"wrote {OUT.name} ({OUT.stat().st_size / 1024:.0f} KB)")
