use ../tomo-btui/btui.tm
use <sys/wait.h>

struct ColumnWidths(
    codepoint=8,
    text=6,
    name=32,
    description=32,
)

struct Codepoint(
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
    func parse(text:Text -> Codepoint)
        items := text.split(";")
        codepoint := Codepoint(Int32.parse("0x"++items[1]!)!)
        codepoint.text = Text.from_utf32([codepoint.codepoint])
        codepoint.name = items[2]!
        codepoint.category = items[3]!
        codepoint.combining_class = items[4]!
        codepoint.bidi_class = items[5]!
        codepoint.decomposition_mapping = items[6]!
        junk : Text
        codepoint.decimal_digit = Int.parse(items[7]!, &junk)
        codepoint.digit = Int.parse(items[8]!, &junk)
        codepoint.numeric = Int.parse(items[9]!, &junk)
        codepoint.mirrored = items[10] == "Y"
        codepoint.unicode_1_name = items[11]
        codepoint.iso_comment = items[11]
        codepoint.simple_uppercase = Int32.parse(items[12]!, &junk)
        codepoint.simple_lowercase = Int32.parse(items[13]!, &junk)
        codepoint.simple_titlecase = Int32.parse(items[14]!, &junk)
        return codepoint

func cleanup_fail(msg:Text->Abort)
    disable()
    fail(msg)

struct Unitable(
    entries:[Text],
    _top:Int=1,
    _cursor:Int=1,
    quit:Bool=no,
    search_start:Int?=none,
    search:Text?=none,
    message:Text?=none,
)
    func load(table:Path=(./UnicodeData.txt) -> Unitable)
        return Unitable(entries=table.lines()!)

    func draw(self:Unitable)
        clear()
        size := get_size()
        style(fg=Black, bg=Blue)
        write(" Unicode Table ", ScreenVec2(0,0))
        clear(Right)

        for y in (1).to(size.y - 2)
            row := self._top + y - 1
            codepoint := Codepoint.parse(self.entries[row]!)
            if row == self._cursor
                style(reverse=yes)

            style(fg=Black, bg=Yellow)
            write(" U+$(codepoint.codepoint.hex(digits=5, prefix=no))", ScreenVec2(0, y))
            clear(Right)

            if text := codepoint.text
                style(fg=White, bg=Normal, bold=yes)
                if codepoint.codepoint > 32
                    write(" $text          ", ScreenVec2(9, y))
                else
                    write("           ", ScreenVec2(9, y))
                clear(Right)
                if name := codepoint.name
                    style(fg=Cyan, bg=Normal, bold=no)
                    write(" $name", ScreenVec2(14, y))
                    clear(Right)
                else
                    style(fg=Red, bg=Normal, bold=yes)
                    write(" No name", ScreenVec2(14, y))
                    clear(Right)
            else
                style(fg=Red, bg=Normal, bold=yes)
                write("Invalid codepoint")
                clear(Right)
                style(bold=no)

            if row == self._cursor
                style(reverse=no)

        if search := self.search
            style(bg=Red, fg=Black)
            write(" Search: ", ScreenVec2(0, size.y-1))
            style(bg=Normal, fg=White, bold=yes)
            write(" "++search)
            clear(Right)

        if message := self.message
            style(bg=Normal, fg=White, bold=yes)
            write(" $message ", ScreenVec2(0, size.y-1))
            clear(Right)

    func update(self:&Unitable)
        if self.search_start
            self.update_search()
            return

        key := get_key()
        if key == "j"
            self.move_cursor(1)
        else if key == "Mouse wheel down"
            self.move_scroll(1)
        else if key == "k"
            self.move_cursor(-1)
        else if key == "Mouse wheel up"
            self.move_scroll(-1)
        else if key == "g"
            self.move_cursor(-self.entries.length)
        else if key == "G"
            self.move_cursor(self.entries.length)
        else if key == "q"
            self.quit = yes
        else if key == "Ctrl-d"
            self.move_scroll(get_size().y/2)
        else if key == "Ctrl-u"
            self.move_scroll(-get_size().y/2)
        else if key == "Ctrl-c"
            if text := self.entries[self._cursor]!.text
                success := no
                C_code `
                    int fds[2];
                    pipe(fds);
                    pid_t child = fork();
                    if (child == 0) {
                        close(fds[1]);
                        dup2(fds[0], STDIN_FILENO);
                        execlp("xclip", "xclip", "-selection", "clipboard", NULL);
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
                if success
                    self.message = "Copied!"
                else
                    self.message = "Failed to copy to clipboard!"
        else if key == "/"
            self.search = ""
            self.search_start = self._cursor
        else if key == "n"
            if search := self.search
                for offset in (0).to(self.entries.length-1)
                    index := (self._cursor + 1 + offset) mod1 self.entries.length
                    line := self.entries[index]!
                    if line.lower().has(search)
                        self.set_cursor(index)
                        stop
        else if key == "N"
            if search := self.search
                for offset in (self.entries.length-1).to(0)
                    index := (self._cursor - 1 + offset) mod1 self.entries.length
                    line := self.entries[index]!
                    if line.lower().has(search)
                        self.set_cursor(index)
                        stop

    func update_search(self:&Unitable)
        key := get_key()
        search := self.search!
        if key == "Escape" or key == "Ctrl-c"
            self.search = none
            self.search_start = none
            return
        else if key == "Enter"
            # keep self.search so we can use 'n' to find it later
            self.search_start = none
            return
        else if key == "Space"
            search = search ++ " "
        else if key == "Backspace"
            search = search.to(-2)
        else if key.length == 1
            search = search ++ key

        search = search.lower()
        self.search = search

        search_start := self.search_start!
        for offset in (0).to(self.entries.length-1)
            index := (search_start + offset) mod1 self.entries.length
            line := self.entries[index]!
            if line.lower().has(search)
                self.set_cursor(index)
                stop

    func move_cursor(self:&Unitable, delta:Int)
        self.set_cursor(self._cursor + delta)

    func set_cursor(self:&Unitable, pos:Int)
        size := get_size()
        self._cursor = Int.clamped(pos, 1, self.entries.length)
        table_height := size.y - 2
        self._top = Int.clamped(Int.clamped(self._top, self._cursor - table_height + 5, self._cursor + - 5), 1, self.entries.length - table_height + 1)

    func move_scroll(self:&Unitable, delta:Int)
        size := get_size()
        self._top = Int.clamped(self._top + delta, 1, self.entries.length)
        table_height := size.y - 2
        self._cursor = Int.clamped(self._cursor, self._top + 5, self._top + table_height - 5)

func main()
    table := Unitable.load()
    set_mode(TUI)
    hide_cursor()
    table.draw()
    while not table.quit
        table.update()
        table.draw()

    disable()
