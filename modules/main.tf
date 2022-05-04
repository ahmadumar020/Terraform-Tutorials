module "aws-vpc" {
    source = "/source-vpc"
}

module "aws-load-balancer" {
    source = "/source"
}

module "aws-instance" {
    source = "/source-instance"
  
}