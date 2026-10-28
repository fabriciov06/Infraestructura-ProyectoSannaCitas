variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "entorno" {
  type    = string
  default = "dev"
}

variable "nombre_cola_sqs" {
  type    = string
  default = "notificaciones-citas-queue"
}

variable "email_notificaciones" {
  type    = string
  default = "admin@sannacitas.com"
}