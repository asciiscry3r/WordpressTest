// Copyright (C) 2021 by Klimenko Maxim Sergeevich

module "nixos_image" {
    source  = "git::https://github.com/tweag/terraform-nixos.git//aws_image_nixos?ref=5f5a0408b299874d6a29d1271e9bffeee4c9ca71"
    release = "20.09"
}

resource "tls_private_key" "state_ssh_key" {
    algorithm = "RSA"
}

resource "local_file" "machine_ssh_key" {
    sensitive_content = tls_private_key.state_ssh_key.private_key_pem
    filename          = "${path.module}/id_rsa.pem"
    file_permission   = "0600"
}

resource "aws_key_pair" "generated_key" {
    key_name   = "generated-key-${sha256(tls_private_key.state_ssh_key.public_key_openssh)}"
    public_key = tls_private_key.state_ssh_key.public_key_openssh

    tags = {
        Name = "ssh_key_pair"
        Env  = "mksplayground"
    }
}

resource "aws_kms_key" "encrypt" {
    count       = (var.encryption_state != false ? 1 : 0 )
    description = "instances crypto key"

    tags = {
        Name = "CryptedEncrypted"
        Env  = "mksplayground"
    }
}

resource "aws_instance" "nixos" {
    count           = (var.deploy_nixos != false ? 1 : 0 )
    ami             = module.nixos_image.ami
    instance_type   = var.instance_type
    security_groups = [ aws_security_group.nixos[0].name ]
    key_name        = aws_key_pair.generated_key.key_name

    root_block_device {
        encrypted   = var.encryption_state
        #kms_key_id  = aws_kms_key.encrypt[0].key_id
        volume_size = var.ec2_volume_size

        tags = {
            Name = "NixOS"
            Env  = "mksplayground"
        }
    }

    tags = {
        Name = "NixOS"
        Env  = "mksplayground"
    }
}

//Use nixos-instantiate for check configuration drift
//Error: failed to execute ".terraform/modules/deploy_nixos/deploy_nixos/nixos-instantiate.sh": running (instantiating):  'nix-instantiate' '--show-trace' '--expr' $'\n  { system, configuration, ... }:\n  let\n    os = import <nixpkgs/nixos> { inherit system configuration; };\n    inherit (import <nixpkgs/lib>) concatStringsSep;\n  in {\n    substituters = concatStringsSep " " os.config.nix.binaryCaches;\n    trusted-public-keys = concatStringsSep " " os.config.nix.binaryCachePublicKeys;\n    drv_path = os.system.drvPath;\n    out_path = os.system;\n    inherit (builtins) currentSystem;\n  }' '--argstr' 'configuration' '/home/max/Projects/HomeInfrastructure/nixos/configuration.nix' '--argstr' 'system' 'x86_64-linux' -A out_path
//│ .terraform/modules/deploy_nixos/deploy_nixos/nixos-instantiate.sh: line 44: nix-instantiate: command not found
//module "deploy_nixos" {
//    count       = (var.deploy_nixos != false ? 1 : 0 )
//    source = "git::https://github.com/tweag/terraform-nixos.git//deploy_nixos?ref=5f5a0408b299874d6a29d1271e9bffeee4c9ca71"
//    nixos_config = "${path.module}/../nixos/configuration.nix"
//    target_host = aws_instance.nixos.public_ip
//    ssh_private_key_file = local_file.machine_ssh_key.filename
//    ssh_agent = false
//}

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

resource "aws_instance" "server" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.generated_key.key_name
  security_groups = [ aws_security_group.server.name ]

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
    Name = "Server"
    Env  = "mksplayground"
  }
}

resource "aws_eip" "server" {
  instance = aws_instance.server.id
  vpc      = true

  tags = {
    Name = "Server"
    Env  = "mksplayground"
  }
}
