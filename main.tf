resource "aws_vpc" "my_vpc_tf" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "dev"
  }
}

# creating a subnet 
resource "aws_subnet" "fca-public_subnet" {
  vpc_id                  = aws_vpc.my_vpc_tf.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

# creating a internet gateway
resource "aws_internet_gateway" "fca-igw" {
  vpc_id = aws_vpc.my_vpc_tf.id

  tags = {
    Name = "dev-igw"
  }
}

#creating a route table
resource "aws_route_table" "fca_public_rt" {
  vpc_id = aws_vpc.my_vpc_tf.id
  tags = {
    Name = "dev_public_rt"
  }
}
#creating a route 
resource "aws_route" "fca_public_route" {
  route_table_id         = aws_route_table.fca_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fca-igw.id
}

#route table association
resource "aws_route_table_association" "fca_public_rt_assoc" {
  subnet_id      = aws_subnet.fca-public_subnet.id
  route_table_id = aws_route_table.fca_public_rt.id
}

#creating a SecurityGroup
resource "aws_security_group" "fca_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.my_vpc_tf.id

  ingress {
    description = "sg from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# creating public key  
# commands:
# ssh-keygen -t ed25519
# ls ~/ssh

resource "aws_key_pair" "fca_auth_key" {
  key_name   = "fcakey"
  public_key = file("~/.ssh/myfavorite.pub") #using a T function to get the public key

}
resource "aws_instance" "dev-node" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.fca_auth_key.id
  vpc_security_group_ids = [aws_security_group.fca_sg.id]
  subnet_id              = aws_subnet.fca-public_subnet.id
  user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }
}