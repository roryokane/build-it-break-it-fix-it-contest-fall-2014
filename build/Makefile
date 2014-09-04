# when specifying this Makefile, feel free to write what you wish you could specify, and then implement a compiler (or write up a cheat sheet in SofOp) for it
# reference the manual at http://www.gnu.org/software/make/manual/make.html

src_folder=src
bin_folder=.

header_file=$(src_folder)/header.rb
common_files=$(wildcard $(src_folder)/common/*.rb)

append_bin=$(bin_folder)/logappend
read_bin=$(bin_folder)/logread

executables=$(append_bin) $(read_bin)

.PHONY: build
build: $(executables)

.PHONY: run-example
run-example: build
	hilite $(append_bin) -T 1 -K secret -A -E Fred log1
	hilite $(append_bin) -T 2 -K secret -A -G Jill log1
	hilite $(append_bin) -T 3 -K secret -A -E Fred -R 1 log1
	hilite $(append_bin) -T 4 -K secret -A -G Jill -R 1 log1
	hilite $(read_bin) -K secret -S log1

.PHONY: test
test: build
	python dist/testing/check_test.py --prefix $(bin_folder) --xml dist/testing/some_tests/core/core_1.xml

.PHONY: clean
clean:
	rm -f $(executables)


$(bin_folder)/logappend: $(header_file) $(common_files) $(src_folder)/logappend-body.rb
	mkdir -p $(bin_folder)
	cat $+ > $(append_bin)
	chmod +x $(append_bin)

$(bin_folder)/logread: $(header_file) $(common_files) $(src_folder)/logread-body.rb
	mkdir -p $(bin_folder)
	cat $+ > $(read_bin)
	chmod +x $(read_bin)

