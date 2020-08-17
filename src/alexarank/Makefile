DATA=20100623-top-1m.csv

.PHONY: all
all: $(DATA) run

$(DATA):
	xz -dcv ../../dat/alexa-top-1m/20100623-top-1m.csv.xz > $@

.PHONY: run
run:
	gradle run --args "../../alexa/20100623-top-1m.csv ../../alexa/cw09_host_docno.csv" \
		| grep ^clue > docno_alexarank.txt
