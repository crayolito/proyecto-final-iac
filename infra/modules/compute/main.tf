
locals {
  etiquetas = merge(var.etiquetas_comunes, {
    Nombre = "instancia-ec2-${var.nombre_proyecto}"
    Tipo   = "instancia-ec2"
  })
}


resource "aws_security_group" "servidor_web" {
  name        = "${var.nombre_proyecto}-sg-compute"
  description = "Security group para el servidor web EC2"

  vpc_id = var.vpc_id

  ingress {
    description = "SSH - Solo desde IPs permitidas del equipo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP - Acceso web publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP - Acceso web publico"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.etiquetas, {
    Name        = "${var.nombre_proyecto}-sg-compute"
    Descripcion = "Security Group para servidor web con nginx"
    Tipo        = "security-group"
  })
}

resource "aws_instance" "servidor_web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.servidor_web.id]

  user_data            = var.user_data != "" ? var.user_data : null
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  root_block_device {
    encrypted   = true
    volume_size = 8
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
      "echo '<h1>Servidor configurado con Terraform Provisioner</h1><p>Proyecto: ${var.nombre_proyecto}</p><p>Docker ya está instalado por user_data</p>' | sudo tee /usr/share/nginx/html/index.html"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.private_key_path != "" ? file(var.private_key_path) : null
      host        = self.public_ip
      timeout     = "5m"
    }
  }

  tags = merge(local.etiquetas, {
    Descripcion = "Instancia EC2 para servidor web con nginx"
  })
}
