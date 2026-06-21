terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  # Skip credential validation. Plan only, nothing is provisioned.
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# -----------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "greenops-demo-vpc"
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "greenops-demo-public" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "greenops-demo-private" }
}

# -----------------------------------------------------------------------
# EC2: web server
# GreenOps will recommend: m6g.xlarge (ARM) or shift to eu-north-1
# -----------------------------------------------------------------------

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "m5.xlarge"
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "greenops-demo-web"
    Environment = "demo"
  }
}

# -----------------------------------------------------------------------
# EC2: API server
# GreenOps will recommend: m6g.large (ARM) or shift to eu-north-1
# -----------------------------------------------------------------------

resource "aws_instance" "api" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "m5.xlarge"  # changed for demo, GreenOps will suggest m6g.xlarge
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "greenops-demo-api"
    Environment = "demo"
  }
}

# -----------------------------------------------------------------------
# RDS: database
# GreenOps will recommend: db.m6g.large or shift to eu-north-1
# -----------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "greenops-demo-db-subnet"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = { Name = "greenops-demo-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier        = "greenops-demo-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.m5.large"
  allocated_storage = 20
  db_name           = "demodb"
  username          = "admin"
  password          = "demo-password-change-me"

  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot  = true
  publicly_accessible  = false

  tags = {
    Name        = "greenops-demo-db"
    Environment = "demo"
  }
}

output "web_instance_type" { value = aws_instance.web.instance_type }
output "api_instance_type" { value = aws_instance.api.instance_type }
output "db_instance_class" { value = aws_db_instance.main.instance_class }

# -----------------------------------------------------------------------
# EKS cluster + node group
# GreenOps will report this as m5.large x 2 (autoscaling minimum size,
# not the desired_size of 3) and recommend an ARM upgrade or region shift
# across the whole node group.
# -----------------------------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name = "greenops-demo-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "eks_node_group" {
  name = "greenops-demo-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_eks_cluster" "main" {
  name     = "greenops-demo-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]
  }

  tags = {
    Name        = "greenops-demo-cluster"
    Environment = "demo"
  }
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "greenops-demo-workers"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = [aws_subnet.public.id, aws_subnet.private.id]
  instance_types  = ["m5.large"]

  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 6
  }

  tags = {
    Name        = "greenops-demo-eks-workers"
    Environment = "demo"
  }
}

output "eks_node_group_instance_types" { value = aws_eks_node_group.workers.instance_types }
