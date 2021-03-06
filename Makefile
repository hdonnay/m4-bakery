# Copies files from src/ to dst/. Any .html files are
# interpreted by GNU m4 and wrapped in a the GNU m4
# template. Common m4 macros may be stored in a macros
# file.

MACROS   := macros.m4
TEMPLATE := template.html.m4
SRC      := src
DST      := dst

# Build a list of all the files that should exist when the
# baking is done. We do this by getting a list of all the
# source files and rewriting pathnames and file suffixes as
# necessary.
targets  := $(shell find $(SRC) -type f)
targets  := $(targets:$(SRC)/%=$(DST)/%)
targets  := $(targets:.m4=)
targets  := $(filter-out %.inc %.swp,$(targets))
targets  := $(targets:.md=.html)

all: $(targets)

# Any files named '*.html.m4' will be interpreted by M4
# with the macros available, wrapped in the HTML template,
# and saved without the '.m4' extension. A later rule
# copies this to the destination, and Make is smart enough
# to delete the intermediate file.
$(SRC)/%.html: $(SRC)/%.html.m4 $(MACROS) $(TEMPLATE)
	m4 -P $(MACROS) $< $(TEMPLATE) > $@

# How about markdown? This idea can be extended to support
# many different pre- and post-processing tools. I think
# pandoc is the best markdown tool out there, so here's one
# way to wire it in to run *before* m4. GNU Make is even
# smart enough to clean up the intermediate file created by
# this step.
$(SRC)/%.html.m4: $(SRC)/%.md.m4 $(MACROS) $(TEMPLATE)
	# Rendering $< to $@ with pandoc
	pandoc -f markdown -t html -o $@ $<

# Any other files named '*.m4' will be interpreted by M4
# with the macros available, saved without the '.m4'
# extension, but will not be wrapped in the HTML template.
$(SRC)/%: $(SRC)/%.m4 $(MACROS)
	m4 -P $(MACROS) $< > $@

# After the files have been compiled by m4, they will be
# copied verbatim to the destination. I use the ubiquitous
# unix 'install' tool here because it creates any needed
# paths automatically.
$(DST)/%: $(SRC)/%
	install -m 644 -D $< $@

# By default, GNU Make will skip any source files that have
# not been modified since the last time they were rendered.
# Run 'make clean' to erase the destination directory for a
# complete rebuild. I do a 'mv' then 'rm' to reduce the
# chances of running an 'rm -rf /'.
clean:
	mv $(DST) .old_dst
	rm -rf .old_dst

# vim: tw=59 :
