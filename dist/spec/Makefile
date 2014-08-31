HTML = SPEC.html LOGAPPEND.html LOGREAD.html EXAMPLES.html VM.html STATE_HTML.html ROOM_HTML.html PRESENT_HTML.html BOUNDS_HTML.html IDS_HTML.html BREAK.html SCORE.html

all: $(HTML)

MD ?= markdown

%.html: %.md
	$(MD) $^ > $@

clean:
	rm -f *.html
