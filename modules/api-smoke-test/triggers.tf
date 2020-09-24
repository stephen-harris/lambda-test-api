resource "aws_cloudwatch_event_rule" "trigger_schedule" {
  name                = "smoke-tests-${var.service}-trigger-schedule"
  description         = "Fires every five minutes"
  schedule_expression = "cron(*/5 * * * ? *)"
  is_enabled = var.enable
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.trigger_schedule.name
  target_id = "SmokeTest${local.service_title_case}TriggerLambda"
  arn       = aws_lambda_function.smoke_test.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.smoke_test.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_schedule.arn
}