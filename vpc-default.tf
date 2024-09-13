provider "aws" {
  region = "us-east-1"
}

// VPC 
resource "aws_vpc" "MyVPC" {
    cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My-vpc"
  }
}

// PRIVATE SUBNET
resource "aws_subnet" "private_subnet1" {
    vpc_id = aws_vpc.MyVPC.id
    availability_zone = "us-east-1a"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = false
    tags = {
        Name = "my_private_subnet1"
    }
}

resource "aws_subnet" "private_subnet2" {
    vpc_id = aws_vpc.MyVPC.id
    availability_zone = "us-east-1b"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = false
    tags = {
        Name = "my_private_subnet2"
    }
}

// PUBLIC SUBNET
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.MyVPC.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "my_public_subnet"
    }
}

// INTERNET GATEWAY
resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.MyVPC.id
  tags = {
    Name = "my_internet_gateway"
  }
}

// ROUTE TABLES
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.MyVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "my_public_routes"
  }
}

// ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "route_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


// SUBNET GROUP
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

// EC2 
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "My_ec2_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "My_instance"
  }
}

// RDS
resource "aws_db_instance" "my_db_instance" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin123"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot  = true
  publicly_accessible = false
  
  tags = {
    Name = "my_rds_instance"
  }
}