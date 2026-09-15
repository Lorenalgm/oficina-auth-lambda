output "api_url" {
  description = "URL base do API Gateway."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "auth_endpoint" {
  description = "Endpoint de autenticacao por CPF."
  value       = "${aws_apigatewayv2_stage.default.invoke_url}auth"
}

output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}
