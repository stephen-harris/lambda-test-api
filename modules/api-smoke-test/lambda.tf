locals {
  function_name = "smoke-tests-${var.service}"
  service_title_case = replace(title(replace(var.service, "-", " ")), " ", "")
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir = "${path.module}/src"
  depends_on = [null_resource.copy_spec_files_in]
}

resource "null_resource" "copy_spec_files_in" {
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/src/spec
      cp -r ${var.spec_path} ${path.module}/src/spec
EOT
  }
}

resource "aws_lambda_function" "smoke_test" {
  function_name    = local.function_name
  filename         = "${path.module}/lambda.zip"
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

  environment {
    variables = {
      SERVICE = var.service,
      DD_TAGS = join(" ", toset(concat([
        "service:${var.service}"
      ], var.dd_tags)))
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_cloudwatch_logs,
    aws_iam_role_policy_attachment.network_interfaces,
    aws_cloudwatch_log_group.lambda_cloudwatch_logs,
  ]
}


resource "aws_security_group" "smoke_test_lambda_sg" {
  name        = "smoke_test_${var.service}_sg"
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
    Name = "smoke_test_${var.service}_sg"
    Service = var.service
  }

}

resource "aws_iam_role" "iam_for_smoke_test_lambda" {
  name = "SmokeTest${local.service_title_case}LambdaRole"

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
  policy      = file("${path.module}/cloudwatch_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs" {
  role       = aws_iam_role.iam_for_smoke_test_lambda.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logs.arn
}

resource "aws_iam_policy" "network_interfaces" {
  name        = "SmokeTest${local.service_title_case}AllowManagingNetworkInterfaces"
  path        = "/"
  description = "IAM policy for managing network interfaces"
  policy      = file("${path.module}/network_interface_policy.json")
}

resource "aws_iam_role_policy_attachment" "network_interfaces" {
  role       = aws_iam_role.iam_for_smoke_test_lambda.name
  policy_arn = aws_iam_policy.network_interfaces.arn
}

resource "aws_iam_policy" "retrieve_ssm_secrets" {
  name        = "SmokeTest${local.service_title_case}AllowGetParameters"
  path        = "/"
  description = "IAM policy to allow lambda to retrieve secrets from /smoke-tests/service/ path"
  policy = templatefile("${path.module}/ssm_policy.json", {
    account : data.aws_caller_identity.current.account_id
    region : data.aws_region.current.name
    service: var.service
    master_key_arn : aws_kms_key.smoke_tests_master_key.arn
  })
}

resource "aws_iam_role_policy_attachment" "retrieve_ssm_secrets" {
  role       = aws_iam_role.iam_for_smoke_test_lambda.name
  policy_arn = aws_iam_policy.retrieve_ssm_secrets.arn
}

resource "aws_kms_key" "smoke_tests_master_key" {
  description = "Master key used by smoke test lambda for ${var.service}"
}


resource "aws_kms_alias" "smoke_tests_master_key" {
  name          = "alias/smoke-tests/${var.service}"
  target_key_id = aws_kms_key.smoke_tests_master_key.key_id
}