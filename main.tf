terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  #   backend "s3" {
  #     bucket = "tfstate-bkt1"
  #     key = "terraform.tfstate"
  #     region = "eu-west-1"
  #     dynamodb_table = "aws-table"
  #   }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}

#VPC Creation
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myVPC"
  }
}

#Subnet creation

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.myVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "subnet1"
  }
}

#IGW

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "IGW"
  }
}

#Route Table Creation

resource "aws_route_table" "RT1" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "RT1"
  }
}

#Route Table association with Subnet1

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.RT1.id
}


#Security Group creation

resource "aws_security_group" "mySG" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mySG"
  }
}

# Data source block

data "aws_ami" "myAMI" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#EC2 instance creation

resource "aws_instance" "web-server" {
  ami                         = data.aws_ami.myAMI.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mySG.id]
  key_name                    = "london1"
  user_data                   = file("server-script.sh")

  tags = {
    Name = "web-server"
  }
}