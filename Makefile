FIGUREDIR = figures
CACHEDIR = cache

pdf: main.bbl main.pdf 

all: pod cover

complete: index main.pdf

index:  main.snd
 
main.pdf: main.aux
	xelatex main 

main.aux: main.tex $(wildcard local*.tex)
	xelatex -no-pdf main 

# Before the normal LSP make begins, we need to make TeX from Rnw.
main.tex: main.Rnw $(wildcard chapters/*.Rnw) $(wildcard chapters/*.tex)
	Rscript \
	  -e "library(knitr)" \
	  -e "knitr::knit('$<','$@')"

# Make R files.
%.R: %.Rnw
	Rscript -e "Sweave('$^', driver=Rtangle())"

# Create only the book.
main.bbl: main.tex localbibliography.bib  
	xelatex -no-pdf main
	biber main


main.snd: main.bbl
	touch main.adx main.sdx main.ldx
	sed -i s/.*\\emph.*// main.adx 
	sed -i 's/hyperindexformat{\\\(infn {[0-9]*\)}/\1/' main.sdx
	sed -i 's/hyperindexformat{\\\(infn {[0-9]*\)}/\1/' main.adx
	sed -i 's/hyperindexformat{\\\(infn {[0-9]*\)}/\1/' main.ldx
# 	python3 fixindex.py
# 	mv mainmod.adx main.adx
	makeindex -o main.and main.adx
	makeindex -o main.lnd main.ldx
	makeindex -o main.snd main.sdx 
	xelatex main 
 

cover: FORCE
	convert main.pdf\[0\] -quality 100 -background white -alpha remove -bordercolor "#999999" -border 2  cover.png
	cp cover.png googlebooks_frontcover.png
	convert -geometry 50x50% cover.png covertwitter.png
	convert main.pdf\[0\] -quality 100 -background white -alpha remove -bordercolor "#999999" -border 2  -resize x495 coveromp.png
	display cover.png


googlebooks: googlebooks_interior.pdf

googlebooks_interior.pdf: complete
	cp main.pdf googlebooks_interior.pdf
	pdftk main.pdf cat 1 output googlebooks_frontcover.pdf 

openreview: openreview.pdf
	

openreview.pdf: main.pdf
	pdftk main.pdf multistamp orstamp.pdf output openreview.pdf 

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
	
proofreading.pdf: main.pdf
	pdftk main.pdf multistamp prstamp.pdf output proofreading.pdf 

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
	*.run.xml main.tex main.pgs main.bcf \
	chapters/*aux chapters/*~ chapters/*.bak chapters/*.backup \
	langsci/*/*aux langsci/*/*~ langsci/*/*.bak langsci/*/*.backup \
	cache/* figures/* cache*.*
	
realclean: clean
	rm -f *.dvi *.ps

chapterlist:
	grep chapter main.toc|sed "s/.*numberline {[0-9]\+}\(.*\).newline.*/\\1/" 

podcover:
	bash podcovers.sh

FORCE:
