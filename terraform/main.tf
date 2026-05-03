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

  # Skip credential validation — plan only, nothing is provisioned
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
# EC2 — web server
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
# EC2 — API server
# GreenOps will recommend: m6g.large (ARM) or shift to eu-north-1
# -----------------------------------------------------------------------

resource "aws_instance" "api" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "m5.large"
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "greenops-demo-api"
    Environment = "demo"
  }
}

# -----------------------------------------------------------------------
# RDS — database
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
