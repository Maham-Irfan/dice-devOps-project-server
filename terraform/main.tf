resource "aws_vpc" "Main-VPC" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "Main-VPC"
 }
}

resource "aws_internet_gateway" "Main-VPC-Gateway" {
    vpc_id = aws_vpc.Main-VPC.id
    tags = {
        Name="Main-VPC-Gateway"
    }
}

resource "aws_route_table" "route_internet_gateway" {
    vpc_id = aws_vpc.Main-VPC.id

    route{
        cidr_block= "0.0.0.0/0"
        gateway_id= aws_internet_gateway.Main-VPC-Gateway.id
    }
    
    tags={
        Name="route_internet_gateway"
    }
}

resource "aws_subnet" "subnet-python" {
  vpc_id     = aws_vpc.Main-VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  depends_on = [aws_internet_gateway.Main-VPC-Gateway]
  tags={
    Name="subnet-python"
  }
}

resource "aws_route_table_association" "route-to-subnet"{
    subnet_id= aws_subnet.subnet-python.id
    route_table_id= aws_route_table.route_internet_gateway.id
}

resource "aws_security_group" "python-server-security-group" {
    name= "python-server-security-group"
    description= "Allowing http http and ssh inbound traffic"
    vpc_id = aws_vpc.Main-VPC.id

    ingress {
    description = "http"
    from_port    = 8080
    to_port      = 8080
    protocol     = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "ssh"
    from_port    = 22
    to_port      = 22
    protocol     = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "prometheus"
    from_port    = 9090
    to_port      = 9090
    protocol     = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "node-exporter"
    from_port    = 9100
    to_port      = 9100
    protocol     = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "grafana"
    from_port    = 3000
    to_port      = 3020
    protocol     = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks= ["0.0.0.0/0"]
    }

    tags={
        Name="python-server-security-group"
    }

}

resource "aws_instance" "python-server" {
    ami = "ami-0230bd60aa48260c6"
    instance_type = "t2.micro"
    key_name=aws_key_pair.default.key_name
    subnet_id = aws_subnet.subnet-python.id
    vpc_security_group_ids  = [aws_security_group.python-server-security-group.id]
    associate_public_ip_address = true
    user_data = <<-EOF
    #!/bin/bash

    set -e

    sudo yum install -y yum-utils

    sudo yum install docker -y
    sudo yum install awscli -y

    sudo service docker start
    sudo chmod 777 /var/run/docker.sock
    sudo yum install -y git
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo systemctl enable docker
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 590654135973.dkr.ecr.us-east-1.amazonaws.com
    docker pull 590654135973.dkr.ecr.us-east-1.amazonaws.com/python-server:latest
    docker run -d --name temp_container 590654135973.dkr.ecr.us-east-1.amazonaws.com/python-server:latest
    sudo docker cp temp_container:/docker-compose.yaml /docker-compose.yaml
    docker stop temp_container
    docker rm temp_container
    docker-compose -f docker-compose.yaml up -d
    EOF
    tags={
        Name="python-server"
    }
}
