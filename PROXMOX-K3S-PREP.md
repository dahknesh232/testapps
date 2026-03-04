# Proxmox Host — k3s LXC Preparation Runbook

## Overview

Before running `ansible-playbook playbooks/site.yml`, the Proxmox host
requires manual preparation to allow k3s to function inside unprivileged LXCs.

These steps are intentionally manual. They involve kernel modules, cgroup
device permissions, and AppArmor policy — decisions that should be made
deliberately and reviewed when infrastructure changes.

**Proxmox Host:** house-aboo (192.168.0.20)
**k3s LXC VMIDs:** 210 (k8s-control), 211 (k8s-worker-01), 212 (k8s-worker-02)

---

## Step 1 — Load Kernel Modules on Proxmox Host

SSH into the Proxmox host as root and run:

```bash
# Load immediately
modprobe br_netfilter
modprobe overlay

# Persist across reboots
echo "br_netfilter" >> /etc/modules
echo "overlay" >> /etc/modules
```

These modules must be loaded at the **host** level. LXCs share the host
kernel and cannot load modules independently.

---

## Step 2 — Update LXC Configs

For each k3s LXC (210, 211, 212), append the following to its config file.
The LXC must be stopped first.

```bash
for vmid in 210 211 212; do
  pct stop ${vmid}

  # AppArmor — allow unconfined (required for containerd)
  echo "lxc.apparmor.profile: unconfined"          >> /etc/pve/lxc/${vmid}.conf

  # cgroup device access — allow all devices
  echo "lxc.cgroup2.devices.allow: a"              >> /etc/pve/lxc/${vmid}.conf

  # kmsg char device — required by kubelet OOM watcher
  echo "lxc.cgroup2.devices.allow: c 1:11 rwm"     >> /etc/pve/lxc/${vmid}.conf

  # Bind mount /dev/kmsg from host into LXC
  echo "lxc.mount.entry: /dev/kmsg dev/kmsg none bind,create=file" \
                                                    >> /etc/pve/lxc/${vmid}.conf

  # Auto-mount proc, sys, and cgroup with rw access
  echo "lxc.mount.auto: proc:rw sys:rw cgroup:rw"  >> /etc/pve/lxc/${vmid}.conf

  pct start ${vmid}
done
```

---

## Step 3 — Verify LXCs Are Reachable

```bash
ansible k8s_nodes -m ping
```

All three nodes should return `pong` before proceeding.

---

## Step 4 — Run Ansible

```bash
ansible-playbook playbooks/provision-k8s.yml
```

Or as part of the full site run:

```bash
ansible-playbook playbooks/site.yml
```

---

## Notes on Each Setting

| Setting | Why Required |
|---|---|
| `lxc.apparmor.profile: unconfined` | containerd/runc needs to write OCI runtime configs |
| `lxc.cgroup2.devices.allow: a` | kubelet needs full cgroup device access |
| `lxc.cgroup2.devices.allow: c 1:11 rwm` | `/dev/kmsg` char device (major 1, minor 11) |
| `lxc.mount.entry: /dev/kmsg` | kubelet opens `/dev/kmsg` for OOM watcher |
| `lxc.mount.auto: proc:rw sys:rw cgroup:rw` | k3s reads/writes proc and cgroup paths |
| `modprobe br_netfilter` | flannel/iptables network bridging |
| `modprobe overlay` | containerd overlay filesystem driver |

---

## Troubleshooting

**`open /dev/kmsg: no such file or directory`**
→ kmsg bind mount not applied or LXC not restarted after config change.

**`open /dev/kmsg: operation not permitted`**
→ kmsg mount exists but cgroup device permission `c 1:11 rwm` is missing.

**`failed to start sandbox: OCI runtime create failed: open sysctl net.ipv4.ip_unprivileged_port_start`**
→ `KubeletInUserNamespace=true` feature gate missing from `/etc/rancher/k3s/config.yaml`.
   The Ansible role writes this automatically — only occurs if k3s was installed before the role ran.

**`token CA hash does not match`**
→ Workers have a stale token from a previous k3s bootstrap.
   Re-run `provision-k8s.yml` — the role reads the current `agent-token` from the control plane.
