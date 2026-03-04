#!/usr/bin/env bash
# =============================================================================
# bootstrap-runner.sh
# Run from any Proxmox node shell as root.
# Creates runner-01 LXC with Terraform, Ansible, Git, Python3.
#
# Usage:
#   chmod +x bootstrap-runner.sh
#   ./bootstrap-runner.sh
#
# Requirements:
#   - Run as root on a Proxmox node
#   - Proxmox node must have internet access
#   - Debian 12 CT template must be available (script will download if missing)
#
# Execution order:
#   1.  Preflight checks
#   2.  Ensure CT template exists
#   3.  Create LXC
#   4.  Start LXC (initial boot)
#   5.  Install base packages + locales package
#   6.  Configure locale and PATH across all environment sources,
#       then perform a full LXC stop/start so every subsequent pct exec
#       shell inherits a clean, fully-initialised environment
#   7.  Install Terraform via HashiCorp apt repo
#   8.  Install Ansible and Python dependencies via pip
#   9.  Install Ansible Galaxy collections
#   10. Create ansible user and SSH keypair
#   11. Harden SSH
#   12. Create project directory structure
#   13. Print summary
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
# Edit these values to match your environment before running.

RUNNER_VMID="200"
RUNNER_HOSTNAME="runner-01"
RUNNER_IP="192.168.0.160/24"
RUNNER_GW="192.168.0.1"
RUNNER_DNS="192.168.0.1"
RUNNER_CORES="2"
RUNNER_MEMORY="4096"
RUNNER_DISK="80"
RUNNER_BRIDGE="vmbr0"
RUNNER_STORAGE="local-lvm"
TEMPLATE_STORAGE="local"

DEBIAN_TEMPLATE="debian-12-standard_12.12-1_amd64.tar.zst"
TEMPLATE_PATH="${TEMPLATE_STORAGE}:vztmpl/${DEBIAN_TEMPLATE}"

# SSH public key injected into runner.
# Generate with: ssh-keygen -t ed25519 -C "proxmox-runner"
SSH_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItj0O5hq2xti/9HbB6H2LAOIieLhaquUdKyRCmb3asw proxmox-runner"

# ── Constants ─────────────────────────────────────────────────────────────────
readonly LOCALE="en_US.UTF-8"
readonly CONTAINER_READY_TIMEOUT=30
readonly CONTAINER_STOP_TIMEOUT=30

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Shared: wait for container to accept exec commands ────────────────────────
# Single responsibility: block until the container is responsive.
# Called after both the initial start and the post-locale restart.
wait_for_container() {
    log_info "Waiting for container ${RUNNER_VMID} to be ready..."
    local attempts=0

    until pct exec "${RUNNER_VMID}" -- test -f /etc/debian_version 2>/dev/null; do
        attempts=$((attempts + 1))
        if [[ ${attempts} -ge ${CONTAINER_READY_TIMEOUT} ]]; then
            log_error "Container did not become ready after ${CONTAINER_READY_TIMEOUT} attempts."
            exit 1
        fi
        sleep 2
    done

    log_success "Container is ready."
}

# ── 1. Preflight checks ───────────────────────────────────────────────────────
preflight_checks() {
    log_info "Running preflight checks..."

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root on a Proxmox node."
        exit 1
    fi

    if ! command -v pvesh &>/dev/null; then
        log_error "pvesh not found. This script must run on a Proxmox node."
        exit 1
    fi

    if pct status "${RUNNER_VMID}" &>/dev/null; then
        log_error "VMID ${RUNNER_VMID} already exists."
        log_error "Destroy it first: pct stop ${RUNNER_VMID} && pct destroy ${RUNNER_VMID}"
        exit 1
    fi

    if [[ "${SSH_PUBLIC_KEY}" == *"YOUR_KEY_HERE"* ]]; then
        log_error "Replace SSH_PUBLIC_KEY with your actual public key before running."
        log_error "Generate one with: ssh-keygen -t ed25519 -C 'proxmox-runner'"
        exit 1
    fi

    log_success "Preflight checks passed."
}

# ── 2. Ensure CT template ─────────────────────────────────────────────────────
ensure_template() {
    log_info "Checking for Debian 12 CT template..."

    if pveam list "${TEMPLATE_STORAGE}" 2>/dev/null | grep -q "${DEBIAN_TEMPLATE}"; then
        log_success "Template already present."
        return 0
    fi

    log_info "Template not found. Downloading..."
    pveam update
    pveam download "${TEMPLATE_STORAGE}" "${DEBIAN_TEMPLATE}" || {
        log_error "Failed to download template. Check internet connectivity and storage."
        exit 1
    }
    log_success "Template downloaded."
}

# ── 3. Create LXC ─────────────────────────────────────────────────────────────
create_runner_lxc() {
    log_info "Creating ${RUNNER_HOSTNAME} LXC (VMID: ${RUNNER_VMID})..."

    pct create "${RUNNER_VMID}" "${TEMPLATE_PATH}" \
        --hostname "${RUNNER_HOSTNAME}" \
        --cores   "${RUNNER_CORES}" \
        --memory  "${RUNNER_MEMORY}" \
        --rootfs  "${RUNNER_STORAGE}:${RUNNER_DISK}" \
        --net0    name=eth0,bridge="${RUNNER_BRIDGE}",ip="${RUNNER_IP}",gw="${RUNNER_GW}" \
        --nameserver   "${RUNNER_DNS}" \
        --searchdomain "local" \
        --ssh-public-keys <(echo "${SSH_PUBLIC_KEY}") \
        --unprivileged 1 \
        --features nesting=1 \
        --ostype debian \
        --start 0

    log_success "LXC created."
}

# ── 4. Start LXC (initial boot) ───────────────────────────────────────────────
start_lxc() {
    log_info "Starting ${RUNNER_HOSTNAME}..."
    pct start "${RUNNER_VMID}"
    wait_for_container
}

# ── 5. Install base packages ──────────────────────────────────────────────────
install_base_packages() {
    log_info "Updating package lists..."
    pct exec "${RUNNER_VMID}" -- bash -c "apt-get update -qq"

    log_info "Installing base packages..."
    pct exec "${RUNNER_VMID}" -- bash -c "
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            curl \
            wget \
            git \
            gnupg \
            lsb-release \
            locales \
            ca-certificates \
            software-properties-common \
            python3 \
            python3-pip \
            python3-venv \
            unzip \
            jq \
            vim \
            openssh-server \
            kubectl \
            sudo
    "
    log_success "Base packages installed."
}

# ── 6. Configure locale and PATH, then restart ───────────────────────────────
# Debian 12 minimal LXC templates ship with no locale generated. Python,
# Ansible, and Perl all fail without it. Writing to /etc/environment and
# /etc/profile.d alone is insufficient because pct exec uses lxc-attach which
# spawns a minimal shell that bypasses PAM and does not source those files.
# The only reliable fix is to write locale to all sources and then perform a
# full LXC stop/start. After restart, systemd re-initialises the container
# environment from scratch and all subsequent pct exec shells inherit LANG,
# LC_ALL, and PATH correctly without any inline prefixes needed.
configure_locale_and_restart() {
    log_info "Generating locale (${LOCALE})..."

    pct exec "${RUNNER_VMID}" -- bash -c "
        sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8
    "

    log_info "Writing locale and PATH to all environment sources..."

    # /etc/environment — read by PAM for all session types
    pct exec "${RUNNER_VMID}" -- bash -c "
        cat > /etc/environment << 'EOF'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US.UTF-8
EOF
    "

    # /etc/default/locale — read by systemd and init on container start
    pct exec "${RUNNER_VMID}" -- bash -c "
        cat > /etc/default/locale << 'EOF'
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US.UTF-8
EOF
    "

    # /etc/profile.d — sourced by interactive bash login shells (SSH sessions)
    pct exec "${RUNNER_VMID}" -- bash -c "
        cat > /etc/profile.d/99-locale-path.sh << 'EOF'
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
EOF
        chmod 0644 /etc/profile.d/99-locale-path.sh
    "

    log_success "Locale and PATH written to all environment sources."

    # Stop cleanly and wait before restarting
    log_info "Stopping LXC for clean restart..."
    pct stop "${RUNNER_VMID}"

    local attempts=0
    until [[ "$(pct status "${RUNNER_VMID}" | awk '{print $2}')" == "stopped" ]]; do
        attempts=$((attempts + 1))
        if [[ ${attempts} -ge ${CONTAINER_STOP_TIMEOUT} ]]; then
            log_error "Container did not stop cleanly within timeout."
            exit 1
        fi
        sleep 2
    done

    log_info "Restarting LXC..."
    pct start "${RUNNER_VMID}"
    wait_for_container

    log_success "LXC restarted — locale and PATH are now active for all shell environments."
}

# ── 7. Install Terraform ──────────────────────────────────────────────────────
# Installed via the official HashiCorp apt repository.
# The distro codename is resolved on the Proxmox host shell to avoid subshell
# expansion being lost across the pct exec boundary.
install_terraform() {
    log_info "Installing Terraform..."

    local codename
    codename=$(pct exec "${RUNNER_VMID}" -- lsb_release -cs)

    if [[ -z "${codename}" ]]; then
        log_error "Could not determine distro codename. Is lsb-release installed?"
        exit 1
    fi

    log_info "Detected distro codename: ${codename}"

    pct exec "${RUNNER_VMID}" -- bash -c "
        wget -O- https://apt.releases.hashicorp.com/gpg \
            | gpg --dearmor \
            | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    "

    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${codename} main" \
        | pct exec "${RUNNER_VMID}" -- tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

    pct exec "${RUNNER_VMID}" -- bash -c "
        DEBIAN_FRONTEND=noninteractive apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq terraform
    "

    local tf_version
    tf_version=$(pct exec "${RUNNER_VMID}" -- /usr/bin/terraform version -json \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])")

    log_success "Terraform ${tf_version} installed."
}

# ── 8. Install Ansible + Dependencies ────────────────────────────────────────────────────────
# Installed via pip as root. After the locale restart, LANG, LC_ALL, and PATH
# are all initialised correctly — no inline environment prefixes required.
install_ans() {
    log_info "Installing Ansible..."

    pct exec "${RUNNER_VMID}" -- bash -c "
        DEBIAN_FRONTEND=noninteractive apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible
    " 

}


install_ansibledep() {
    log_info "Installing Ansible + Python dependencies via pip..."

    pct exec "${RUNNER_VMID}" -- bash -c "
        python3 -m pip install --quiet --break-system-packages \
            ansible-lint \
            jmespath \
            netaddr \
            hvac \
            proxmoxer \
            requests
    "

    local ansible_version
    ansible_version=$(pct exec "${RUNNER_VMID}" -- ansible --version | head -1)
    log_success "${ansible_version} installed."
}

# ── 9. Install Ansible Galaxy collections ────────────────────────────────────
# --quiet must immediately follow 'collection install' — it is a subcommand
# flag, not a top-level ansible-galaxy flag.
install_galaxy_collections() {
    log_info "Installing Ansible Galaxy collections..."

    pct exec "${RUNNER_VMID}" -- ansible-galaxy collection install \
        community.general \
        community.docker \
        community.crypto \
        ansible.posix \
        kubernetes.core

    log_success "Galaxy collections installed."
}

# ── 10. Create ansible user ───────────────────────────────────────────────────
create_ansible_user() {
    log_info "Creating ansible user..."

    pct exec "${RUNNER_VMID}" -- bash -c "
        useradd -m -s /bin/bash -G sudo ansible
        echo 'ansible ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible
        chmod 0440 /etc/sudoers.d/ansible
        mkdir -p /home/ansible/.ssh
        echo '${SSH_PUBLIC_KEY}' > /home/ansible/.ssh/authorized_keys
        chmod 700 /home/ansible/.ssh
        chmod 600 /home/ansible/.ssh/authorized_keys
        chown -R ansible:ansible /home/ansible/.ssh
    "

    log_info "Generating ansible SSH keypair for connecting to other LXCs..."
    pct exec "${RUNNER_VMID}" -- bash -c "
        su - ansible -c \"ssh-keygen -t ed25519 -f /home/ansible/.ssh/id_ed25519 -N '' -C 'ansible-runner-01'\"
    "

    log_success "ansible user created."
    log_warn "IMPORTANT — copy this public key, you will need it in terraform.tfvars:"
    echo ""
    pct exec "${RUNNER_VMID}" -- cat /home/ansible/.ssh/id_ed25519.pub
    echo ""
}

# ── 11. Harden SSH ────────────────────────────────────────────────────────────
harden_ssh() {
    log_info "Hardening SSH configuration..."

    pct exec "${RUNNER_VMID}" -- bash -c "
        cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
X11Forwarding no
AllowTcpForwarding no
MaxAuthTries 3
LoginGraceTime 20
EOF
        systemctl restart ssh
    "
    log_success "SSH hardened."
}

# ── 12. Create project directory structure ────────────────────────────────────
create_project_structure() {
    log_info "Creating project directory structure..."

    pct exec "${RUNNER_VMID}" -- bash -c "
        mkdir -p /home/ansible/infrastructure/{terraform,ansible}
        mkdir -p /home/ansible/infrastructure/terraform/modules/lxc
        mkdir -p /home/ansible/infrastructure/ansible/{inventory,playbooks,roles}
        mkdir -p /home/ansible/infrastructure/ansible/inventory/group_vars/{all,controllers,workers}
        mkdir -p /home/ansible/.vault
        mkdir -p /home/ansible/..kube
        chmod 700 /home/ansible/.vault
        chmod 700 /home/ansible/.kube
        chown -R ansible:ansible /home/ansible/infrastructure
        chown -R ansible:ansible /home/ansible/.vault
        chown -R ansible:ansible /home/ansible/.kube
    "
    log_success "Project structure created at /home/ansible/infrastructure/"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Bootstrap Complete — ${RUNNER_HOSTNAME} is ready      ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  VMID:        ${YELLOW}${RUNNER_VMID}${NC}"
    echo -e "  Hostname:    ${YELLOW}${RUNNER_HOSTNAME}${NC}"
    echo -e "  IP Address:  ${YELLOW}${RUNNER_IP%/*}${NC}"
    echo ""
    echo -e "  Connect via: ${YELLOW}ssh ansible@${RUNNER_IP%/*}${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. SSH into runner-01 as the ansible user"
    echo "  2. Copy your values into:"
    echo "     /home/ansible/infrastructure/terraform/terraform.tfvars"
    echo "  3. Create your Proxmox API token in the Proxmox UI:"
    echo "     Datacenter > Permissions > API Tokens > Add"
    echo "  4. Run: cd /home/ansible/infrastructure/terraform && terraform init"
    echo "  5. Run: terraform plan"
    echo "  6. Run: terraform apply"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Proxmox Bootstrap — Creating ${RUNNER_HOSTNAME} LXC  ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""

    preflight_checks
    ensure_template
    create_runner_lxc
    start_lxc
    configure_locale_and_restart
    install_base_packages
    install_terraform
    install_ans
    install_ansibledep
    install_galaxy_collections
    create_ansible_user
    harden_ssh
    create_project_structure
    print_summary
}

main "$@"