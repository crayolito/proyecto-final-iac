locals {
  etiquetas = merge(var.etiquetas_comunes, {
    Name = "red-principal-${var.nombre_proyecto}"
    Tipo = "red-virtual"
  })
}

resource "aws_vpc" "red_principal" {
  cidr_block = var.cidr_vpc
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = merge(local.etiquetas, {
    Descripcion = "VPC principal del proyecto con CIDR ${var.cidr_vpc}"
  })
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.red_principal.id

  tags = merge(local.etiquetas, {
    Name = "igw-${var.nombre_proyecto}"
    Tipo = "internet-gateway"
  })
}

resource "aws_subnet" "subred_publica" {
  vpc_id     = aws_vpc.red_principal.id
  cidr_block = var.cidr_subred_publica

  map_public_ip_on_launch = true

  tags = merge(local.etiquetas, {
    Name = "subred-publica-${var.nombre_proyecto}"
    Tipo = "subred-publica"
  })
}

resource "aws_subnet" "subred_privada" {
  vpc_id     = aws_vpc.red_principal.id
  cidr_block = var.cidr_subred_privada

  map_public_ip_on_launch = false

  tags = merge(local.etiquetas, {
    Name = "subred-privada-${var.nombre_proyecto}"
    Tipo = "subred-privada"
  })
}


resource "aws_route_table" "rt_publica" {
  vpc_id = aws_vpc.red_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.etiquetas, {
    Name = "rt-publica-${var.nombre_proyecto}"
    Tipo = "tabla-rutas-publica"
  })
}

resource "aws_route_table_association" "asoc_publica" {
  subnet_id = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.rt_publica.id
}

resource "aws_route_table" "rt_privada" {
  vpc_id = aws_vpc.red_principal.id

  tags = merge(local.etiquetas, {
    Name = "rt-privada-${var.nombre_proyecto}"
    Tipo = "tabla-rutas-privada"
  })
}

resource "aws_route_table_association" "asoc_privada" {
  subnet_id = aws_subnet.subred_privada.id
  route_table_id = aws_route_table.rt_privada.id
}
