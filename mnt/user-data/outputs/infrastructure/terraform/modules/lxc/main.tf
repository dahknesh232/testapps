# =============================================================================
# modules/lxc/main.tf
# Reusable module for creating a single hardened LXC container.
# Called once per LXC with role-specific parameters from main.tf.
# =============================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

resource "proxmox_virtual_environment_container" "lxc" {
  vm_id       = var.vmid
  node_name   = var.node
  description = var.description
  tags        = var.tags
  started     = true
  unprivileged = var.unprivileged

  operating_system {
    template_file_id = var.template
    type             = "debian"
  }

  initialization {
    hostname = var.hostname

    dns {
      server  = var.dns_server
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys = [trimspace(var.ssh_public_key)]
    }
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = var.storage
    size         = var.disk_size
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  features {
    nesting = var.nesting
  }

  # Prevent accidental destruction of infrastructure LXCs
  lifecycle {
    prevent_destroy = false  # Set true after initial setup is verified
    ignore_changes  = [
      # Ignore changes to started state — Ansible manages service lifecycle
      started,
    ]

  }
}

