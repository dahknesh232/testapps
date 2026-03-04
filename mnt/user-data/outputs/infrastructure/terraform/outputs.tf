# =============================================================================
# outputs.tf
# Exposes key values after apply — used to verify deployment and
# feed into Ansible inventory generation.
# =============================================================================

#output "vault_ip" {
#  description = "IP address of vault-01"
#  value       = split("/", module.vault.ip_address)[0]
#}

output "controller_ip" {
  description = "IP address of controller-01"
  value       = split("/", module.controller.ip_address)[0]
}

output "worker_infra_ip" {
  description = "IP address of worker-01 (infra)"
  value       = split("/", module.worker_infra.ip_address)[0]
}

output "worker_app_ip" {
  description = "IP address of worker-02 (app)"
  value       = split("/", module.worker_app.ip_address)[0]
}

output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = "${path.module}/../ansible/inventory/hosts.yml"
}

output "next_steps" {
  description = "Instructions after terraform apply completes"
  value       = <<-EOT

    ════════════════════════════════════════════════════════
    Terraform apply complete. Next steps:
    ════════════════════════════════════════════════════════

    1. Run '.necessary' on all new LXCs
    
    2. run 'clearssh' on runner-01
    
    3. Verify all LXCs are reachable:
       ansible all -i ../ansible/inventory/hosts.yml -m ping

    4. Run '.k3snecc' on host for cluster

    5. Run the Ansible site playbook to configure all nodes:
       cd ../ansible
       ansible-playbook playbooks/site.yml
    ════════════════════════════════════════════════════════
  EOT
}
