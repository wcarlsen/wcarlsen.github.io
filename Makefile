.PHONY: run build deploy

run:
	mkdocs serve

build:
	mkdocs build

deploy:
	git config user.name github-actions[bot]
	git config user.email 41898282+github-actions[bot]@users.noreply.github.com
	mkdocs gh-deploy --force
