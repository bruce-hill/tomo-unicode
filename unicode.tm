use btui
use <sys/wait.h>

_HELP := "
    `unicode` is a Tomo program to view information about the Unicode 3.1 standard
    codepoints. The table viewer is an interactive text user interface with the
    following controls:

        q              - Quit the program
        j/k or up/down - Move up or down one entry
        Ctrl+d/Ctrl+u  - Move up or down one page
        g/G            - Move to top/bottom
        Ctrl+c or y    - Copy the text of an entry to the clipboard
        u              - Copy the codepoint of an entry (U+XXXX) to the clipboard
        d              - Copy the decimal codepoint of an entry to the clipboard
        Ctrl+f or /    - Search for text (enter to confirm)
        n/N            - Jump to next/previous search result
        i              - Toggle info panel

"

struct UnicodeEntry(
    codepoint:Int32,
    text:Text?=none,
    name:Text="",
    category:Text="",
    combining_class:Text="",
    bidi_class:Text="",
    decomposition_mapping:Text="",
    decimal_digit:Int?=none,
    digit:Int?=none,
    numeric:Int?=none,
    mirrored:Bool=no,
    unicode_1_name:Text?=none,
    iso_comment:Text?=none,
    simple_uppercase:Int32?=none,
    simple_lowercase:Int32?=none,
    simple_titlecase:Int32?=none,
)
    func parse(text:Text -> UnicodeEntry?)
        # For format details, see: https://www.unicode.org/L2/L1999/UnicodeData.html
        items := text.split(";")
        entry := UnicodeEntry(Int32.parse("0x"++(items[1] or return none)) or return none)
        entry.text = Text.from_utf32([entry.codepoint])
        entry.name = items[2] or return none
        entry.category = items[3] or return none
        entry.combining_class = items[4] or return none
        entry.bidi_class = items[5] or return none
        entry.decomposition_mapping = items[6] or return none
        junk : Text
        entry.decimal_digit = Int.parse(items[7] or return none, &junk)
        entry.digit = Int.parse(items[8] or return none, &junk)
        entry.numeric = Int.parse(items[9] or return none, &junk)
        entry.mirrored = items[10] == "Y"
        entry.unicode_1_name = items[11]
        entry.iso_comment = items[12]
        entry.simple_uppercase = Int32.parse("0x"++(items[13] or return none), &junk)
        entry.simple_lowercase = Int32.parse("0x"++(items[14] or return none), &junk)
        entry.simple_titlecase = Int32.parse("0x"++(items[15] or return none), &junk)
        return entry

    func info(self:UnicodeEntry -> {Text:Text})
        return {
            "Symbol": (if self.codepoint > 32 then self.text or "" else ""),
            "UTF32": "$(self.codepoint.hex()) ($(self.codepoint))",
            "UTF16": (if text := self.text then " ".join([u.hex() for u in text.utf16()]) ++ " (" ++ " ".join([Text(u) for u in text.utf16()]) ++ ")" else "")
            "UTF8": (if text := self.text then " ".join([b.hex() for b in text.utf8()]) else "")
            "Name": self.name,
            "Unicode 1 name": self.unicode_1_name or "",
            "Category": self.category,
            "Combining class": self.combining_class,
            "Bidi class": self.bidi_class,
            "Decomposition": self.decomposition_mapping,
            "Digit": (if d := self.digit then Text(d) else ""),
            "Mirrored": Text(self.mirrored),
            "ISO comment": self.iso_comment or "",
            "Uppercase": (if u := self.simple_uppercase then Text.from_utf32([u])! else ""),
            "Lowercase": (if l := self.simple_lowercase then Text.from_utf32([l])! else ""),
            "Titlecase": (if t := self.simple_titlecase then Text.from_utf32([t])! else ""),
        }

    func draw(self:UnicodeEntry, y:Int, highlighted=no)
        columns := [
            " U+$(self.codepoint.hex(digits=5, prefix=no))",

            (
                if text := self.text
                    if self.codepoint > 32
                        text
                    else
                        ""
                else
                    ""
            )

            (
                do
                    name := if self.name then self.name else "No name"
                    if desc := self.unicode_1_name
                        name ++= " "++desc
                    name.title()
            ),
        ]

        styles := if highlighted
            [
                func() style(fg=Yellow, bg=Color256(239))
                func() style(fg=White, bg=Color256(239), bold=yes)
                func() style(fg=Cyan, bg=Color256(239), bold=yes)
            ]
        else
            [
                func() style(fg=Yellow, bg=Color256(235))
                func() style(fg=White, bg=Color256(235), bold=yes)
                func() style(fg=Cyan, bg=Color256(235), bold=yes)
            ]

        widths := [10, 6, 32]

        x := 0
        for i,column in columns
            styles[i]!()
            write(" $column ", ScreenVec2(x, y))
            clear(Right)
            x += widths[i]!

struct TableViewer(
    entries:[Text],
    _top:Int=1,
    _cursor:Int=1,
    quit:Bool=no,
    show_info:Bool=yes,
    search_start:Int?=none,
    search:Text?=none,
    message:Text?=none,
)
    func draw(self:TableViewer)
        size := get_size()
        style(fg=Black, bg=Blue)
        write(" Codepoint Symbol Description ", ScreenVec2(0,0))
        clear(Right)

        for y in (1).to(size.y - 1)
            row := self._top + y - 1
            entry := self.get_entry(row) or skip
            entry.draw(y, highlighted=(row == self._cursor))

        if self.show_info
            if entry := self.get_entry()
                info := entry.info()
                height := info.length + 2
                label_width := (_max_: k.width() for k in info.keys)!
                value_width := (_max_: v.width() for v in info.values)! _max_ 50
                width := label_width + 3 + value_width
                top_left := ScreenVec2(size.x - width - 1, 1)
                box_color := Color.Color256(222)
                style(bg=box_color, fg=box_color)
                fill_box(top_left, ScreenVec2(width, height))
                style(fg=Color256(94))
                for i,label in info.keys
                    write(label, pos=top_left + ScreenVec2(label_width + 1, i), Right)
                style(fg=Black)
                for i,value in info.values
                    write(value, pos=top_left + ScreenVec2(label_width + 2, i), Left)

        if search := self.search
            style(bg=Color256((if self.search_start then Byte(69) else Byte(27))), fg=Color(232))
            write(" Search: ", ScreenVec2(0, size.y-1))
            style(bg=Color256(235), fg=Color256((if self.search_start then Byte(255) else Byte(242))), bold=yes)
            write(" "++search)
            clear(Right)

        if message := self.message
            style(bg=Color256(252), fg=Color256(232), bold=yes)
            write(" $message ", ScreenVec2(size.x-1, size.y-1), Right)
            clear(Right)

        # Scroll bar
        scroll_height := size.y-2
        scroll_top := 1 + (self._top * scroll_height)/self.entries.length
        scroll_bottom := 1 + ((self._top + scroll_height - 1) * scroll_height)/self.entries.length
        style(bg=Color256(237))
        for y in (1).to(scroll_top-1, step=1)
            write(" ", ScreenVec2(size.x-1, y))
        style(bg=Color256(247))
        for y in (scroll_top).to(scroll_bottom, step=1)
            write(" ", ScreenVec2(size.x-1, y))
        style(bg=Color256(237))
        for y in (scroll_bottom+1).to(size.y-1, step=1)
            write(" ", ScreenVec2(size.x-1, y))

        flush()

    func update(self:&TableViewer)
        if self.search_start
            self.update_search()
            return

        size := get_size()
        mouse_pos := ScreenVec2(0, 0)
        key := get_key(&mouse_pos)
        when key
        is "j"
            self.move_cursor(1)
        is "Mouse wheel down"
            self.move_scroll(1)
        is "k"
            self.move_cursor(-1)
        is "Mouse wheel up"
            self.move_scroll(-1)
        is "Left press", "Left drag"
            if 1 <= mouse_pos.y and mouse_pos.y <= size.y-2
                if mouse_pos.x >= size.x-1
                    self.set_cursor((self.entries.length * (mouse_pos.y - 1)) / (size.y - 2))
                    # Prevent spamming the console too much
                    sleep(0.01)
                else if key == "Left press"
                    self.set_cursor(self._top + mouse_pos.y - 1)
        is "g"
            self.move_cursor(-self.entries.length)
        is "G"
            self.move_cursor(self.entries.length)
        is "q"
            self.quit = yes
        is "Escape"
            if self.search != none
                self.search = none
            else
                self.quit = yes
        is "Ctrl-d"
            self.move_scroll(size.y/2)
        is "Ctrl-u"
            self.move_scroll(-size.y/2)
        is "Ctrl-c", "y"
            if entry := self.get_entry()
                if text := entry.text
                    if copy_to_clipboard(text)
                        self.message = "Copied text!"
                    else
                        self.message = "Failed to copy to clipboard!"
        is "u"
            if entry := self.get_entry()
                if copy_to_clipboard("U+$(entry.codepoint.hex())")
                    self.message = "Copied U+$(entry.codepoint.hex())!"
                else
                    self.message = "Failed to copy to clipboard!"
        is "d"
            if entry := self.get_entry()
                if copy_to_clipboard("$(entry.codepoint)")
                    self.message = "Copied $(entry.codepoint)!"
                else
                    self.message = "Failed to copy to clipboard!"
        is "i"
            self.show_info = not self.show_info
        is "/", "Ctrl-f"
            self.search = ""
            self.search_start = self._cursor
            self.message = none
        is "n"
            if search := self.search
                for offset in (0).to(self.entries.length-1)
                    index := (self._cursor + 1 + offset) mod1 self.entries.length
                    line := self.entries[index]!
                    if line.lower().has(search)
                        self.set_cursor(index)
                        stop
        is "N"
            if search := self.search
                for offset in (self.entries.length-1).to(0)
                    index := (self._cursor - 1 + offset) mod1 self.entries.length
                    line := self.entries[index]!
                    if line.lower().has(search)
                        self.set_cursor(index)
                        stop

    func get_entry(self:TableViewer, row:Int?=none -> UnicodeEntry?)
        return UnicodeEntry.parse(self.entries[row or self._cursor] or return none)

    func update_search(self:&TableViewer)
        key := get_key()
        search := self.search or ""
        when key
        is "Escape", "Ctrl-c"
            self.search = none
            self.search_start = none
            return
        is "Enter"
            # keep self.search so we can use 'n' to find it later
            self.search_start = none
            return
        is "Space"
            search = search ++ " "
        is "Backspace"
            search = search.to(-2)
        else if key.length == 1
            search = search ++ key

        search = search.lower()
        self.search = search

        search_start := self.search_start or 1
        for offset in (0).to(self.entries.length-1)
            index := (search_start + offset) mod1 self.entries.length
            line := self.entries[index] or skip
            if line.lower().has(search)
                self.set_cursor(index)
                stop

    func move_cursor(self:&TableViewer, delta:Int)
        self.set_cursor(self._cursor + delta)

    func set_cursor(self:&TableViewer, pos:Int)
        size := get_size()
        self._cursor = Int.clamped(pos, 1, self.entries.length)
        table_height := size.y - 2
        self._top = Int.clamped(Int.clamped(self._top, self._cursor - table_height + 5, self._cursor + - 5), 1, self.entries.length - table_height)

    func move_scroll(self:&TableViewer, delta:Int)
        size := get_size()
        self._top = Int.clamped(self._top + delta, 1, self.entries.length)
        table_height := size.y - 2
        self._cursor = Int.clamped(self._cursor, self._top + 5, self._top + table_height - 5)

func copy_to_clipboard(text:Text -> Bool)
    success := no
    C_code `
        int fds[2];
        pipe(fds);
        pid_t child = fork();
        if (child == 0) {
            close(fds[1]);
            dup2(fds[0], STDIN_FILENO);
        #ifdef __APPLE__
            execlp("pbcopy", "pbcopy", NULL);
        #else
            execlp("xclip", "xclip", "-selection", "clipboard", NULL);
        #endif
            errx(1, "Could not exec!");
        }
        close(fds[0]);
        const char *str = @(text.as_c_string());
        write(fds[1], str, strlen(str));
        close(fds[1]);
        int status;
        waitpid(child, &status, 0);
        @success = (WIFEXITED(status) && WEXITSTATUS(status) == 0);
    `
    return success

func main(unicode_data:Path?=none)
    C_code `
        static const char unicode_table[] = {
            #embed "../UnicodeData.txt"
            ,0,
        };
    `
    table_lines := if file := unicode_data
        file.lines()!
    else
        C_code:Text`Text$from_str(unicode_table)`.lines()

    viewer := TableViewer(table_lines)

    set_mode(TUI)
    hide_cursor()
    viewer.draw()
    while not viewer.quit
        prev := viewer
        viewer.update()
        if viewer != prev
            viewer.draw()

    disable()
