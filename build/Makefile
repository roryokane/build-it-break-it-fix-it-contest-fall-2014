# when specifying this Makefile, feel free to write what you wish you could specify, and then implement a compiler (or write up a cheat sheet in SofOp) for it
# reference the manual at http://www.gnu.org/software/make/manual/make.html

SRC_FOLDER=src
BIN_FOLDER=.

APPEND_BIN=$(BIN_FOLDER)/logappend
READ_BIN=$(BIN_FOLDER)/logread

EXECUTABLES=$(APPEND_BIN) $(READ_BIN)

.PHONY: build
build: $(EXECUTABLES)

.PHONY: run-example
run-example: build
	hilite $(APPEND_BIN) -T 1 -K secret -A -E Fred log1
	hilite $(APPEND_BIN) -T 2 -K secret -A -G Jill log1
	hilite $(APPEND_BIN) -T 3 -K secret -A -E Fred -R 1 log1
	hilite $(APPEND_BIN) -T 4 -K secret -A -G Jill -R 1 log1
	hilite $(READ_BIN) -K secret -S log1

.PHONY: test
test: build
	python dist/testing/check_test.py --prefix $(BIN_FOLDER) --xml dist/testing/some_tests/core/core_1.xml

.PHONY: clean
clean:
	rm -f $(EXECUTABLES)


$(BIN_FOLDER)/logappend: $(SRC_FOLDER)/header.rb $(SRC_FOLDER)/logappend-body.rb
	mkdir -p $(BIN_FOLDER)
	cat $(SRC_FOLDER)/header.rb $(SRC_FOLDER)/logappend-body.rb > $(APPEND_BIN)
	chmod +x $(APPEND_BIN)

$(BIN_FOLDER)/logread: $(SRC_FOLDER)/header.rb $(SRC_FOLDER)/logread-body.rb
	mkdir -p $(BIN_FOLDER)
	cat $(SRC_FOLDER)/header.rb $(SRC_FOLDER)/logread-body.rb > $(READ_BIN)
	chmod +x $(READ_BIN)

