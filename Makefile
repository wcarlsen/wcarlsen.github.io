.PHONY: run build

run:
	zensical serve --open --strict

build:
	zensical build --clean --strict
