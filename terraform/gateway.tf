resource "aws_apigatewayv2_api" "principal" {
  name          = "${var.projeto}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["authorization", "content-type", "x-request-id"]
  }
}

# ---------------------------------------------------------------------------
# Rota pública de autenticação: recebe o CPF e devolve o JWT.
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "authenticate" {
  api_id                 = aws_apigatewayv2_api.principal.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth["authenticate"].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "authenticate" {
  api_id    = aws_apigatewayv2_api.principal.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.authenticate.id}"
}

resource "aws_lambda_permission" "authenticate" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth["authenticate"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.principal.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------
# Rotas protegidas: o Authorizer valida o JWT e o Gateway encaminha ao cluster.
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id                            = aws_apigatewayv2_api.principal.id
  name                              = "${var.projeto}-jwt"
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.auth["authorizer"].invoke_arn
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]

  # Respostas do authorizer ficam em cache por 5 min, reduzindo invocações.
  authorizer_result_ttl_in_seconds = 300
}

resource "aws_lambda_permission" "authorizer" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth["authorizer"].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.principal.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.jwt.id}"
}

resource "aws_apigatewayv2_integration" "backend" {
  api_id                 = aws_apigatewayv2_api.principal.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "${var.backend_base_url}/api/{proxy}"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "/api/$request.path.proxy"
  }
}

resource "aws_apigatewayv2_route" "backend" {
  api_id             = aws_apigatewayv2_api.principal.id
  route_key          = "ANY /api/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

# ---------------------------------------------------------------------------
# Stage único com auto-deploy e log de acesso em JSON.
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "gateway" {
  name              = "/aws/apigateway/${var.projeto}"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.principal.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      correlation_id = "$context.requestId"
      route          = "$context.routeKey"
      method         = "$context.httpMethod"
      status         = "$context.status"
      duration_ms    = "$context.responseLatency"
      erro           = "$context.error.message"
    })
  }

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }
}
