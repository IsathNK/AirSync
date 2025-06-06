terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "us-east-1"
}

# ────────────────────────────────────────────────────────────────────────────────
# Existing Resources (ECR, ECS Cluster, Log Group, IAM Role, Task Definition, SG)
# ────────────────────────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "airsync" {
  name = "airsync-backend"
}

resource "aws_ecs_cluster" "airsync_cluster" {
  name = "airsync-cluster"
}

resource "aws_cloudwatch_log_group" "airsync_log_group" {
  name              = "/ecs/airsync"
  retention_in_days = 7
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "airsync_task" {
  family                   = "airsync-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "airsync-backend"
      image = "${aws_ecr_repository.airsync.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airsync_log_group.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "airsync"
        }
      }

      environment = [
        {
          name  = "DATABASE_FILE"
          value = "/app/clips.db"
        }
      ]
    }
  ])
}

resource "aws_security_group" "airsync_sg" {
  name        = "airsync-sg"
  description = "Allow HTTP inbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 8000
    to_port     = 8000
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

data "aws_vpc" "default" {
  default = true
}

# ────────────────────────────────────────────────────────────────────────────────
# 1) Look up default-VPC subnets
# ────────────────────────────────────────────────────────────────────────────────
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ────────────────────────────────────────────────────────────────────────────────
# 2) ECS Service (Fargate) — keeps one task running
# ────────────────────────────────────────────────────────────────────────────────
resource "aws_ecs_service" "airsync_service" {
  name            = "airsync-service"
  cluster         = aws_ecs_cluster.airsync_cluster.id
  task_definition = aws_ecs_task_definition.airsync_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.airsync_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_ecs_task_definition.airsync_task
  ]
}
