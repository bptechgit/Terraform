# Provider AWS
provider "aws" {
  
  access_key = ""
  secret_key = ""
  region     = "us-east-1"
}

# Create vpc 
resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    
    tags = {
    Name = "cust_vpc"
  }
}

# Create Public Subnet

 resource "aws_subnet" "my_sub" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub_subnet"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "net_igw"
  }
}

# Create Route Table
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route_pub"
  }
}

resource "aws_route_table_association" "pub_asso" {
  subnet_id      = aws_subnet.my_sub.id
  route_table_id = aws_route_table.route.id
}

# Create Security Group
resource "aws_security_group" "dbsg" {
  name   = "db_sg"
  vpc_id = aws_vpc.my_vpc.id

  # Inbound Rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_inst" {
  ami           = "ami-06c68f701d8090592"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_sub.id
  vpc_security_group_ids = [aws_security_group.dbsg.id]
  key_name   = "aws_key"
}


# Create RSA key 
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create Key Pair 
resource "aws_key_pair" "aws_key" {
  key_name   = "aws_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "TF_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfkey"
}