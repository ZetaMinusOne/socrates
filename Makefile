.PHONY: build clean check

build:
	python3 scripts/strip_cue.py

clean:
	find socrates/protocols -name '*.opt.cue' -delete

check:
	python3 scripts/strip_cue.py
	@git diff --exit-code socrates/protocols/ > /dev/null 2>&1 && echo "Protocol files are up to date." || (echo "Protocol files are stale — run 'make build' and commit the changes."; exit 1)
