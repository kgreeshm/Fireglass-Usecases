data "fmc_access_policies" "acp" {
    name = var.access_policy_name
}

resource "null_resource" "ztp" {
  provisioner "local-exec" {
    command = "python3 ${path.module}/ztp.py --host ${var.scc_host} --token ${var.scc_token} --password ${var.password} --acp ${data.fmc_access_policies.acp.id} --serial ${var.serial_numbers}"
  }
}

resource "null_resource" "delete_device" {
  triggers = {
    scc_token  = var.scc_token
    scc_host = var.scc_host
    serial_numbers = var.serial_numbers
  }

  provisioner "local-exec" {
    when    = destroy
    command = "python3 ${path.module}/delete.py --host ${self.triggers.scc_host} --token ${self.triggers.scc_token} --serial ${self.triggers.serial_numbers}"
  }
}