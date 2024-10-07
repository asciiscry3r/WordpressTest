// Copyright (C) 2022 by Klimenko Maxim Sergeevich

data "aws_vpc" "default" {
  id = var.vpc_id_main
}

resource "aws_security_group" "server" {
  name        = "${var.instance_tag_name}_security_group"
  description = "Allow inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.cidr_allowed_for_ssh
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.instance_tag_name
    Env  = var.server_record_name
  }
}

resource "aws_security_group_rule" "server_80" {
  count             = (var.web_server_ingress != false ? 1 : 0 )
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "server_443" {
  count             = (var.web_server_ingress != false ? 1 : 0 )
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server.id
}

module "nixos_image" {
    source  = "git::https://github.com/tweag/terraform-nixos.git//aws_image_nixos?ref=5f5a0408b299874d6a29d1271e9bffeee4c9ca71"
    release = "20.09"
}

resource "tls_private_key" "state_ssh_key" {
    algorithm = "RSA"
    rsa_bits  = "4096"
}

resource "local_file" "machine_ssh_key" {
    sensitive_content = tls_private_key.state_ssh_key.private_key_pem
    filename          = "${path.module}/${var.instance_tag_name}.pem"
    file_permission   = "0600"
}

resource "aws_key_pair" "generated_key" {
    key_name   = "generated-key-${sha256(tls_private_key.state_ssh_key.public_key_openssh)}"
    public_key = tls_private_key.state_ssh_key.public_key_openssh

    tags = {
      Name = var.instance_tag_name
      Env  = var.server_record_name
    }
}

resource "aws_kms_key" "encrypt" {
    count       = ( var.encryption_state != false ? 1 : 0 )
    description = "instances crypto key"

    tags = {
      Name = var.instance_tag_name
      Env  = var.server_record_name
    }
}

resource "aws_instance" "nixos" {
    count           = ( var.deploy_nixos != false ? 1 : 0 )
    ami             = module.nixos_image.ami
    instance_type   = var.instance_type
    security_groups = [ aws_security_group.server.name ]
    key_name        = aws_key_pair.generated_key.key_name

    root_block_device {
        encrypted   = var.encryption_state
        #kms_key_id  = aws_kms_key.encrypt[0].key_id
        volume_size = var.ec2_volume_size

	tags = {
      	  Name = var.instance_tag_name
          Env  = var.server_record_name
        }
    }

    tags = {
      Name = var.instance_tag_name
      Env  = var.server_record_name
    }
}

//Use nixos-instantiate for check configuration drift
//Error: failed to execute ".terraform/modules/deploy_nixos/deploy_nixos/nixos-instantiate.sh": running (instantiating):  'nix-instantiate' '--show-trace' '--expr' $'\n  { system, configuration, ... }:\n  let\n    os = import <nixpkgs/nixos> { inherit system configuration; };\n    inherit (import <nixpkgs/lib>) concatStringsSep;\n  in {\n    substituters = concatStringsSep " " os.config.nix.binaryCaches;\n    trusted-public-keys = concatStringsSep " " os.config.nix.binaryCachePublicKeys;\n    drv_path = os.system.drvPath;\n    out_path = os.system;\n    inherit (builtins) currentSystem;\n  }' '--argstr' 'configuration' '/home/max/Projects/HomeInfrastructure/nixos/configuration.nix' '--argstr' 'system' 'x86_64-linux' -A out_path
//│ .terraform/modules/deploy_nixos/deploy_nixos/nixos-instantiate.sh: line 44: nix-instantiate: command not foundmo

module "deploy_nixos" {
    count       = ( var.deploy_nixos != false ? 1 : 0 )
    source = "git::https://github.com/tweag/terraform-nixos.git//deploy_nixos?ref=5f5a0408b299874d6a29d1271e9bffeee4c9ca71"
    nixos_config = "${path.module}/../nixos/configuration.nix"
    target_host = aws_instance.nixos[count.index].public_ip
    ssh_private_key_file = local_file.machine_ssh_key.filename
    ssh_agent = false
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "arch_server" {
  count           = ( var.deploy_arch == true ? 1 : 0 )
  ami             = var.aws_arch_ami
  instance_type   = var.instance_type
  key_name        = aws_key_pair.generated_key.key_name
  security_groups = [ aws_security_group.server.name ]

  root_block_device {
    encrypted   = var.encryption_state
    volume_size = var.ec2_volume_size

    tags = {
      Name = var.instance_tag_name
      Env  = var.server_record_name
    }
  }

  tags = {
    Name = var.instance_tag_name
    Env  = var.server_record_name
  }
}


resource "aws_eip" "arch_server" {
  count    = ( var.deploy_arch == true ? 1 : 0 )
  instance = aws_instance.arch_server[count.index].id
  vpc      = true

  tags = {
    Name = var.instance_tag_name
    Env  = var.server_record_name
  }
}

resource "aws_instance" "server" {
  count           = ( var.deploy_ubuntu == true ? 1 : 0 ) 
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.generated_key.key_name
  security_groups = [ aws_security_group.server.name ]

  root_block_device {
    encrypted   = var.encryption_state
    volume_size = var.ec2_volume_size

    tags = {
      Name = var.instance_tag_name
      Env  = var.server_record_name
    }
  }

  tags = {
    Name = var.instance_tag_name
    Env  = var.server_record_name
  }
}

resource "aws_eip" "server" {
  count    = ( var.deploy_ubuntu == true ? 1 : 0 )
  instance = aws_instance.server[count.index].id
  vpc      = true

  tags = {
    Name = var.instance_tag_name
    Env  = var.server_record_name
  }
}
