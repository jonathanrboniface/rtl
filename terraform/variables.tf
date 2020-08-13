variable "project" {
  type    = string
  default = "elasticsearch-236916"
}
variable "name" {
  type    = string
  default = "rlt-test"
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
  default     = ""
  description = ""
}
variable "password" {
  default     = ""
  description = ""
}

variable "network_name" {
  type        = string
  default     = "default"
  description = "network name"
}

variable "env" {
  default = ["production", "development"]
  type    = list
}
variable "service_account" {
  type        = string
  default     = "jonathan-boniface@elasticsearch-236916.iam.gserviceaccount.com"
  description = "service account"
}

