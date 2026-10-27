output "alb_dns_name" {
  description = "URL publica del Balanceador de Carga (ALB) para probar el acceso web"
  value       = aws_lb.sannacitas_alb.dns_name
}

output "sqs_queue_url" {
  description = "URL de la cola SQS"
  value       = aws_sqs_queue.cola_notificaciones_citas.id
}

output "sns_topic_arn" {
  description = "ARN del tema SNS"
  value       = aws_sns_topic.notificaciones_pacientes.arn
}

output "lambda_function_name" {
  description = "Nombre de la funcion Lambda"
  value       = aws_lambda_function.procesador_notificaciones.function_name
}