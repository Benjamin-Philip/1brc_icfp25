##
# 1brc_icfp25
#
# @file
# @version 0.1

PAPER_DIR=paper
OUT_DIR=out
AUX_DIR=$(OUT_DIR)/aux
EMPTY_DIR=$(OUT_DIR)/empty
DEPS_FILE=$(OUT_DIR)/.deps

LATEXMK = latexmk -pdflua -outdir=$(OUT_DIR) \
	-auxdir=$(AUX_DIR) -emulate-aux-dir \
	-recorder -use-make -deps -deps-out=$(DEPS_FILE) \
	-usepretex="\pdfvariable suppressoptionalinfo 512\relax" \
	-e 'warn qq(In Makefile, turn off custom dependencies\n);' \
	-e '@cus_dep_list = ();' \
	-e 'show_cus_dep();'

.DEFAULT_GOAL := all

-include $(DEPS_FILE)

all: $(OUT_DIR)/paper.pdf $(OUT_DIR)/index.html

$(OUT_DIR)/paper.pdf: $(PAPER_DIR)/paper.tex
	@mkdir -p $(OUT_DIR)
	$(LATEXMK) -lualatex='lualatex -interaction=batchmode' $<

$(OUT_DIR)/index.html: $(OUT_DIR)/paper.pdf $(OUT_DIR)/ar5iv-bindings
	latexmlc \
		--preload=[nobibtex,ids,localrawstyles,nobreakuntex,magnify=1.8,zoomout=1.8,tokenlimit=249999999,iflimit=3599999,absorblimit=1299999,pushbacklimit=599999]latexml.sty \
		--preload=ar5iv.sty \
		--path=$(OUT_DIR)/ar5iv-bindings/bindings \
		--path=$(OUT_DIR)/ar5iv-bindings/supported_originals \
		--format=html5 --pmml --cmml --mathtex \
		--timeout=2700 \
		--noinvisibletimes --nodefaultresources \
		--css=https://cdn.jsdelivr.net/gh/dginev/ar5iv-css/css/ar5iv.min.css \
		--css=https://cdn.jsdelivr.net/gh/dginev/ar5iv-css/css/ar5iv-fonts.min.css \
		--source=$(PAPER_DIR)/paper.tex --dest=$@ --log=$(AUX_DIR)/paper.latexml.log

$(OUT_DIR)/ar5iv-bindings:
	@mkdir -p $(OUT_DIR)
	wget https://github.com/dginev/ar5iv-bindings/archive/refs/tags/0.3.0.tar.gz -O out/ar5iv-bindings.tar.gz
	tar -xvzf out/ar5iv-bindings.tar.gz -C out
	mv out/ar5iv-bindings-0.3.0 out/ar5iv-bindings
	rm out/ar5iv-bindings.tar.gz

.PHONY: synctex
synctex: $(OUT_DIR)/paper.pdf
	$(LATEXMK) $(PAPER_DIR)/paper.tex \
		-g -pvc -lualatex='lualatex -interaction=batchmode -synctex=1'

.PHONY: clean
clean:
	-rm -rf $(OUT_DIR)

################
# Weather Data #
################
WD_DIR = data

$(WD_DIR)/wd-1K.txt:
	@mkdir -p $(WD_DIR)
	mix eval "Ibrc.WeatherData.async_stream(\"$(WD_DIR)\", \"1K\")"

$(WD_DIR)/wd-10K.txt:
	@mkdir -p $(WD_DIR)
	mix eval "Ibrc.WeatherData.async_stream(\"$(WD_DIR)\", \"10K\")"

$(WD_DIR)/wd-100K.txt:
	@mkdir -p $(WD_DIR)
	mix eval "Ibrc.WeatherData.async_stream(\"$(WD_DIR)\", \"100K\")"

$(WD_DIR)/wd-1M.txt:
	@mkdir -p $(WD_DIR)
	mix eval "Ibrc.WeatherData.async_stream(\"$(WD_DIR)\", \"1M\")"

$(WD_DIR)/wd-10M.txt:
	@mkdir -p $(WD_DIR)
	mix eval "Ibrc.WeatherData.async_stream(\"$(WD_DIR)\", \"10M\")"

$(WD_DIR)/wd-100M.txt:
	@mkdir -p $(WD_DIR)
	mix eval "Ibrc.WeatherData.async_stream(\"$(WD_DIR)\", \"100M\")"

$(WD_DIR)/wd-1B.txt:
	@mkdir -p $(WD_DIR)
	mix eval "Ibrc.WeatherData.async_stream(\"$(WD_DIR)\", \"1B\")"


.PHONY: wd-clean
wd-clean:
	-rm -rf $(WD_DIR)/wd-*

.PHONY: wd-all
.NOTPARALLEL: wd-all
wd-all: $(WD_DIR)/wd-1K.txt $(WD_DIR)/wd-10K.txt $(WD_DIR)/wd-100K.txt \
		$(WD_DIR)/wd-1M.txt $(WD_DIR)/wd-10M.txt $(WD_DIR)/wd-100M.txt \
		$(WD_DIR)/wd-1B.txt

##########
# Format #
##########

.PHONY: format
format: latex-format mix-format nix-format

.PHONY: latex-format
latex-format: $(EMPTY_DIR)/latex-format
$(EMPTY_DIR)/latex-format: **/*.tex
	tex-fmt $^

.PHONY: mix-format
mix-format: $(EMPTY_DIR)/mix-format
$(EMPTY_DIR)/mix-format: $(mix_src)
	mix format

.PHONY: nix-format
nix-format: $(EMPTY_DIR)/nix-format
$(EMPTY_DIR)/nix-format: flake.nix
	nix fmt

#########
# Tests #
#########

mix_src = $(wildcard **/*.ex) mix.exs

.PHONY: test
test: latex mix nix

##############
# Benchmarks #
##############

.PHONY: bench
bench: large-bench small-bench eflambe

.PHONY: large-bench
large-bench: wd-all
	mix run bench/large_bench.exs

.PHONY: small-bench
small-bench: wd-all
	mix run bench/small_bench.exs

.PHONY: eflambe
eflambe: wd-all
	mix run bench/eflambe.exs

#########
# LaTeX #
#########

.PHONY: latex
latex: latex-formatted

.PHONY: latex-formatted
latex-formatted:  **/*.tex
	tex-fmt -c $^
	@mkdir -p $(EMPTY_DIR)
	@touch $@

.PHONY: latex-pdf
latex-pdf: $(OUT_DIR)/paper.pdf

.PHONY: latex-html
latex-html: $(OUT_DIR)/index.html

#######
# Mix #
#######

.PHONY: mix
mix: mix-test mix-formatted mix-compiles

.PHONY: mix-test
mix-test: $(EMPTY_DIR)/mix-test
$(EMPTY_DIR)/mix-test: $(mix_src) $(EMPTY_DIR)/mix-deps $(WD_DIR)/wd-1K.txt
	mix test
	@mkdir -p $(EMPTY_DIR)
	@touch $@

.PHONY: mix-formatted
mix-formatted: $(mix_src)
	mix format --check-formatted
	@mkdir -p $(EMPTY_DIR)
	@touch $@

.PHONY: mix-compiles
mix-compiles: $(EMPTY_DIR)/mix-compiles
$(EMPTY_DIR)/mix-compiles: $(mix_src) $(EMPTY_DIR)/mix-deps
	mix compile --warnings-as-errors
	@mkdir -p $(EMPTY_DIR)
	@touch $@

.PHONY: mix-deps
mix-deps: $(EMPTY_DIR)/mix-deps
$(EMPTY_DIR)/mix-deps: mix.exs mix.lock
	mix deps.get && mix deps.compile
	@mkdir -p $(EMPTY_DIR)
	@touch $@


#######
# Nix #
#######

.PHONY: nix
nix: nix-check nix-formatted

.PHONY: nix-check
nix-check:
	nix flake check --all-systems

.PHONY: nix-formatted
nix-formatted: flake.nix
	nixfmt -c flake.nix
	@mkdir -p $(EMPTY_DIR)
	@touch $@

######
# CI #
######

.PHONY: ci
ci: ci-latex ci-mix ci-nix

.PHONY: ci-latex
ci-latex:
	act -W '.github/workflows/latex-ci.yml'

.PHONY: ci-mix
ci-mix:
	act -W '.github/workflows/elixir-ci.yml'

.PHONY: ci-nix
ci-nix:
	act -W '.github/workflows/nix-ci.yml'

# end
