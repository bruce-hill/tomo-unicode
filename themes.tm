# Color themes for the table viewer
use btui

enum Theme(Dark, Light, None)
    func guess(->Theme)
        if bg := get_bg()
            if bg.is_light()
                return Theme.Light
            else
                return Theme.Dark
        else
            return Theme.Dark

    func header(theme:Theme)
        when theme is Dark
            style(fg=Color256(232), bg=Blue)
        is Light
            style(fg=Color256(255), bg=Color256(237))
        else pass

    func box(theme:Theme)
        when theme is Dark
            style(bg=Color256(222), fg=Color256(94))
        is Light
            style(bg=Color256(54), fg=Color256(219))
        else pass

    func box_details(theme:Theme)
        when theme is Dark
            style(bg=Color256(222), fg=Color256(232))
        is Light
            style(bg=Color256(54), fg=Color256(255))
        else pass

    func row_codepoint(theme:Theme, highlighted=no)
        when theme is Dark
            style(fg=Yellow, bg=(if highlighted then Color.Color256(239) else Color.Color256(235)))
        is Light
            style(fg=Color256(18), bg=(if highlighted then Color.Color256(153) else Color.Color256(255)))
        else pass

    func row_character(theme:Theme, highlighted=no)
        when theme is Dark
            style(fg=Color256(255), bg=(if highlighted then Color.Color256(239) else Color.Color256(235)), bold=yes)
        is Light
            style(fg=Color256(232), bg=(if highlighted then Color.Color256(153) else Color.Color256(255)), bold=yes)
        else pass

    func row_description(theme:Theme, highlighted=no)
        when theme is Dark
            style(fg=Color256(195), bg=(if highlighted then Color.Color256(239) else Color.Color256(235)), bold=yes)
        is Light
            style(fg=Color256(52), bg=(if highlighted then Color.Color256(153) else Color.Color256(255)), bold=yes)
        else pass

    func search_label(theme:Theme, active:Bool)
        when theme is Dark
            style(bg=Color256((if active then Byte(69) else Byte(27))), fg=Color(232))
        is Light
            style(bg=Color256((if active then Byte(27) else Byte(69))), fg=Color(255))
        else pass

    func search_text(theme:Theme, active:Bool)
        when theme is Dark
            style(bg=Color256(255), fg=Color256((if active then Byte(232) else Byte(242))), bold=yes)
        is Light
            style(bg=Color256(255), fg=Color256((if active then Byte(232) else Byte(242))), bold=yes)
        else pass

    func message_theme(theme:Theme)
        when theme is Dark
            style(bg=Color256(252), fg=Color256(232), bold=yes)
        is Light
            style(bg=Color256(249), fg=Color256(232), bold=yes)
        else pass

    func scroll_bg(theme:Theme)
        when theme is Dark, Light
            style(bg=Color256(252), fg=Color256(232), bold=yes)
        else pass

    func scroll_bar(theme:Theme)
        when theme is Dark, Light
            style(bg=Color256(247))
        else pass
