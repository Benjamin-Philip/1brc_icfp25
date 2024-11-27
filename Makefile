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

.DEFAULT_GOAL := all

-include $(DEPS_FILE)

all: $(OUT_DIR)/paper.pdf $(OUT_DIR)/paper.html

$(OUT_DIR)/paper.pdf: $(PAPER_DIR)/paper.tex $(mix_src)
	@mkdir -p $(OUT_DIR)
	$(LATEXMK) -lualatex='lualatex -interaction=batchmode' $<

$(OUT_DIR)/paper.html: $(OUT_DIR)/paper.pdf $(OUT_DIR)/ar5iv-bindings
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

# end
