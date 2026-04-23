.PHONY: run build deploy

run:
	mkdocs serve --strict --open

test:
	pre-commit run -a

build: test
	mkdocs build --strict

deploy:
	git config user.name github-actions[bot]
	git config user.email 41898282+github-actions[bot]@users.noreply.github.com
	mkdocs gh-deploy --strict --force
