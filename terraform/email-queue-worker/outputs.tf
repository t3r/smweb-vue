output "lambda_function_arn" {
  description = "ARN of the email queue worker Lambda."
  value       = aws_lambda_function.worker.arn
}

output "lambda_function_name" {
  description = "Name of the email queue worker Lambda."
  value       = aws_lambda_function.worker.function_name
}

output "schedule_rule_arn" {
  description = "EventBridge rule ARN that invokes the Lambda."
  value       = aws_cloudwatch_event_rule.schedule.arn
}

output "lambda_role_arn" {
  description = "Execution role ARN for the Lambda."
  value       = aws_iam_role.lambda.arn
}
