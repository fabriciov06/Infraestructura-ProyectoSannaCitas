# Configuración del proveedor de AWS usando variables
provider "aws" {
  region = var.aws_region
}

# 1. Creación de la cola SQS para desacoplar las notificaciones
resource "aws_sqs_queue" "cola_notificaciones_citas" {
  name                      = "${var.entorno}-${var.nombre_cola_sqs}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400 # Retención de 1 día
  receive_wait_time_seconds = 10
}

# 2. Creación del tema SNS para envío de correos/SMS a pacientes
resource "aws_sns_topic" "notificaciones_pacientes" {
  name = "${var.entorno}-sannacitas-alertas-topic"
}