# =============================================================================
# main.tf
# Provisions Controller, Worker, and K8s cluster LXCs across the Proxmox cluster.
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
}

## ── Vault LXC ─────────────────────────────────────────────────────────────────
#
#module "vault" {
#  source = "./modules/lxc"
#
#  vmid          = var.vmid_vault
#  hostname      = "vault-01"
#  node          = var.node_vault
#  template      = local.debian_template_ref
#  storage       = var.storage_vault
#  disk_size     = 16
#  cores         = 2
#  memory        = 2048
#  swap          = 512
#  ip_address    = var.ip_vault
#  gateway       = var.network_gateway
#  dns_server    = var.network_dns
#  search_domain = var.network_domain
#  bridge        = var.network_bridge
#  ssh_public_key = var.ansible_public_key
#  unprivileged  = true
#  nesting       = true
#
#  tags = ["vault", "infrastructure", "always-on"]
#
#  description = "HashiCorp Vault secret store. Managed by Terraform + Ansible."
#}

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

# ── K8s Control Plane ─────────────────────────────────────────────────────────

module "k8s_control" {
  source = "./modules/lxc"

  vmid          = var.vmid_k8s_control
  hostname      = "k8s-control"
  node          = var.node_k8s
  template      = local.debian_template_ref
  storage       = var.storage_k8s
  disk_size     = 16
  cores         = 2
  memory        = 4096
  swap          = 512
  ip_address    = var.ip_k8s_control
  gateway       = var.network_gateway
  dns_server    = var.network_dns
  search_domain = var.network_domain
  bridge        = var.network_bridge
  ssh_public_key = var.ansible_public_key
  unprivileged  = true
  nesting       = true

  tags = ["k8s", "control-plane", "k3s"]

  description = "K3s control plane node."
}

# ── K8s Worker 01 ─────────────────────────────────────────────────────────────

module "k8s_worker_01" {
  source = "./modules/lxc"

  vmid          = var.vmid_k8s_worker_01
  hostname      = "k8s-worker-01"
  node          = var.node_k8s
  template      = local.debian_template_ref
  storage       = var.storage_k8s
  disk_size     = 16
  cores         = 2
  memory        = 4096
  swap          = 512
  ip_address    = var.ip_k8s_worker_01
  gateway       = var.network_gateway
  dns_server    = var.network_dns
  search_domain = var.network_domain
  bridge        = var.network_bridge
  ssh_public_key = var.ansible_public_key
  unprivileged  = true
  nesting       = true

  tags = ["k8s", "worker", "k3s"]

  description = "K3s worker node 01."
}

# ── K8s Worker 02 ─────────────────────────────────────────────────────────────

module "k8s_worker_02" {
  source = "./modules/lxc"

  vmid          = var.vmid_k8s_worker_02
  hostname      = "k8s-worker-02"
  node          = var.node_k8s
  template      = local.debian_template_ref
  storage       = var.storage_k8s
  disk_size     = 16
  cores         = 2
  memory        = 4096
  swap          = 512
  ip_address    = var.ip_k8s_worker_02
  gateway       = var.network_gateway
  dns_server    = var.network_dns
  search_domain = var.network_domain
  bridge        = var.network_bridge
  ssh_public_key = var.ansible_public_key
  unprivileged  = true
  nesting       = true

  tags = ["k8s", "worker", "k3s"]

  description = "K3s worker node 02."
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
              ansible_host                 = split("/", var.ip_vault)[0]
              ansible_user                 = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
            }
          }
        }
        controllers = {
          hosts = {
            "controller-01" = {
              ansible_host                 = split("/", var.ip_controller)[0]
              ansible_user                 = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
            }
          }
        }
        workers = {
          hosts = {
            "worker-01" = {
              ansible_host                 = split("/", var.ip_worker_infra)[0]
              ansible_user                 = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
              worker_role                  = "infra"
            }
            "worker-02" = {
              ansible_host                 = split("/", var.ip_worker_app)[0]
              ansible_user                 = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
              worker_role                  = "app"
            }
          }
        }
        k8s_nodes = {
          hosts = {
            "k8s-control" = {
              ansible_host                 = split("/", var.ip_k8s_control)[0]
              ansible_user                 = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
              k8s_role                     = "control"
            }
            "k8s-worker-01" = {
              ansible_host                 = split("/", var.ip_k8s_worker_01)[0]
              ansible_user                 = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
              k8s_role                     = "worker"
            }
            "k8s-worker-02" = {
              ansible_host                 = split("/", var.ip_k8s_worker_02)[0]
              ansible_user                 = "ansible"
              ansible_ssh_private_key_file = "~/.ssh/id_ed25519"
              k8s_role                     = "worker"
            }
          }
        }
      }
    }
  })

  depends_on = [
    #    module.vault,
    module.controller,
    module.worker_infra,
    module.worker_app,
    module.k8s_control,
    module.k8s_worker_01,
    module.k8s_worker_02,
  ]
}
