variable "region" {
    type = string
    description = "the default aws region"
    default = "ap-southeast-2"
}
variable "main_vpc_cidr" {
    type = string
    description = "manually setting cidr block"
    default = "10.3.0.0/16"
}
variable "public_subnets" {
    type = string
    description = "manually setting cidr block"
    default = "10.3.0.0/20"
}
/*
variable "private_subnets" {
    type = string
    description = "manually setting cidr block"
    default = "10.4.0.192/26"
}*/

variable public_key_path {
    type = string
    description = "public key to ssh"
    default = "./../demo-key-pair.pem"
}


