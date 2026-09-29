#!/usr/bin/env python3
"""Observable Cruz-Diez ribbon checks.

Cells are read from the ribbon line only (a line of color with no visible
text), so a prompt or the logout farewell cannot disturb the sequence.
"""
from __future__ import annotations

import re
import sys

RESET = b"\x1b[0m"
CSI = re.compile(rb"\x1b\[[0-9;?]*[ -/]*[@-~]")


def _ribbon_line(data: bytes) -> bytes | None:
    for line in data.split(b"\n"):
        if not (
            b"\x1b[48;2;" in line or b"\x1b[48;5;" in line or b"\x1b[41m" in line
        ):
            continue
        visible = CSI.sub(b"", line).strip()
        if visible == b"":
            return line
    return None


def _cells(line: bytes, kind: str) -> list[str]:
    if kind == "24":
        found = re.findall(rb"\x1b\[48;2;(\d+;\d+;\d+)m", line)
    elif kind == "256":
        found = re.findall(rb"\x1b\[48;5;(\d+)m", line)
    else:
        found = re.findall(rb"\x1b\[(4[0-7]|10[0-7])m", line)
    return [item.decode("ascii") for item in found]


def _channel(cell: str, index: int) -> int:
    return int(cell.split(";")[index])


def _hue_name(cell: str) -> str:
    """Name the ribbon cell. Cyan's green channel is slightly above its blue
    channel, and blue's green channel is above 100, so the tests are ordered
    to keep those two apart."""
    red, green, blue = (_channel(cell, i) for i in range(3))
    if red >= 250 and green >= 250 and blue >= 250:
        return "white"
    if red <= 20 and green <= 20 and blue <= 20:
        return "black"
    if blue > 150 and red < 80 and green < 160 and blue > green + 40:
        return "blue"
    if green > 140 and blue > 140 and red < 80:
        return "cyan"
    if red > 150 and green < 80 and blue < 80:
        return "red"
    if red > 200 and 80 <= green <= 170 and blue < 80:
        return "orange"
    if red > 200 and green > 170 and blue < 90:
        return "yellow"
    if green > red and green > blue and green > 100:
        return "green"
    if red > 70 and blue > 80 and green < 90:
        return "purple"
    return f"unclassified:{cell}"


def _check_shape(kind: str, cells: list[str]) -> str | None:
    if len(cells) != 16:
        return f"expected 16 color cells, found {len(cells)}: {','.join(cells)}"
    if cells[0:7] != cells[8:15]:
        return "the rainbow does not repeat after the white break"
    if kind == "24":
        names = [_hue_name(cell) for cell in cells]
        expected = [
            "red", "orange", "yellow", "green", "cyan", "blue", "purple", "white",
            "red", "orange", "yellow", "green", "cyan", "blue", "purple", "black",
        ]
        if names != expected:
            return "hue order is " + ",".join(names)
    elif kind == "256":
        if cells[7] != "231" or cells[15] != "16":
            return f"256-color break/close is {cells[7]} / {cells[15]}"
    else:
        if cells[7] != "107" or cells[15] != "40":
            return f"16-color break/close is {cells[7]} / {cells[15]}"
    return None


def main() -> None:
    if len(sys.argv) < 3:
        sys.stderr.write("usage: banner.py <absent|24|256|16> <capture> [baseline]\n")
        sys.exit(2)
    kind = sys.argv[1]
    data = open(sys.argv[2], "rb").read()
    line = _ribbon_line(data)
    if kind == "absent":
        if line is None and b"\x1b[48;2;" not in data and b"\x1b[48;5;" not in data:
            sys.exit(0)
        sys.stdout.write("ribbon or truecolor/256 background appeared outside a TTY banner\n")
        sys.exit(1)
    if line is None:
        sys.stdout.write("ribbon line not found in terminal output\n")
        sys.exit(1)
    if RESET not in line:
        sys.stdout.write("ribbon does not reset SGR before the line ends\n")
        sys.exit(1)
    cells = _cells(line, kind)
    problem = _check_shape(kind, cells)
    if problem:
        sys.stdout.write(problem + "\n")
        sys.exit(1)
    observed = ",".join(cells)
    if len(sys.argv) > 3:
        expected = open(sys.argv[3], encoding="utf-8").read().strip()
        if observed != expected:
            sys.stdout.write(f"Expected cells:\n{expected}\nActual cells:\n{observed}\n")
            sys.exit(1)
    else:
        sys.stdout.write(observed + "\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
