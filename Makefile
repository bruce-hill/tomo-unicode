unicode: unicode.tm UnicodeData.txt
	tomo -e unicode.tm

install:
	tomo -Ie unicode.tm

uninstall:
	tomo -u unicode

.PHONY: install uninstall
