
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.5.0.0/16"
  tags = {
    Name = "k8_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "k8_igw"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.5.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "k8-primary-subnet"
  }
}


resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.main_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}


resource "aws_security_group" "main_sg" {
  name        = "allow_ssh_http_internal"
  description = "Allow SSH and all internal TCP/UDP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.5.1.0/24"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["10.5.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http_internal"
  }
}

resource "aws_eip" "eip" {
  count  = 3
  domain = "vpc"
  tags = {
    Name = "eip-${count.index + 1}"
  }
}


resource "aws_instance" "nodes" {
  count                  = 3
  ami                    = "ami-0f9de6e2d2f067fca"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  associate_public_ip_address = false
  key_name               = "k8"  # Replace this with your actual key pair name

  tags = {
    Name = "${element(["Master", "Node-1", "Node-2"], count.index)}"
  }

  user_data = file("${path.module}/scripts/init-script.sh")
}


resource "aws_eip_association" "eip_assoc" {
  count         = 3
  instance_id   = aws_instance.nodes[count.index].id
  allocation_id = aws_eip.eip[count.index].id
}

output "instance_info" {
  description = "EC2 instance names with private and public IPs"
  value = [
    for i in range(length(aws_instance.nodes)) : {
      name       = aws_instance.nodes[i].tags["Name"]
      private_ip = aws_instance.nodes[i].private_ip
      public_ip  = aws_eip.eip[i].public_ip
    }
  ]
}
