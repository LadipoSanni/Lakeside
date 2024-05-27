#create vpc
resource "aws_vpc" "vpc"{
    cidr_block   =  "var.vpc_cidr"
    instance_tenancy = "default"
    enable-dns-hostname = true
    enable-dns-support = true
    tags  = {
        Name = "${var.project_name}-vpc"
    }

