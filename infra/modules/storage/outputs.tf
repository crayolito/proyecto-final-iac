
output "bucket_nombre" {
  description = "Nombre del bucket S3 creado"
  value       = aws_s3_bucket.bucket.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.bucket.arn
}
