terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}
/*
module "vpc" {
  source = "./vpc"
}*/
module "vpc-online" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets = var.vpc_public_subnets

  tags = var.vpc_tags

}


/*
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
  availability_zone = "ap-southeast-2a"

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
  availability_zone = "ap-southeast-2b"

  depends_on = [
      aws_vpc.terraform-vpc
    ]

  tags = {
    "Name" = "subnet2"
  }
}

resource "aws_route_table" "terraform-rt-table" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.IGW.id}" 
    }
}

resource "aws_route_table_association" "rt-table-subnet1"{
    subnet_id = "${aws_subnet.subnet1.id}"
    route_table_id = "${aws_route_table.terraform-rt-table.id}"
}

resource "aws_route_table_association" "rt-table-subnet2"{
    subnet_id = "${aws_subnet.subnet2.id}"
    route_table_id = "${aws_route_table.terraform-rt-table.id}"
}

# for declaring security group for ec2 instance resource 

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id = aws_vpc.terraform-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTPS from VPC"
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

  tags = {
    Name = "web-alb"
  }

  depends_on = [
      aws_security_group.allow_web,
      aws_subnet.subnet1,
      aws_subnet.subnet2
    ]
}

resource "aws_lb_listener" "web-alb" {
  load_balancer_arn = aws_lb.web-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-alb.arn
  }

  depends_on = [
    aws_lb.web-alb,
    aws_lb_target_group.web-alb
  ]
}

resource "aws_lb_target_group" "web-alb" {
  name     = "web-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id

  health_check {
    port     = "traffic-port"
    protocol = "HTTP"
    timeout  = 5
    interval = 10
  }

  depends_on = [
    aws_vpc.terraform-vpc
  ]
}

resource "aws_lb_target_group_attachment" "web-alb" {
  #count            = length(aws_instance.terraform-instance)
  target_group_arn = aws_lb_target_group.web-alb.arn
  target_id        = aws_instance.terraform-instance.id
  #target_id        = aws_instance.terraform-instance[count.index].id
  port             = 80

  depends_on = [
    aws_lb_target_group.web-alb,
    aws_instance.terraform-instance
  ]
}

## ami-0c6120f461d6b39e9 (Amazon Linux 2 AMI)
## instance type is t2.micro (free tier)

resource "aws_instance" "terraform-instance" {
  ami           = "ami-0c6120f461d6b39e9"
  associate_public_ip_address          = false
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  #security_groups   = [aws_security_group.allow_web.name]
  subnet_id = aws_subnet.subnet1.id
  key_name = "demo-key-pair"
  depends_on = [
    aws_vpc.terraform-vpc,
    aws_security_group.allow_web
  ]

  user_data         = <<-EOF
                #! /bin/bash
                sudo yum update
                sudo yum install -y httpd
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "
<Title>Terraform Demo</Title>
<h1>Hello World</h1>
<h2>Deployed via Terraform</h2>

" | sudo tee /var/www/html/index.html
        EOF

  tags = {
    Name = "terraform-instance"
  }
}

resource "aws_eip" "terraform-eip" {
  instance = aws_instance.terraform-instance.id
  vpc = true

  depends_on = [
    aws_internet_gateway.IGW
  ]
  
  tags = {
    Name = "terraform-eip"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.terraform-instance.id
  allocation_id = aws_eip.terraform-eip.id
}
