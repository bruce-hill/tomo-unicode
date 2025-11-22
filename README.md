# Unicode

`unicode` is a Tomo program to view information about the Unicode 3.1 standard
codepoints. The table viewer is an interactive text user interface with the
following controls:

```
q              - Quit the program
j/k or up/down - Move up or down one entry
Ctrl+d/Ctrl+u  - Move up or down one page
g/G            - Move to top/bottom
Ctrl+c or y    - Copy the text of an entry to the clipboard
u              - Copy the codepoint of an entry (U+XXXX) to the clipboard
d              - Copy the decimal codepoint of an entry to the clipboard
Ctrl+f or /    - Search for text (enter to confirm)
n/N            - Jump to next/previous search result
```

This project uses [bruce-hill/tomo-btui](https://github.com/bruce-hill/tomo-btui)
for the terminal user interface.

## Installation

```
make install
```

Or:

```
tomo -Ie unicode.tm
```
