# =============================================================================
# variables.tf
# All input variable definitions for the infrastructure module.
# Values are provided via terraform.tfvars (gitignored).
# =============================================================================

# ── Proxmox Connection ────────────────────────────────────────────────────────

variable "proxmox_api_url" {
  description = "Full URL to the Proxmox API endpoint. Use the cluster VIP if available."
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID in format: USER@REALM!TOKENNAME"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret value. Never commit this value."
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification. Set true only for self-signed certs in dev."
  type        = bool
  default     = false
}

# ── Cluster Node Names ────────────────────────────────────────────────────────

#variable "node_vault" {
#  description = "Proxmox node name to host the Vault LXC."
#  type        = string
#}

variable "node_controller" {
  description = "Proxmox node name to host the Ansible Controller LXC."
  type        = string
}

variable "node_worker_infra" {
  description = "Proxmox node name to host Worker 1 (infra) LXC."
  type        = string
}

variable "node_worker_app" {
  description = "Proxmox node name to host Worker 2 (app) LXC."
  type        = string
}

variable "node_k8s" {
  description = "Proxmox node name to host the K3s cluster LXCs."
  type        = string
}

# ── Storage ───────────────────────────────────────────────────────────────────

#variable "storage_vault" {
#  description = "Storage pool name on the Vault node."
#  type        = string
#  default     = "local-lvm"
#}

variable "storage_controller" {
  description = "Storage pool name on the Controller node."
  type        = string
  default     = "local-lvm"
}

variable "storage_worker_infra" {
  description = "Storage pool name on the Infra Worker node."
  type        = string
  default     = "local-lvm"
}

variable "storage_worker_app" {
  description = "Storage pool name on the App Worker node."
  type        = string
  default     = "local-lvm"
}

variable "storage_k8s" {
  description = "Storage pool name on the K8s node (house-aboo)."
  type        = string
  default     = "local-lvm"
}

variable "template_storage" {
  description = "Storage pool where CT templates are stored (usually 'local')."
  type        = string
  default     = "local"
}

# ── Network ───────────────────────────────────────────────────────────────────

variable "network_bridge" {
  description = "Proxmox network bridge to attach all LXCs to."
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Default gateway for all LXCs."
  type        = string
  default     = "192.168.0.1"
}

variable "network_dns" {
  description = "DNS server IP for all LXCs."
  type        = string
  default     = "192.168.0.1"
}

variable "network_domain" {
  description = "Search domain for all LXCs."
  type        = string
  default     = "home.arpa"
}

# ── IP Assignments ────────────────────────────────────────────────────────────

variable "ip_vault" {
  description = "Static IP with CIDR for vault-01."
  type        = string
  default     = "192.168.0.171/24"
}

variable "ip_controller" {
  description = "Static IP with CIDR for controller-01."
  type        = string
  default     = "192.168.0.172/24"
}

variable "ip_worker_infra" {
  description = "Static IP with CIDR for worker-01."
  type        = string
  default     = "192.168.0.173/24"
}

variable "ip_worker_app" {
  description = "Static IP with CIDR for worker-02."
  type        = string
  default     = "192.168.0.174/24"
}

variable "ip_k8s_control" {
  description = "Static IP with CIDR for k8s-control."
  type        = string
  default     = "192.168.0.180/24"
}

variable "ip_k8s_worker_01" {
  description = "Static IP with CIDR for k8s-worker-01."
  type        = string
  default     = "192.168.0.181/24"
}

variable "ip_k8s_worker_02" {
  description = "Static IP with CIDR for k8s-worker-02."
  type        = string
  default     = "192.168.0.182/24"
}

# ── VMID Assignments ──────────────────────────────────────────────────────────

#variable "vmid_vault" {
#  description = "VMID for vault-01 LXC."
#  type        = number
#  default     = 201
#}

variable "vmid_controller" {
  description = "VMID for controller-01 LXC."
  type        = number
  default     = 202
}

variable "vmid_worker_infra" {
  description = "VMID for worker-01 LXC."
  type        = number
  default     = 203
}

variable "vmid_worker_app" {
  description = "VMID for worker-02 LXC."
  type        = number
  default     = 204
}

variable "vmid_k8s_control" {
  description = "VMID for k8s-control LXC."
  type        = number
  default     = 210
}

variable "vmid_k8s_worker_01" {
  description = "VMID for k8s-worker-01 LXC."
  type        = number
  default     = 211
}

variable "vmid_k8s_worker_02" {
  description = "VMID for k8s-worker-02 LXC."
  type        = number
  default     = 212
}

# ── SSH ───────────────────────────────────────────────────────────────────────

variable "ansible_public_key" {
  description = "SSH public key from runner-01's ansible user. Injected into all provisioned LXCs."
  type        = string
}

# ── CT Template ───────────────────────────────────────────────────────────────

variable "debian_template" {
  description = "Debian 12 CT template filename in Proxmox template storage."
  type        = string
  default     = "debian-12-standard_12.12-1_amd64.tar.zst"
}
