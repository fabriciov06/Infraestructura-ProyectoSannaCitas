variable "aws_region" {
  description = "Región de AWS para el despliegue de la clínica"
  type        = string
  default     = "us-east-1"
}

variable "entorno" {
  description = "Entorno de despliegue (ej. dev, prod)"
  type        = string
  default     = "produccion"
}

variable "nombre_cola_sqs" {
  description = "Nombre de la cola SQS para notificaciones"
  type        = string
  default     = "sannacitas-notificaciones-queue"
}