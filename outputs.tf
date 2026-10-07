output "sqs_queue_url" {
  description = "URL de la cola SQS creada para notificaciones"
  value       = aws_sqs_queue.cola_notificaciones_citas.id
}

output "sns_topic_arn" {
  description = "ARN del tema SNS para envío de alertas"
  value       = aws_sns_topic.notificaciones_pacientes.arn
}