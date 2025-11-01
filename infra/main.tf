terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  etiquetas_comunes = {
    Proyecto   = "proyecto-final-iac"
    Ambiente   = "desarrollo"
    Creado_con = "Terraform"
  }

  user_data = <<-EOT
    #!/bin/bash
    # Le decimos que use el interprete de bash 

    # Configuracion para el script para que se detenga si hay un error
    set -euxo pipefail

    # Actualiza el sistema operativo
    dnf update -y
    
    # Instala Docker
    dnf install -y docker
    
    # Hace que Docker se inicie automaticamente al arranchar la maquina
    systemctl enable docker
    
    # Inicia Docker
    systemctl start docker

    # Le da permisos al usuario para usar docker
    # Agrega el usuario ec2-user al grupo docker
    usermod -aG docker ec2-user
  EOT
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.nombre_proyecto}-key"
  public_key = var.public_ssh_key
}

module "network" {
  source = "./modules/network"

  nombre_proyecto   = var.nombre_proyecto
  etiquetas_comunes = local.etiquetas_comunes
}

module "compute" {
  source = "./modules/compute"

  nombre_proyecto   = var.nombre_proyecto
  etiquetas_comunes = local.etiquetas_comunes



  ami_id               = data.aws_ami.al2023.id
  instance_type        = "t3.micro"
  key_name             = aws_key_pair.this.key_name
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.subred_publica_id
  private_key_path     = var.private_key_path
  user_data            = local.user_data
  iam_instance_profile = module.iam.instance_profile_name
}

module "storage" {
  source = "./modules/storage"

  nombre_proyecto   = var.nombre_proyecto
  etiquetas_comunes = local.etiquetas_comunes

  bucket_prefix = "proyecto-iac"
  force_destroy = true
}

module "iam" {
  source = "./modules/iam"

  nombre_proyecto   = var.nombre_proyecto
  etiquetas_comunes = local.etiquetas_comunes

  s3_bucket_arn      = module.storage.bucket_arn
  secrets_path_arn   = "arn:aws:secretsmanager:${var.region}:*:secret:proyecto-iac/*"
  ssm_parameter_path = "/proyecto-iac/"
}
