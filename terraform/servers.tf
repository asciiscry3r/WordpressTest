// Copyright (C) 2024 by Klimenko Maxim Sergeevich

resource "aws_vpc" "wordpress" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "wordpress"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "wordpress1" {
  vpc_id     = aws_vpc.wordpress.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Wordpress Main"
  }
}

resource "aws_subnet" "wordpress2" {
  vpc_id     = aws_vpc.wordpress.id
  cidr_block = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Wordpress Main"
  }
}

resource "aws_db_subnet_group" "wordpress" {
  name       = "wordpress"
  subnet_ids = [aws_subnet.wordpress1.id, aws_subnet.wordpress2.id]

  tags = {
    Name = "My wordpress DB subnet group"
  }
}

resource "aws_db_instance" "wordpress" {
  allocated_storage    = 10
  //db_name              = "wordpress"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "wordpress"
  password             = "deedtbdeyhbehb"
  db_subnet_group_name = aws_db_subnet_group.wordpress.name
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

resource "aws_elasticache_cluster" "wordpress" {
  cluster_id        = "wordpress"
  engine            = "redis"
  node_type         = "cache.t3.micro"
  num_cache_nodes   = 1
  port              = 6379
  apply_immediately = true
  subnet_group_name = aws_db_subnet_group.wordpress.name
}

module "deploy_wordpress_server" {
    source = "./modules/ec2instance"

    instance_tag_name = "wordpress_server"
    deploy_nixos = false
    deploy_ubuntu = true
    deploy_arch = false
    encryption_state = true
    instance_type = "t2.micro"
    vpc_id_main = aws_vpc.wordpress.id
    ec2_volume_size = "30"
    cidr_allowed_for_ssh = [ var.cidr_allowed_for_ssh ]
    server_record_name = "wordpress.mksscryertower.quest"
    web_server_ingress = true
}

