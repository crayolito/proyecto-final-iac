locals {
  etiquetas = merge(var.etiquetas_comunes, {
    Nombre = "bucket-s3-${var.nombre_proyecto}"
    Tipo   = "almacenamiento-s3"
  })
}

resource "random_id" "sufijo" {
  byte_length = 4
}

resource "aws_s3_bucket" "bucket" {
  bucket = lower("${var.bucket_prefix}-${var.nombre_proyecto}-${random_id.sufijo.hex}")
  force_destroy = var.force_destroy

  tags = merge(local.etiquetas, {
    Descripcion = "Bucket S3 seguro con cifrado y versionado"
  })
}

resource "aws_s3_bucket_versioning" "versionado" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
