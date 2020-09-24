variable "vpc_id" {
  type = string
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "subnets" {
  type = list(string)
}

variable "service" {
  type = string
}

variable "spec_path" {
  type = string
}

variable "dd_tags" {
  type = list(string)
  default = []
}