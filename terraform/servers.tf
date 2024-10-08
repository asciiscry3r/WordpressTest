// Copyright (C) 2024 by Klimenko Maxim Sergeevich

resource "aws_vpc" "wordpress" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "wordpress"
  }
}

data "aws_vpc" "wordpress" {
  id = aws_vpc.wordpress.id
}

resource "aws_internet_gateway" "wordpressgw" {
  vpc_id = aws_vpc.wordpress.id

  tags = {
    Name = "wordpress GW"
  }
}

//resource "aws_route_table_association" "wordpressgw" {
//  gateway_id     = aws_internet_gateway.wordpressgw.id
//  route_table_id = data.aws_vpc.wordpress.main_route_table_id
//}

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

resource "aws_route_table_association" "wordpress1" {
  subnet_id      = aws_subnet.wordpress1.id
  route_table_id = data.aws_vpc.wordpress.main_route_table_id
}

resource "aws_route_table_association" "wordpress2" {
  subnet_id      = aws_subnet.wordpress2.id
  route_table_id = data.aws_vpc.wordpress.main_route_table_id
}

resource "aws_route" "wordpress" {
  route_table_id              = data.aws_vpc.wordpress.main_route_table_id
  destination_cidr_block      = "0.0.0.0/0"
  gateway_id                  = aws_internet_gateway.wordpressgw.id
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
  name                 = "wordpress"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "wordpress"
  password             = "swsw" // just placeholder
  db_subnet_group_name = aws_db_subnet_group.wordpress.name
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

resource "aws_subnet" "wordpress" {
  vpc_id            = aws_vpc.wordpress.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "wordpress"
  }
}

resource "aws_route_table_association" "wordpress" {
  subnet_id      = aws_subnet.wordpress.id
  route_table_id = data.aws_vpc.wordpress.main_route_table_id
}

resource "aws_elasticache_subnet_group" "wordpress" {
  name       = "wordpress-cache-subnet"
  subnet_ids = [aws_subnet.wordpress.id]
}

resource "aws_elasticache_cluster" "wordpress" {
  cluster_id         = "wordpress"
  engine             = "redis"
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 1
  port               = 6379
  apply_immediately  = true
  subnet_group_name  = aws_elasticache_subnet_group.wordpress.name
  security_group_ids = [ aws_security_group.wordpress_redis.id ]
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
    server_subnet_id = aws_subnet.wordpress.id
    ec2_volume_size = "30"
    cidr_allowed_for_ssh = [ var.cidr_allowed_for_ssh ]
    server_record_name = "wordpress.mksscryertower.quest"
    web_server_ingress = true
}

data "aws_db_instance" "wordpress" {
  db_instance_identifier = aws_db_instance.wordpress.id
}

resource "aws_security_group_rule" "wordpress_db" {
  count                    = length(data.aws_db_instance.wordpress.vpc_security_groups)
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  //cidr_blocks            = ["0.0.0.0/0"]
  //ipv6_cidr_blocks       = ["::/0"]
  source_security_group_id = module.deploy_wordpress_server.server_security_group_id
  security_group_id        = data.aws_db_instance.wordpress.vpc_security_groups[count.index]

}

resource "aws_security_group" "wordpress_redis" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.wordpress.id

  tags = {
    Name = "Wordpress allow access"
  }
}

resource "aws_security_group_rule" "wordpress_redis_in" {
  security_group_id        = aws_security_group.wordpress_redis.id
  source_security_group_id = module.deploy_wordpress_server.server_security_group_id
  type                     = "ingress"
  from_port                = 6379
  protocol                 = "tcp"
  to_port                  = 6379
}

resource "aws_security_group_rule" "wordpress_redis_out" {
  security_group_id = aws_security_group.wordpress_redis.id
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}
