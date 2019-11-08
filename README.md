# Terr-ansi-form-able

It slices! It dices! It welds! It grinds! It will even drive the kids to school!
This is an example of using GNU Make to drive Terraform and Ansible together.

***Note:*** This tool-chain is not recommended for large-scale use, it really only
makes sense for small-scale automation and standalone one-offs.

# Example of the example

Assumes recent (2020) versions of make, Ansible, and terraform are installed.  Note:
Some paths in the output below, have been truncated for clarity and line-length.

```
$ make
Valid targets:       Purpose/description:
--------------       --------------------
help                 Default target, parses special in-line comments as documentation.
init                 Initialize Terraform plugins and backend
plan                 Regenerate plan for infrastructure creation and/or changes
apply                Realize infrastructure based on plan
clean                Remove all generated files referenced in this Makefile
```

```
rm -vf ./terraform/.initialized
bin/create_backend.sh ./terraform/backend.tf backend.cfg
terraform init -backend-config="backend.cfg" "./terraform" | tee ./terraform/.initialized

Initializing the backend...

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.local: version = "~> 1.4"
* provider.null: version = "~> 2.1"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
terraform plan "-out=./terraform/plan.bin" "./terraform"
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.ansible_inventory will be created
  + resource "local_file" "ansible_inventory" {
      + content              = "\"all\":\n  \"hosts\":\n    \"testhost\":\n      \"ansible_connection\": \"local\"\n      \"ansible_host\": \"127.0.0.1\"\n"
      + directory_permission = "0777"
      + file_permission      = "0644"
      + filename             = "./ansible/inventory/terraform_hosts.yml"
      + id                   = (known after apply)
    }

  # null_resource.ansible_playbook will be created
  + resource "null_resource" "ansible_playbook" {
      + id = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: ./terraform/plan.bin

To perform exactly these actions, run the following command to apply:
    terraform apply "./terraform/plan.bin"

terraform apply  ./terraform/plan.bin | tee -a ./terraform/terraform.log
local_file.ansible_inventory: Creating...
local_file.ansible_inventory: Creation complete after 0s [id=ba7683e29fef4fd72e316a79ea70d767f55bc2dc]
null_resource.ansible_playbook: Creating...
null_resource.ansible_playbook: Provisioning with 'local-exec'...
null_resource.ansible_playbook (local-exec): Executing: ["/bin/sh" "-c" "ansible-playbook -i ./ansible/inventory site.yml | tee -a site.log"]

null_resource.ansible_playbook (local-exec): PLAY [localhost] ***************************************************************

null_resource.ansible_playbook (local-exec): TASK [Gathering Facts] *********************************************************
null_resource.ansible_playbook (local-exec): ok: [localhost]

null_resource.ansible_playbook (local-exec): TASK [debug] *******************************************************************
null_resource.ansible_playbook (local-exec): ok: [localhost] => {
null_resource.ansible_playbook (local-exec):     "msg": "localhost is doing stuff"
null_resource.ansible_playbook (local-exec): }

null_resource.ansible_playbook (local-exec): PLAY [testhost] ****************************************************************

null_resource.ansible_playbook (local-exec): TASK [Gathering Facts] *********************************************************
null_resource.ansible_playbook (local-exec): ok: [testhost]

null_resource.ansible_playbook (local-exec): TASK [debug] *******************************************************************
null_resource.ansible_playbook (local-exec): ok: [testhost] => {
null_resource.ansible_playbook (local-exec):     "msg": "Usefull things could be happening"
null_resource.ansible_playbook (local-exec): }

null_resource.ansible_playbook (local-exec): PLAY RECAP *********************************************************************
null_resource.ansible_playbook (local-exec): localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
null_resource.ansible_playbook (local-exec): testhost                   : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

null_resource.ansible_playbook: Creation complete after 2s [id=7335517498039505606]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```
