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