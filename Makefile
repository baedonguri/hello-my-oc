.PHONY: fmt validate plan apply

TF_DIR ?= infra/terraform/live/personal

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) init -backend=false
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) init
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) init
	terraform -chdir=$(TF_DIR) apply
