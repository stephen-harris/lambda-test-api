locals {
    function_name = "api_health_check"
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "availability_check" {
  function_name    = local.function_name
  filename         = "lambda.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role    = aws_iam_role.iam_for_lambda.arn
  handler = "lambda.handler"

  runtime     = "nodejs12.x"
  timeout     = 60
  memory_size = 512

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.network_interfaces,
    aws_cloudwatch_log_group.lambda_logs,
  ]
}

resource "aws_security_group" "lambda_sg" {
  name        = "availability_check_lambda"
  description = "Assigned to availability check lambda"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "availability-check-lambda"
  }

}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
}



resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy = file("./cloudwatch_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy" "network_interfaces" {
  name = "network_interfaces"
  path        = "/"
  description = "IAM policy for managing network interfaces"
  policy = file("./network_interface_policy.json")
}

resource "aws_iam_role_policy_attachment" "network_interfaces" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.network_interfaces.arn
}