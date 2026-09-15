data "archive_file" "pacote" {
  type        = "zip"
  source_dir  = "${path.module}/../build"
  output_path = "${path.module}/../dist/lambda.zip"
}

resource "aws_security_group" "lambda" {
  name        = "${var.projeto}-lambda"
  description = "Lambdas de autenticacao"
  vpc_id      = data.terraform_remote_state.db.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Libera o acesso das Lambdas ao Postgres. A regra vive aqui, e não no
# repositório do banco, para não criar dependência circular entre os states.
resource "aws_security_group_rule" "lambda_para_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.db.outputs.db_sg_id
  source_security_group_id = aws_security_group.lambda.id
  description              = "Lambda de autenticacao"
}

locals {
  funcoes = {
    authenticate = "src/authenticate.handler"
    authorizer   = "src/authorizer.handler"
  }
}

resource "aws_lambda_function" "auth" {
  for_each = local.funcoes

  function_name    = "${var.projeto}-${each.key}"
  role             = data.aws_iam_role.lambda.arn
  runtime          = "nodejs22.x"
  handler          = each.value
  filename         = data.archive_file.pacote.output_path
  source_code_hash = data.archive_file.pacote.output_base64sha256
  timeout          = 15
  memory_size      = 256

  vpc_config {
    subnet_ids         = data.terraform_remote_state.db.outputs.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      SECRET_ARN      = data.terraform_remote_state.db.outputs.secret_arn
      JWT_ISSUER      = "${var.projeto}-auth"
      JWT_TTL_SECONDS = var.jwt_ttl_seconds
      NODE_OPTIONS    = "--enable-source-maps"
    }
  }
}

resource "aws_cloudwatch_log_group" "auth" {
  for_each = local.funcoes

  name              = "/aws/lambda/${var.projeto}-${each.key}"
  retention_in_days = 7
}
