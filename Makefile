.PHONY: fmt validate preflight plan apply create destroy deploy-openclaw

TF_DIR ?= infra/terraform/live/production
TF_VALIDATE_DATA_DIR ?= /tmp/hello-my-oc-tf-validate

ifdef AWS_PROFILE
export AWS_PROFILE
endif

ifdef AWS_REGION
export AWS_REGION
endif

ifdef AWS_DEFAULT_REGION
export AWS_DEFAULT_REGION
endif

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

create: apply

destroy:
	./scripts/tf_destroy.sh

deploy-openclaw:
	./scripts/deploy_openclaw.sh
