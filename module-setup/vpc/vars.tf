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
variable "public_subnet1" {
    type = string
    description = "manually setting cidr block"
    default = "10.3.0.0/20"
}

variable "public_subnet2" {
    type = string
    description = "manually setting cidr block"
    default = "10.3.16.0/20"
}
/*
variable "private_subnets" {
    type = string
    description = "manually setting cidr block"
    default = "10.4.0.192/26"
}*/

variable "vpc_public_subnets" {
    type = list(string)
    description = "hard coded public subnet values"
    default = ["10.0.101.0/24","10.0.102.0/24"]
}

variable public_key_path {
    type = string
    description = "public key to ssh"
    default = "./../demo-key-pair.pem"
}


