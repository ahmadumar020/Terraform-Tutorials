provider "aws" {
  region = "ap-southeast-2"
}

# Declare the data source
data "aws_availability_zones" "available-zones" {
  state = "available"
}

resource "aws_vpc" "terraform-vpc" {
    cidr_block = "10.3.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
      "name" = "terraform-vpc"
    }
}