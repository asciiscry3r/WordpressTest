// Copyright (C) 2024 by Klimenko Maxim Sergeevich

resource "aws_vpc" "wordpress" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "wordpress"
  }
}

resource "aws_subnet" "wordpress" {
  vpc_id     = aws_vpc.wordpress.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Wordpress Main"
  }
}

resource "aws_db_subnet_group" "wordpress" {
  name       = "wordpress"
  subnet_ids = [aws_subnet.wordpress.id]

  tags = {
    Name = "My wordpress DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "wordpressdb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "wordpress"
  password             = ""
  db_subnet_group_name = aws_db_subnet_group.wordpress.name
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

module "deploy_wordpress_server" {
    source = "./modules/ec2instance"

    instance_tag_name = "wordpress_server"
    deploy_nixos = false
    deploy_ubuntu = true
    deploy_arch = false
    aws_arch_ami = local.aws_arch_ami
    encryption_state = true
    instance_type = "t2.medium"
    vpc_id_main = aws_vpc.wordpress.id
    ec2_volume_size = "30"
    cidr_allowed_for_ssh = [ var.cidr_allowed_for_ssh ]
    server_record_name = "wordpress.mksscryertower.quest"
    web_server_ingress = true
}

