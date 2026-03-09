.PHONY: init plan apply upgrade

plan: init
	tofu plan

apply: init
	tofu apply

init:
	tofu init

upgrade:
	tofu init -upgrade
