locals {
  etiquetas = merge(var.etiquetas_comunes, {
    Nombre = "role-ec2-${var.nombre_proyecto}"
    Tipo   = "iam-role-ec2"
  })
}
data "aws_iam_policy_document" "asumir_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rol_ec2" {
  name = "rol-ec2-${var.nombre_proyecto}"
  assume_role_policy = data.aws_iam_policy_document.asumir_role.json
  tags               = local.etiquetas
}
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.rol_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
data "aws_iam_policy_document" "politica_minima" {
  statement {
    sid       = "S3ReadBucket"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
  }

  statement {
    sid       = "SecretsReadByPath"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.secrets_path_arn]
  }

  statement {
    sid       = "SSMParameterReadByPath"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:*:*:parameter${var.ssm_parameter_path}*"]
  }
}
resource "aws_iam_role_policy" "politica_minima" {
  name   = "politica-minima-${var.nombre_proyecto}"
  role   = aws_iam_role.rol_ec2.id
  policy = data.aws_iam_policy_document.politica_minima.json
}
resource "aws_iam_instance_profile" "perfil_ec2" {
  name = "perfil-ec2-${var.nombre_proyecto}"
  role = aws_iam_role.rol_ec2.name
  tags = local.etiquetas
}
