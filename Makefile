.PHONY: fmt validate preflight plan apply

TF_DIR ?= infra/terraform/live/personal

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) init -backend=false
	terraform -chdir=$(TF_DIR) validate

preflight:
	./scripts/tf_preflight.sh

plan:
	./scripts/tf_plan.sh

apply:
	./scripts/tf_apply.sh
