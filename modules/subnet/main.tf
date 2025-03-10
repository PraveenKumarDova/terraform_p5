
#Subnet creation

resource "aws_subnet" "subnet1" {
#   vpc_id            = aws_vpc.myVPC.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "eu-west-2a"

    vpc_id = var.vpc_id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.az

  tags = {
    Name = "${var.env}-subnet1"
  }
}

#IGW

resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.env}-IGW"
  }
}

#Route Table Creation

resource "aws_route_table" "RT1" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-RT1"
  }
}

#Route Table association with Subnet1

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.RT1.id
}


