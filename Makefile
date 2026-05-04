.PHONY: fmt validate preflight plan apply deploy-openclaw

TF_DIR ?= infra/terraform/live/production
TF_VALIDATE_DATA_DIR ?= /tmp/hello-my-oc-tf-validate

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	TF_DATA_DIR=$(TF_VALIDATE_DATA_DIR) terraform -chdir=$(TF_DIR) init -backend=false
	TF_DATA_DIR=$(TF_VALIDATE_DATA_DIR) terraform -chdir=$(TF_DIR) validate

preflight:
	./scripts/tf_preflight.sh

plan:
	./scripts/tf_plan.sh

apply:
	./scripts/tf_apply.sh

deploy-openclaw:
	./scripts/deploy_openclaw.sh
