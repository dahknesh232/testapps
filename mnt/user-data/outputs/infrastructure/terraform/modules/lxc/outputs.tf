# =============================================================================
# modules/lxc/outputs.tf
# =============================================================================

output "vmid" {
  description = "VMID of the created LXC."
  value       = proxmox_virtual_environment_container.lxc.vm_id
}

output "hostname" {
  description = "Hostname of the created LXC."
  value       = proxmox_virtual_environment_container.lxc.initialization[0].hostname
}

output "ip_address" {
  description = "IP address (with CIDR) of the created LXC."
  value       = proxmox_virtual_environment_container.lxc.initialization[0].ip_config[0].ipv4[0].address
}
