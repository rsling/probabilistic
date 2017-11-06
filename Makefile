FIGUREDIR = figures
CACHEDIR = cache

pdf: probabilistic.bbl probabilistic.pdf 

all: pod cover

complete: index probabilistic.pdf

index:  probabilistic.snd
 
probabilistic.pdf: probabilistic.aux
	xelatex probabilistic 

probabilistic.aux: probabilistic.tex $(wildcard local*.tex)
	xelatex -no-pdf probabilistic 

# Before the normal LSP make begins, we need to make TeX from Rnw.
probabilistic.tex: probabilistic.Rnw $(wildcard chapters/*.Rnw) $(wildcard chapters/*.tex)
	Rscript \
	  -e "library(knitr)" \
	  -e "knitr::knit('$<','$@')"

# Make R files.
%.R: %.Rnw
	Rscript -e "Sweave('$^', driver=Rtangle())"

# Create only the book.
probabilistic.bbl: probabilistic.tex localbibliography.bib  
	xelatex -no-pdf probabilistic
	biber probabilistic


probabilistic.snd: probabilistic.bbl
	touch probabilistic.adx probabilistic.sdx probabilistic.ldx
	sed -i s/.*\\emph.*// probabilistic.adx 
	sed -i 's/hyperindexformat{\\\(infn {[0-9]*\)}/\1/' probabilistic.sdx
	sed -i 's/hyperindexformat{\\\(infn {[0-9]*\)}/\1/' probabilistic.adx
	sed -i 's/hyperindexformat{\\\(infn {[0-9]*\)}/\1/' probabilistic.ldx
# 	python3 fixindex.py
# 	mv mainmod.adx probabilistic.adx
	makeindex -o probabilistic.and probabilistic.adx
	makeindex -o probabilistic.lnd probabilistic.ldx
	makeindex -o probabilistic.snd probabilistic.sdx 
	xelatex probabilistic 
 

cover: FORCE
	convert probabilistic.pdf\[0\] -quality 100 -background white -alpha remove -bordercolor "#999999" -border 2  cover.png
	cp cover.png googlebooks_frontcover.png
	convert -geometry 50x50% cover.png covertwitter.png
	convert probabilistic.pdf\[0\] -quality 100 -background white -alpha remove -bordercolor "#999999" -border 2  -resize x495 coveromp.png
	display cover.png


googlebooks: googlebooks_interior.pdf

googlebooks_interior.pdf: complete
	cp probabilistic.pdf googlebooks_interior.pdf
	pdftk probabilistic.pdf cat 1 output googlebooks_frontcover.pdf 

openreview: openreview.pdf
	

openreview.pdf: probabilistic.pdf
	pdftk probabilistic.pdf multistamp orstamp.pdf output openreview.pdf 

proofreading: proofreading.pdf
	
paperhive: 
	git branch gh-pages
	git checkout gh-pages
	git add proofreading.pdf versions.json
	git commit -m 'prepare for proofreading' proofreading.pdf versions.json
	git push origin gh-pages
	git checkout master 
	echo "langsci.github.io/BOOKID"
	firefox https://paperhive.org/documents/new
	
proofreading.pdf: probabilistic.pdf
	pdftk probabilistic.pdf multistamp prstamp.pdf output proofreading.pdf 

blurb: blurb.html blurb.tex biosketch.tex biosketch.html


blurb.tex: blurb.md
	pandoc -f markdown -t latex blurb.md>blurb.tex
	
blurb.html: blurb.md
	pandoc -f markdown -t html blurb.md>blurb.html
	
biosketch.tex: blurb.md
	pandoc -f markdown -t latex biosketch.md>biosketch.tex
	
biosketch.html: blurb.md
	pandoc -f markdown -t html biosketch.md>biosketch.html
	
clean:
	rm -f *.bak *~ *.backup *.tmp \
	*.adx *.and *.idx *.ind *.ldx *.lnd *.sdx *.snd *.rdx *.rnd *.wdx *.wnd \
	*.log *.blg *.ilg \
	*.aux *.toc *.cut *.out *.tpm *.bbl *-blx.bib *_tmp.bib \
	*.glg *.glo *.gls *.wrd *.wdv *.xdv *.mw *.clr \
	*.run.xml probabilistic.tex probabilistic.pgs probabilistic.bcf \
	chapters/*aux chapters/*~ chapters/*.bak chapters/*.backup \
	langsci/*/*aux langsci/*/*~ langsci/*/*.bak langsci/*/*.backup \
	cache/* figures/* cache*.*
	
realclean: clean
	rm -f *.dvi *.ps

chapterlist:
	grep chapter probabilistic.toc|sed "s/.*numberline {[0-9]\+}\(.*\).newline.*/\\1/" 

podcover:
	bash podcovers.sh

FORCE:
