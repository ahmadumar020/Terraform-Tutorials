terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

resource "aws_vpc" "demo-vpc" {
    cidr_block = "10.4.0.0/24"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
      "name" = "demo-vpc"
    }
}

# Create Internet Gateway and attach it to VPC
 resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
    vpc_id =  aws_vpc.demo-vpc.id               # vpc_id will be generated after we create VPC
 }

 #Create Public Subnets.
 resource "aws_subnet" "publicsubnets" {    # Creating Public Subnets
   vpc_id =  aws_vpc.demo-vpc.id
   cidr_block = "${var.public_subnets}"        # CIDR block of public subnets
   availability_zones = ["ap-southeast-2a","ap-southeast-2b","ap-southeast-2c"]

   tags = {
       Name = "demo-pub-subnet"
   }
 }

 #Route table for Public Subnet's
 resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
    vpc_id =  aws_vpc.demo-vpc.id
         route {
    cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
     }
 }
 #Route table Association with Public Subnet's
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
 }


 /*
  #Create a Private Subnet                   # Creating Private Subnets
 resource "aws_subnet" "privatesubnets" {
   vpc_id =  aws_vpc.demo-vpc.id
   cidr_block = "${var.private_subnets}"          # CIDR block of private subnets
 }
 #Route table for Private Subnet's
 resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
   vpc_id = aws_vpc.demo-vpc.id
   route {
   cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
 }

 #Route table Association with Private Subnet's
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.privatesubnets.id
    route_table_id = aws_route_table.PrivateRT.id
 }
 */

resource "aws_lb" "demo-alb" {
    name = "demo-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups = ["${aws_security_group.demo-sg.id}"]
    subnets = aws_subnet.publicsubnets.*.id
    enable_http2       = false

    tags = {
      "Name" = "demo-alb"
    }
}

resource "aws_alb_target_group" "demo-group" {
  name     = "demo-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.demo-vpc.id}"
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }
  depends_on = [
    aws_lb.demo-alb
  ]
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_alb_listener" "demo-listener" {
  load_balancer_arn = "${aws_lb.demo-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
      type             = "forward"
      target_group_arn = "${aws_alb_target_group.demo-group.arn}"
  }
}


resource "aws_key_pair" "demo-keys" {
  key_name   = "demo-keys"
  public_key = "${file(var.public_key_path)}"
}



resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Demo security group"
  vpc_id      = "${aws_vpc.demo-vpc.id}"

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
  vpc_id     = aws_vpc.demo-vpc.id
  subnet_ids = [aws_subnet.publicsubnets[0].id,aws_subnet.publicsubnets[1].id]

  # Ingress rules
  # Allow all local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.demo-vpc.cidr_block
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

  tags = {
    Name = "demo-instance"
  }
}
/*
resource "aws_eip" "default" {
  count    = local.eip_enabled ? 1 : 0
  instance = join("", aws_instance.default.*.id)
  vpc      = true
  tags     = module.this.tags
}
*/
resource "aws_lb_target_group_attachment" "demo-alb-attach" {
  target_group_arn = "${aws_alb_target_group.demo-group.arn}"
  target_id        = aws_instance.demo-instance.id
  port             = 80
}

/*
resource "aws_launch_configuration" "demo-instance" {
  name_prefix                 = "demo-instance"
  image_id                    = "${lookup(var.amis, var.region)}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.demo-keys.id}"
  security_groups             = ["${aws_security_group.demo-sg.id}"]
  associate_public_ip_address = true
  user_data                   = "${data.template_file.provision.rendered}"

  provisioner "remote-exec" {
      inline = [
          "sudo yum install nginx -y",
          "sudo service nginx start"
          ] 
          
    }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
      name = "demo-instance"
  }
}
*/
