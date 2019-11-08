##### Functions #####

# Evaluates to $(1) if $(1) non-empty, otherwise evaluates to $(2)
def_if_empty = $(if $(1),$(1),$(2))

# Dereference variable $(1), return value if non-empty, otherwise raise an error.
err_if_empty = $(if $(strip $($(1))),$(strip $($(1))),$(error Required variable $(1) is undefined or empty))

# Export variable $(1) to subsequent shell environments if contents are non-empty
export_full = $(eval export $(if $(call err_if_empty,$(1)),$(1)))

# Evaluate to the value of $(1) if $(CI) is the literal string "true", else $(2)
if_ci_else = $(if $(findstring true,$(CI)),$(1),$(2))

##### Important Paths and variables #####

# Default base path to directory containing terraform files
TFM_DIR ?= ./terraform

# Base configuration path for all terraform workspaces and configurations
override _TFM_DIR := $(abspath $(call err_if_empty,TFM_DIR))
APB_DIR ?= ./ansible
override _APB_DIR := $(abspath $(call err_if_empty,APB_DIR))

# Input variables for terraform execution of Ansible-playbook
export TF_VAR_ANSIBLE_INVDIR := $(abspath $(_APB_DIR)/inventory)
export TF_VAR_ANSIBLE_PBPATH := $(abspath $(_APB_DIR)/site.yml)

# Location of backend configuration
TF_BE_CFG ?= backend.cfg
override _TF_BE_CFG := $(call err_if_empty,TF_BE_CFG)

# Disable prompts for input when CI==true (Terraform Magic)
export TF_INPUT := $(call if_ci_else,false,true)

# Less output detail when CI==true; only empty/non-empty recognized (Terraform Magic)
export TF_IN_AUTOMATION := $(call if_ci_else,1,)

# Disable yes/no approval prompting when CI==true; CLI arg only
override _TF_AUTOAPPROVE := $(call if_ci_else,-auto-approve,)

# Phony target tracking files
override _TF_INIT_FILE := $(_TFM_DIR)/.initialized
override _TF_PLAN_FILE := $(_TFM_DIR)/plan.bin

# Applying state needs to invalidate old plans
override _TF_STATE_FILE := ./terraform.tfstate

##### Targets #####

# Disable yes/no approval prompting when CI==true; CLI arg only
override _HLPFMT = "%-20s %s\n"
.PHONY: help
help: ## Default target, parses special in-line comments as documentation.
	@printf $(_HLPFMT) "Valid targets:" "Purpose/description:"
	@printf $(_HLPFMT) "--------------" "--------------------"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf $(_HLPFMT), $$1, $$2}'

# Terraform backend must pre-exist and it's configuration often requires secrets
$(_TF_BE_CFG): $(_TFM_DIR)/backend.tf
	$(call export_full,secret_magic_juju)
	-rm -vf $(_TF_INIT_FILE)
	bin/create_backend.sh $< $@

.PHONY: init
init: $(_TF_INIT_FILE) ## Initialize Terraform plugins and backend
$(_TF_INIT_FILE): $(_TF_BE_CFG)
	terraform init -backend-config="$(_TF_BE_CFG)" "$(_TFM_DIR)" | tee $@

.PHONY: plan
plan: $(_TF_PLAN_FILE) ## Regenerate plan for infrastructure creation and/or changes
$(_TF_PLAN_FILE): $(_TF_INIT_FILE) $(wildcard $(_TFM_DIR)/*.tf)
	terraform plan "-out=$@" "$(_TFM_DIR)"

.PHONY: apply
apply: $(_TF_STATE_FILE) ## Realize infrastructure based on plan
$(_TF_STATE_FILE): $(_TF_PLAN_FILE)
	terraform apply $(_TF_AUTOAPPROVE) $< | tee -a $(_TFM_DIR)/terraform.log

.PHONY: clean
clean: ## Remove all generated files referenced in this Makefile
	-rm -vf $(_TF_BE_CFG) $(_TF_INIT_FILE) $(_TF_PLAN_FILE)
