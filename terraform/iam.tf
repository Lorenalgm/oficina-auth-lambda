# O AWS Academy Learner Lab não permite criar nem anexar políticas a IAM roles.
# O ambiente já fornece a role LabRole, que tem permissão ampla o bastante para
# a Lambda: execução básica, ENI na VPC (AWSLambdaVPCAccessExecutionRole) e
# leitura no Secrets Manager. Fora do Learner Lab, o correto seria uma role
# dedicada com o mínimo privilégio — está registrado no ADR-001.
data "aws_iam_role" "lambda" {
  name = var.lambda_role_name
}
