# VPC Definition
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.46.0"

  name = "ecs-vpc"
  cidr = "10.50.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.50.11.0/24", "10.50.12.0/24"]
  private_subnets = ["10.50.21.0/24", "10.50.22.0/24"]

  single_nat_gateway = true

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  tags {
    Terraform = "true"
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "load-balancer-sg"
  description = "Allow all inbound traffic to http and https"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "load-balancer-sg"
  }
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "fargate-ecs-service-sg"
  description = "Allow all inbound traffic to service port"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "fargate-ecs-service-sg"
  }
}

data "aws_route53_zone" "zone" {
  name = "testing.nis.could.vt.edu"
}

module "lb_s3_bucket" {
  source        = "cloudposse/lb-s3-bucket/aws"
  version       = "0.1.4"
  namespace     = "dcr"
  stage         = "test"
  name          = "lb-s3-bucket-98749234phwhfkjsdhfwer"
  region        = "us-east-1"
  force_destroy = "true"
}

module "alb_shared_services_external" {
  source                    = "terraform-aws-modules/alb/aws"
  version                   = "3.4.0"
  load_balancer_name        = "ecs-external"
  security_groups           = ["${aws_security_group.lb_sg.id}"]
  load_balancer_is_internal = false
  log_bucket_name           = "${module.lb_s3_bucket.bucket_id}"
  log_location_prefix       = ""
  subnets                   = ["${module.vpc.public_subnets}"]
  tags                      = "${map("Environment", "ECS Test Setup")}"
  vpc_id                    = "${module.vpc.vpc_id}"
  https_listeners           = []
  https_listeners_count     = "0"
  http_tcp_listeners        = "${list(map("port", "80", "protocol", "HTTP"))}"
  http_tcp_listeners_count  = "1"
  target_groups             = "${list(map("name", "default-ext", "backend_protocol", "HTTP", "backend_port", "80"))}"
  target_groups_count       = "1"
}
