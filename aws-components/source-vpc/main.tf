resource "aws_vpc" "demo-vpc" {
    cidr_block = "172.31.0.0/16"
    instance_tenancy = "default"  
    enable_dns_support = true
    enable_dns_hostnames = true
    enable_classiclink = false

    
}

/*
resource "aws_subnet" "demo-vpc-public-1" {
    vpc_id = aws_vpc.vpc.id
    cidr_block  
}
*/