# =============================================================================
# main.tf
# Provisions Vault, Controller, and Worker LXCs across the Proxmox cluster.
# Each LXC is targeted to a specific node to respect local storage layout.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# ── Provider ──────────────────────────────────────────────────────────────────

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure
}

# ── Local values ──────────────────────────────────────────────────────────────

locals {
  debian_template_ref = "${var.template_storage}:vztmpl/${var.debian_template}"

  # Shared LXC defaults applied to all nodes
  lxc_defaults = {
    unprivileged = true
    start        = true
    os_type      = "debian"
    features = {
      nesting = true
    }
  }
}

# ── Vault LXC ─────────────────────────────────────────────────────────────────

module "vault" {
  source = "./modules/lxc"

  vmid          = var.vmid_vault
  hostname      = "vault-01"
  node          = var.node_vault
  template      = local.debian_template_ref
  storage       = var.storage_vault
  disk_size     = 16
  cores         = 2
  memory        = 2048
  swap          = 512
  ip_address    = var.ip_vault
  gateway       = var.network_gateway
  dns_server    = var.network_dns
  search_domain = var.network_domain
  bridge        = var.network_bridge
  ssh_public_key = var.ansible_public_key
  unprivileged  = true
  nesting       = true

  tags = ["vault", "infrastructure", "always-on"]

  description = "HashiCorp Vault secret store. Managed by Terraform + Ansible."
}

# ── Controller LXC ────────────────────────────────────────────────────────────

module "controller" {
  source = "./modules/lxc"

  vmid          = var.vmid_controller
  hostname      = "controller-01"
  node          = var.node_controller
  template      = local.debian_template_ref
  storage       = var.storage_controller
  disk_size     = 32
  cores         = 4
  memory        = 4096
  swap          = 1024
  ip_address    = var.ip_controller
  gateway       = var.network_gateway
  dns_server    = var.network_dns
  search_domain = var.network_domain
  bridge        = var.network_bridge
  ssh_public_key = var.ansible_public_key
  unprivileged  = true
  nesting       = true

  tags = ["ansible", "controller", "infrastructure", "always-on"]

  description = "Ansible Controller (AWX-style). Manages playbook execution and inventory."
}

# ── Worker 01 — Infra ─────────────────────────────────────────────────────────

module "worker_infra" {
  source = "./modules/lxc"

  vmid          = var.vmid_worker_infra
  hostname      = "worker-01"
  node          = var.node_worker_infra
  template      = local.debian_template_ref
  storage       = var.storage_worker_infra
  disk_size     = 32
  cores         = 4
  memory        = 4096
  swap          = 1024
  ip_address    = var.ip_worker_infra
  gateway       = var.network_gateway
  dns_server    = var.network_dns
  search_domain = var.network_domain
  bridge        = var.network_bridge
  ssh_public_key = var.ansible_public_key
  unprivileged  = true
  nesting       = true

  tags = ["ansible", "worker", "infra"]

  description = "Ansible Worker 1 — Infra. Handles Proxmox API, LXC lifecycle, KIND provisioning."
}

# ── Worker 02 — App ───────────────────────────────────────────────────────────

module "worker_app" {
  source = "./modules/lxc"

  vmid          = var.vmid_worker_app
  hostname      = "worker-02"
  node          = var.node_worker_app
  template      = local.debian_template_ref
  storage       = var.storage_worker_app
  disk_size     = 48
  cores         = 4
  memory        = 6144
  swap          = 1024
  ip_address    = var.ip_worker_app
  gateway       = var.network_gateway
  dns_server    = var.network_dns
  search_domain = var.network_domain
  bridge        = var.network_bridge
  ssh_public_key = var.ansible_public_key
  unprivileged  = true
  nesting       = true

  tags = ["ansible", "worker", "app"]

  description = "Ansible Worker 2 — App. Handles K8s manifests, Docker, Keycloak, Node.js deployment."
}

# ── Generate Ansible inventory from Terraform outputs ─────────────────────────

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.yml"
  file_permission = "0640"

  content = yamlencode({
    all = {
      children = {
        vault_servers = {
          hosts = {
            "vault-01" = {
              ansible_host = split("/", var.ip_vault)[0]
              ansible_user = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
            }
          }
        }
        controllers = {
          hosts = {
            "controller-01" = {
              ansible_host = split("/", var.ip_controller)[0]
              ansible_user = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
            }
          }
        }
        workers = {
          hosts = {
            "worker-01" = {
              ansible_host  = split("/", var.ip_worker_infra)[0]
              ansible_user  = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
              worker_role   = "infra"
            }
            "worker-02" = {
              ansible_host  = split("/", var.ip_worker_app)[0]
              ansible_user  = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
              worker_role   = "app"
            }
          }
        }
      }
    }
  })

  depends_on = [
    module.vault,
    module.controller,
    module.worker_infra,
    module.worker_app
  ]
}
