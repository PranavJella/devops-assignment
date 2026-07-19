data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#######################
# VPC
#######################

resource "aws_vpc" "blog_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Blog-VPC"
  }
}

#######################
# Public Subnet
#######################

resource "aws_subnet" "public_subnet" {

  vpc_id = aws_vpc.blog_vpc.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-south-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }

}

#######################
# Private Subnet
#######################

resource "aws_subnet" "private_subnet" {

  vpc_id = aws_vpc.blog_vpc.id

  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-south-1a"

  tags = {
    Name = "Private-Subnet"
  }

}

#######################
# Internet Gateway
#######################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.blog_vpc.id

  tags = {
    Name = "Blog-IGW"
  }

}

#######################
# Elastic IP for NAT
#######################

resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = {
    Name = "NAT-EIP"
  }

}

#######################
# NAT Gateway
#######################

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat_eip.id

  subnet_id = aws_subnet.public_subnet.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "Blog-NAT"
  }

}

#######################
# Public Route Table
#######################

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.blog_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id

  }

  tags = {
    Name = "Public-RT"
  }

}

resource "aws_route_table_association" "public_assoc" {

  subnet_id = aws_subnet.public_subnet.id

  route_table_id = aws_route_table.public_rt.id

}

#######################
# Private Route Table
#######################

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.blog_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat.id

  }

  tags = {
    Name = "Private-RT"
  }

}

resource "aws_route_table_association" "private_assoc" {

  subnet_id = aws_subnet.private_subnet.id

  route_table_id = aws_route_table.private_rt.id

}

#######################
# Bastion Security Group
#######################

resource "aws_security_group" "bastion_sg" {

  name = "Bastion-SG"

  vpc_id = aws_vpc.blog_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#######################
# Application Security Group
#######################

resource "aws_security_group" "app_sg" {

  name = "App-SG"

  vpc_id = aws_vpc.blog_vpc.id

  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    security_groups = [aws_security_group.bastion_sg.id]

  }

  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    from_port = 5000

    to_port = 5000

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}

#######################
# Database Security Group
#######################

resource "aws_security_group" "db_sg" {

  name = "DB-SG"

  vpc_id = aws_vpc.blog_vpc.id

  ingress {

    from_port = 3306

    to_port = 3306

    protocol = "tcp"

    security_groups = [aws_security_group.app_sg.id]

  }

  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    security_groups = [aws_security_group.bastion_sg.id]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}

#######################
# Bastion Instance
#######################

resource "aws_instance" "bastion" {

  ami = data.aws_ami.ubuntu.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  associate_public_ip_address = true

  key_name = var.key_name

  tags = {

    Name = "Bastion"

  }

}

#######################
# Application Instance
#######################

resource "aws_instance" "application" {

  ami = data.aws_ami.ubuntu.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.private_subnet.id

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  key_name = var.key_name

  tags = {

    Name = "Application"

  }

}

#######################
# Database Instance
#######################

resource "aws_instance" "database" {

  ami = data.aws_ami.ubuntu.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.private_subnet.id

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  key_name = var.key_name

  tags = {

    Name = "Database"

  }

}