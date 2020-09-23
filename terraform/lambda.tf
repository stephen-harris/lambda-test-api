locals {
  function_name = "smoke-tests"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "smoke_test" {
  function_name    = local.function_name
  filename         = "lambda.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role    = aws_iam_role.iam_for_smoke_test_lambda.arn
  handler = "lambda.handler"

  runtime     = "nodejs12.x"
  timeout     = 60
  memory_size = 512

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = [aws_security_group.smoke_test_lambda_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_cloudwatch_logs,
    aws_iam_role_policy_attachment.network_interfaces,
    aws_cloudwatch_log_group.lambda_cloudwatch_logs,
  ]
}

resource "aws_security_group" "smoke_test_lambda_sg" {
  name        = "smoke_test_lambda_sg"
  description = "Assigned to smoke test lambda"
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
    Name = "smoke_test_lambda_sg"
  }

}

resource "aws_iam_role" "iam_for_smoke_test_lambda" {
  name = "SmokeTestLambdaRole"

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

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_cloudwatch_logs" {
  name        = "SmokeTestAllowCloudWatchLogging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = file("./cloudwatch_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs" {
  role       = aws_iam_role.iam_for_smoke_test_lambda.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logs.arn
}

resource "aws_iam_policy" "network_interfaces" {
  name        = "SmokeTestAllowManagingNetworkInterfaces"
  path        = "/"
  description = "IAM policy for managing network interfaces"
  policy      = file("./network_interface_policy.json")
}

resource "aws_iam_role_policy_attachment" "network_interfaces" {
  role       = aws_iam_role.iam_for_smoke_test_lambda.name
  policy_arn = aws_iam_policy.network_interfaces.arn
}

resource "aws_iam_policy" "retrieve_ssm_secrets" {
  name        = "SmokeTestAllowGetParameters"
  path        = "/"
  description = "IAM policy to allow lambda to retrieve secrets from /smoke-tests/ path"
  policy = templatefile("./ssm_policy.json", {
    account : data.aws_caller_identity.current.account_id
    region : data.aws_region.current.name,
    master_key_arn : aws_kms_key.smoke_tests_master_key.arn
  })
}

resource "aws_iam_role_policy_attachment" "retrieve_ssm_secrets" {
  role       = aws_iam_role.iam_for_smoke_test_lambda.name
  policy_arn = aws_iam_policy.retrieve_ssm_secrets.arn
}

resource "aws_kms_key" "smoke_tests_master_key" {
  description = "Master key used by smoke test lambda"
}


resource "aws_kms_alias" "smoke_tests_master_key" {
  name          = "alias/smoke-tests"
  target_key_id = aws_kms_key.smoke_tests_master_key.key_id
}