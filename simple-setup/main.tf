terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
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

# Create Internet Gateway and attach it to VPC
 resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
    vpc_id =  aws_vpc.terraform-vpc.id               # vpc_id will be generated after we create VPC

    depends_on = [
      aws_vpc.terraform-vpc
    ]
 }

resource "aws_subnet" "subnet1" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "10.3.0.0/20"

  depends_on = [
      aws_vpc.terraform-vpc
    ]

  tags = {
    "Name" = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "10.3.16.0/20"

  depends_on = [
      aws_vpc.terraform-vpc
    ]

  tags = {
    "Name" = "subnet2"
  }
}

# for declaring security group for ec2 instance resource 

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id = aws_vpc.terraform-vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" //any protocol
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [
      aws_vpc.terraform-vpc
    ]

  tags = {
    Name = "Created by Terraform"
  }
}


# ALB for the web servers
resource "aws_lb" "web-alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]
  enable_http2       = false
  enable_deletion_protection = false

  depends_on = [
      aws_security_group.allow_web,
      aws_subnet.subnet1,
      aws_subnet.subnet2
    ]

  tags = {
    Name = "web-alb"
  }
}

/*
 #Route table for Public Subnet's
 resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
    vpc_id =  aws_vpc.terraform-vpc.id
    route {
        cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
        gateway_id = aws_internet_gateway.IGW.id
     }



     tags = {
         Name = "demo-pub-RT"
     }
 }
 #Route table Association with Public Subnet's
 resource "aws_route_table_association" "PublicRTassociation-subnet1" {
    subnet_id = aws_subnet.publicsubnet1.id
    route_table_id = aws_route_table.PublicRT.id
 }
resource "aws_route_table_association" "PublicRTassociation-subnet2" {
    subnet_id = aws_subnet.publicsubnet2.id
    route_table_id = aws_route_table.PublicRT.id
 }


resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Demo security group"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  # Allow outbound internet access.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}

resource "aws_network_acl" "demo-nacl" {
  vpc_id     = aws_vpc.terraform-vpc.id
  subnet_ids = [aws_subnet.publicsubnet1.id,aws_subnet.publicsubnet2.id]

  # Ingress rules
  # Allow all local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.terraform-vpc.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Allow HTTP web traffic from anywhere
  ingress {
    protocol   = 6
    rule_no    = 105
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow HTTPS web traffic from anywhere
  ingress {
    protocol   = 6
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow HTTPS web traffic from anywhere
  ingress {
    protocol   = 6
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Egress rules
  # Allow all ports, protocols, and IPs outbound
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "demo-nacl"
  }
}


## ami-0c6120f461d6b39e9 (Amazon Linux 2 AMI)
## instance type is t2.micro (free tier)

resource "aws_instance" "demo-instance" {
  ami           = "ami-0c6120f461d6b39e9"
  instance_type = "t2.micro"
  key_name          = "demo-key-pair"
  security_groups   = [aws_security_group.demo-sg.name]
  user_data         = <<-EOF
                #! /bin/bash
                sudo yum update
                sudo yum install -y httpd
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "
<h1>Deployed via Terraform</h1>

" | sudo tee /var/www/html/index.html
        EOF

  tags = {
    Name = "demo-instance"
  }
}
/*

resource "aws_lb_target_group_attachment" "demo-alb-attach" {
  target_group_arn = "${aws_alb_target_group.demo-group.arn}"
  target_id        = aws_instance.demo-instance.id
  port             = 80
}

*/
