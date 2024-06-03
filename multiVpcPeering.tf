# Define your AWS provider and region
provider "aws" {
  region = "us-east-1"
}

# Variables
variable "source_region" {
  default = "us-east-1"
}

variable "target_region" {
  default = "us-east-2"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr_blocks" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Create VPCs
resource "aws_vpc" "source_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "SourceVPC"
  }
}

resource "aws_vpc" "target_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "TargetVPC"
  }
}

# Create Subnets
resource "aws_subnet" "source_subnets" {
  count         = length(var.subnet_cidr_blocks)
  cidr_block    = var.subnet_cidr_blocks[count.index]
  vpc_id        = aws_vpc.source_vpc.id
  availability_zone = "us-west-1" # Replace with your desired availability zone in the source region
  tags = {
    Name = "SourceSubnet-${count.index}"
  }
}

resource "aws_subnet" "target_subnets" {
  count         = length(var.subnet_cidr_blocks)
  cidr_block    = var.subnet_cidr_blocks[count.index]
  vpc_id        = aws_vpc.target_vpc.id
  availability_zone = "us-east-2" # Replace with your desired availability zone in the target region
  tags = {
    Name = "TargetSubnet-${count.index}"
  }
}

# Create EC2 Instances (for demonstration)
resource "aws_instance" "source_ec2" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with your desired AMI ID in the source region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.source_subnets[0].id
  tags = {
    Name = "SourceEC2"
  }
}

resource "aws_instance" "target_ec2" {
  ami           = "ami-02a2c2494f8cc84ba" # Replace with your desired AMI ID in the target region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.target_subnets[0].id
  tags = {
    Name = "TargetEC2"
  }
}

# Create VPC Peering Connection
resource "aws_vpc_peering_connection" "peering" {
  provider           = aws.target
  peer_vpc_id         = aws_vpc.target_vpc.id
  vpc_id              = aws_vpc.source_vpc.id
  peer_region         = var.target_region
  auto_accept         = true
}

# Update Routing Tables
resource "aws_route" "source_to_target" {
  route_table_id         = aws_vpc.source_vpc.default_route_table_id
  destination_cidr_block = aws_vpc.target_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "target_to_source" {
  route_table_id         = aws_vpc.target_vpc.default_route_table_id
  destination_cidr_block = aws_vpc.source_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}


