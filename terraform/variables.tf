variable "aws_region" {
  description = "Região AWS onde tudo é provisionado."
  type        = string
  default     = "us-east-1"
}

variable "tfstate_bucket" {
  description = "Bucket S3 com os states dos demais repositórios."
  type        = string
}

variable "projeto" {
  description = "Prefixo aplicado aos nomes dos recursos."
  type        = string
  default     = "oficina"
}

variable "backend_base_url" {
  description = <<-DESC
    URL do backend para onde o Gateway encaminha /api/*.
    Durante o desenvolvimento aponta para o Railway (o cluster kind local não é
    alcançável pela AWS); na gravação, para o NLB do Ingress no EKS.
  DESC
  type        = string
}

variable "jwt_ttl_seconds" {
  description = "Validade do token emitido, em segundos."
  type        = number
  default     = 3600
}
