##
# 1brc_icfp25
#
# @file
# @version 0.1

PAPER_DIR=paper
OUT_DIR=out
AUX_DIR=$(OUT_DIR)/aux
DEPS_FILE=$(OUT_DIR)/.deps

LATEXMK = latexmk -pdflua -outdir=$(OUT_DIR) \
	-auxdir=$(AUX_DIR) -emulate-aux-dir \
	-recorder -use-make -deps -deps-out=$(DEPS_FILE) \
	-e 'warn qq(In Makefile, turn off custom dependencies\n);' \
	-e '@cus_dep_list = ();' \
	-e 'show_cus_dep();'

.DEFAULT_GOAL := $(OUT_DIR)/paper.pdf

-include $(DEPS_FILE)

$(OUT_DIR)/paper.pdf: $(PAPER_DIR)/paper.tex $(mix_src)
	@mkdir -p $(OUT_DIR)
	$(LATEXMK) -lualatex='lualatex -interaction=batchmode' $<

.PHONY: synctex
synctex: $(OUT_DIR)/paper.pdf
	$(LATEXMK) $(PAPER_DIR)/paper.tex \
		-g -pvc -lualatex='lualatex -interaction=batchmode -synctex=1'

.PHONY: clean
clean:
	-rm -rf $(OUT_DIR)

# end
