# =============================================================================
# modules/lxc/variables.tf
# =============================================================================

variable "vmid"           { type = number }
variable "hostname"       { type = string }
variable "node"           { type = string }
variable "template"       { type = string }
variable "storage"        { type = string }
variable "disk_size"      { type = number }
variable "cores"          { type = number }
variable "memory"         { type = number }
variable "swap"           { type = number }
variable "ip_address"     { type = string }
variable "gateway"        { type = string }
variable "dns_server"     { type = string }
variable "search_domain"  { type = string }
variable "bridge"         { type = string }
variable "ssh_public_key" { type = string }
variable "unprivileged"   { type = bool }
variable "nesting"        { type = bool }
variable "tags"           { type = list(string) }
variable "description"    { type = string }
