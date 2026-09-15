data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.projeto}-auth-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Necessária para anexar a ENI da Lambda às subnets privadas.
resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "segredo" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.terraform_remote_state.db.outputs.secret_arn]
  }
}

resource "aws_iam_role_policy" "segredo" {
  name   = "ler-segredo"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.segredo.json
}
