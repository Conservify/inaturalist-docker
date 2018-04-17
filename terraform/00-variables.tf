variable "access_key" {}
variable "secret_key" {}

variable "region" {
  default = "us-east-1"
}

variable "whitelisted_cidrs" {
  type    = "list"
  default = []
}

variable "azs" {
  type    = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_name" {
  default = "inat"
}

variable "db_username" {
  default = "inat"
}

variable "db_password" {}

variable "db_subnet_group_name" {}

variable "internet_gateway_id" {}

variable "subnet_ids" {
  type = "list"
}

variable "vpc_id" {}
