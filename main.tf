module "availability_checker" {
  source = "./modules/api-smoke-test"
  vpc_id = var.vpc_id
  subnets = var.subnets
  service = "ose-booking"
  spec_path = "./spec"
  dd_tags = [
      "env:nonprod"
  ]
}

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
