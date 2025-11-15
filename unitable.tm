use ../tomo-btui/btui.tm

struct Codepoint(codepoint:Int32, text:Text?=none, description:Text?=none)

func cleanup_fail(msg:Text->Abort)
    disable()
    fail(msg)

struct Unitable(
    _top:Int=1,
    _cursor:Int=1,
    codepoints:[Codepoint],
)
    func load(table:Path=(./UnicodeData.txt) -> Unitable)
        say("Loading unicode table...")
        codepoints : &[Codepoint]
        for line in table.by_line()!
            hex := "0x"++line
            ignored : Text
            codepoint := Codepoint(Int32.parse(hex, &ignored) or fail("Couldn't load codepoint: $line"))
            codepoint.text = Text.from_utf32([codepoint.codepoint])
            if text := codepoint.text
                codepoint.description = text.codepoint_names()[1]!
            codepoints.insert(codepoint)
        say("Loaded $(codepoints.length) codepoints")
        return Unitable(codepoints=codepoints[])

    func draw(self:Unitable)
        clear()
        size := get_size()
        for row in self._top.to(self.codepoints.length _min_ self._top + size.y - 1)
            codepoint := self.codepoints[row] or cleanup_fail("Invalid row: $row")
            if row == self._cursor
                style(reverse=yes)

            style(fg=Black, bg=Yellow)
            write(" U+$(codepoint.codepoint.hex(digits=5, prefix=no))", ScreenVec2(0, row-self._top))
            clear(Right)

            if text := codepoint.text
                style(fg=White, bg=Normal, bold=yes)
                write(" $text", ScreenVec2(9, row-self._top))
                clear(Right)
                if description := codepoint.description
                    style(fg=Cyan, bg=Normal, bold=no)
                    write(" $description", ScreenVec2(12, row-self._top))
                    clear(Right)
                else
                    style(fg=Red, bg=Normal, bold=yes)
                    write(" No description", ScreenVec2(12, row-self._top))
                    clear(Right)
            else
                style(fg=Red, bg=Normal, bold=yes)
                write("Invalid codepoint")
                clear(Right)
                style(bold=no)

            if row == self._cursor
                style(reverse=no)

    func move_cursor(self:&Unitable, delta:Int)
        size := get_size()
        self._cursor = Int.clamped(self._cursor + delta, 1, self.codepoints.length)
        self._top = Int.clamped(Int.clamped(self._top, self._cursor - size.y + 5, self._cursor + - 5), 1, self.codepoints.length - size.y + 1)

    func move_scroll(self:&Unitable, delta:Int)
        size := get_size()
        self._top = Int.clamped(self._top + delta, 1, self.codepoints.length)
        self._cursor = Int.clamped(self._cursor, self._top + 5, self._top + size.y - 5)

func main()
    table := Unitable.load()

    set_mode(TUI)
    table.draw()
    repeat
        key := get_key()
        if key == "j"
            table.move_cursor(1)
        else if key == "Mouse wheel down"
            table.move_scroll(1)
        else if key == "k"
            table.move_cursor(-1)
        else if key == "Mouse wheel up"
            table.move_scroll(-1)
        else if key == "g"
            table.move_cursor(-table.codepoints.length)
        else if key == "G"
            table.move_cursor(table.codepoints.length)
        else if key == "q"
            stop
        else if key == "Ctrl-d"
            table.move_scroll(get_size().y/2)
        else if key == "Ctrl-u"
            table.move_scroll(-get_size().y/2)

        table.draw()

    disable()
