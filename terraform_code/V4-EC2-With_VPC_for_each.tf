provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "demo-server" {
  ami             = "ami-04a37924ffe27da53"
  instance_type   = "t2.micro"
  key_name        = "keypair"
  
  vpc_security_group_ids = [aws_security_group.eks.id] 
  subnet_id = aws_subnet.my-public-subnet-01.id  
  # Loop over the instances (jenkins-master, build-slave, ansible)
  for_each = toset(["jenkins-master", "build-slave", "ansible"])  
  tags = {
    Name = "${each.key}"
  }
}

resource "aws_security_group" "eks" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id = aws_vpc.my-vpc.id 
  
  ingress {
    description      = "SHH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
    description      = "Jenkins port"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"

  }
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "my-vpc"
  }
  
}

resource "aws_subnet" "my-public-subnet-01" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "my-public-subent-01"
  }
}

resource "aws_subnet" "my-public-subnet-02" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "my-public-subent-02"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id 
  tags = {
    Name = "my-igw"
  } 
}

resource "aws_route_table" "my-public-rt" {
  vpc_id = aws_vpc.my-vpc.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id 
  }
}

resource "aws_route_table_association" "my-rta-public-subnet-01" {
  subnet_id = aws_subnet.my-public-subnet-01.id
  route_table_id = aws_route_table.my-public-rt.id   
}

resource "aws_route_table_association" "my-rta-public-subnet-02" {
  subnet_id = aws_subnet.my-public-subnet-02.id 
  route_table_id = aws_route_table.my-public-rt.id   
}
