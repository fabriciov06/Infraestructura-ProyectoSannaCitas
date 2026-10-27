# Configuración del proveedor de AWS
provider "aws" {
  region = var.aws_region
}

# ==========================================
# 1. RED Y SEGURIDAD (Amazon VPC y ALB)
# ==========================================

# VPC principal para la clínica
resource "aws_vpc" "clinica_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.entorno}-sannacitas-vpc"
  }
}

# Subredes públicas para el Balanceador (ALB)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.clinica_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.entorno}-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.clinica_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "${var.entorno}-public-subnet-2"
  }
}

# Internet Gateway para dar salida a internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.clinica_vpc.id

  tags = {
    Name = "${var.entorno}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clinica_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.entorno}-public-rt"
  }
}

resource "aws_route_table_association" "rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group para el ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.entorno}-alb-sg"
  description = "Permitir trafico HTTP/HTTPS web"
  vpc_id      = aws_vpc.clinica_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer (ALB) - Con su Listener (¡lo que preguntó el profesor!)
resource "aws_lb" "sannacitas_alb" {
  name               = "sannacitas-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "sannacitas-app-load-balancer"
  }
}

# Listener HTTP en puerto 80 (para el MVP y redirección de prueba)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.sannacitas_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bienvenido a la API de SannaCitas - Operativo"
      status_code  = "200"
    }
  }
}


# ==========================================
# 2. CÓMPUTO (Amazon ECS - Backend API B)
# ==========================================

resource "aws_ecs_cluster" "sannacitas_cluster" {
  name = "${var.entorno}-sannacitas-cluster"
}

resource "aws_ecs_task_definition" "api_task" {
  family                   = "sannacitas-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "api-b"
      image     = "public.ecr.aws/docker/library/nginx:alpine" # Imagen ligera de prueba para el MVP
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}


# ==========================================
# 3. PROCESAMIENTO ASÍNCRONO (Notificaciones)
# ==========================================

# Cola SQS
resource "aws_sqs_queue" "cola_notificaciones_citas" {
  name                      = "${var.entorno}-${var.nombre_cola_sqs}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

# Tema SNS (SMS / Alertas)
resource "aws_sns_topic" "notificaciones_pacientes" {
  name = "${var.entorno}-sannacitas-alertas-topic"
}

# Identidad SES (Correos)
resource "aws_ses_email_identity" "verificacion_correo" {
  email = var.email_notificaciones
}

# Rol IAM para Lambda
resource "aws_iam_role" "lambda_procesador_role" {
  name = "${var.entorno}-lambda-procesador-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_sqs_sns_policy" {
  name = "${var.entorno}-lambda-sqs-sns-policy"
  role = aws_iam_role.lambda_procesador_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.cola_notificaciones_citas.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_dummy" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content  = "exports.handler = async (event) => { console.log('Procesando cita:', JSON.stringify(event)); return 'OK'; };"
    filename = "index.js"
  }
}

resource "aws_lambda_function" "procesador_notificaciones" {
  filename         = data.archive_file.lambda_dummy.output_path
  function_name    = "${var.entorno}-sannacitas-lambda-procesador"
  role             = aws_iam_role.lambda_procesador_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.cola_notificaciones_citas.arn
  function_name    = aws_lambda_function.procesador_notificaciones.arn
  enabled          = true
  batch_size       = 5
}