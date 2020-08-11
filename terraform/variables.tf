variable "project" {
  type    = string
  default = "elasticsearch-236916"
}
variable "region" {
  type    = string
  default = "us-central1"
}
variable "location" {
  type    = string
  default = "us-central1"
}
variable "username" {
  default     = "jonathan.boniface"
  description = "gke username"
}

variable "password" {
  default     = "R1deH8rd"
  description = "gke password"
}
