# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = "${merge(map("Name" , "main_vpc"),var.tags)}"
}

# Subnets -- public and private
resource "aws_subnet" "main_public_subnet" {
  vpc_id                  = "${aws_vpc.main_vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = "${merge(map("Name" , "main_public_subnet"),var.tags)}"
}

resource "aws_subnet" "main_private_subnet" {
  vpc_id                  = "${aws_vpc.main_vpc.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = "${merge(map("Name" , "main_private_subnet"),var.tags)}"
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  tags = "${merge(map("Name" , "main_igw"),var.tags)}"
}

# Route tables -- public and private
resource "aws_route_table" "main_public_route_table" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main_igw.id}"
  }

  tags = "${merge(map("Name" , "main_public_route_table"),var.tags)}"
}

resource "aws_route_table_association" "main_public_subnet_route_table_association" {
  subnet_id      = "${aws_subnet.main_public_subnet.id}"
  route_table_id = "${aws_route_table.main_public_route_table.id}"
}

resource "aws_route_table" "main_private_route_table" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  tags = "${merge(map("Name" , "main_private_route_table"),var.tags)}"
}

resource "aws_route_table_association" "main_private_subnet_route_table_association" {
  subnet_id      = "${aws_subnet.main_private_subnet.id}"
  route_table_id = "${aws_route_table.main_private_route_table.id}"
}

# Security groups -- internal only, web-cloudflare, ssh 
resource "aws_security_group" "internal_sg" {
  name        = "internal_sg"
  description = "Allow traffic from web subnets within the same VPC"
  vpc_id      = "${aws_vpc.main_vpc.id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.web_cloudflare_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name" , "internal_sg"),var.tags)}"
}

resource "aws_security_group" "web_cloudflare_sg" {
  name        = "web_cloudflare_sg"
  description = "Allow HTTP, HTTPS inbound traffic from whitelisted Cloudflare IPs"
  vpc_id      = "${aws_vpc.main_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.cloudflare_ips}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.cloudflare_ips}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name" , "web_cloudflare_sg"),var.tags)}"
}

resource "aws_security_group" "ssh_sg" {
  name        = "ssh_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.main_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name" , "ssh_sg"),var.tags)}"
}

# Network Access Control List
resource "aws_network_acl" "main_network_acl" {
  vpc_id     = "${aws_vpc.main_vpc.id}"
  subnet_ids = ["${aws_subnet.main_public_subnet.id}", "${aws_subnet.main_private_subnet.id}"]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 32768
    to_port    = 65535
  }

  ingress {
    protocol   = "-1"
    rule_no    = 500
    action     = "allow"
    cidr_block = "${aws_vpc.main_vpc.cidr_block}"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = "${merge(map("Name" , "main_network_acl"),var.tags)}"
}
