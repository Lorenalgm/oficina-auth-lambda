data "archive_file" "pacote" {
  type        = "zip"
  source_dir  = "${path.module}/../build"
  output_path = "${path.module}/../dist/lambda.zip"
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

  environment {
    variables = {
      SECRET_ARN      = data.terraform_remote_state.db.outputs.secret_arn
      JWT_ISSUER      = "${var.projeto}-auth"
      OS_SERVICE_URL  = var.backend_base_url
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
