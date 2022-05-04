module "vpc" {
  source         = "./source-vpc"
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  aws_region     = var.aws_region
  name = "demo-vpc"
}

/*
module "aws-load-balancer" {
    source = "./source-lb"
}

module "aws-instance" {
    source = "./source-instance"
  
}

*/