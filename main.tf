provider "aws" {
  region     = "ap-east-1"
}

resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id                  = aws_vpc.dev-vpc.id
  cidr_block              = "10.1.10.0/24"
  availability_zone       = "ap-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ec2-sg" {
  name_prefix = "ec2-sg-"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-0123e5d7542358c86"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.dev-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.ec2-sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.jenkins_key.key_name  # 关联密钥对

  tags = {
    Name = "JenkinsInstance"
  }
}


resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "terraform"
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

output "jenkins_private_key" {
  value     = tls_private_key.jenkins_key.private_key_pem
  sensitive = true
}

resource "local_file" "jenkins_private_key_file" {
  content  = tls_private_key.jenkins_key.private_key_pem
  filename = "${path.module}/jenkins_private_key.pem"
}


output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

