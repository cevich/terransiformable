// In practice, all actual cloud resouces (VM's, etc.) would be defined here
// and included in the ansible_inventory below.  The resource dependency graph is key!

resource "local_file" "ansible_inventory" {
  filename = "${var.ANSIBLE_INVDIR}/terraform_hosts.yml"
  content = yamlencode({
    all = {
      hosts = {
        testhost = {
          ansible_host       = "127.0.0.1"
          ansible_connection = "local"
        }
      }
    }
  })
  file_permission = "0644"
}

locals {
  _ansible_pbdir  = dirname(var.ANSIBLE_PBPATH)
  _ansible_pbfile = basename(var.ANSIBLE_PBPATH)
  _ansible_pblog  = replace(local._ansible_pbfile, ".yml", ".log")
}

resource "null_resource" "ansible_playbook" {
  depends_on = [local_file.ansible_inventory] // var.ANSIBLE_INVDIR used in command below
  provisioner "local-exec" {
    working_dir = local._ansible_pbdir
    command     = "ansible-playbook -i ${var.ANSIBLE_INVDIR} ${local._ansible_pbfile} | tee -a ${local._ansible_pblog}"
  }
}
