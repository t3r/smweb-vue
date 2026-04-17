data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_ses" {
  statement {
    sid    = "SesSend"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = [
      "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/${var.ses_send_identity}",
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ses" {
  name   = "${var.function_name}-ses"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_ses.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "worker" {
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "src/handler.handler"
  runtime       = "nodejs24.x"
  architectures = ["arm64"]

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_mb

  environment {
    variables = {
      API_BASE_URL             = var.api_base_url
      EMAIL_QUEUE_BEARER_TOKEN = var.email_queue_bearer_token
      SES_FROM                 = var.ses_from
      NOTIFY_REVIEWER_EMAILS   = var.notify_reviewer_emails
      QUEUE_BATCH_SIZE         = var.queue_batch_size
      VISIBILITY_TIMEOUT_SEC   = var.visibility_timeout_sec
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.function_name}-schedule"
  description         = "Trigger email queue worker on a fixed rate"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "EmailQueueWorker"
  arn       = aws_lambda_function.worker.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.worker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
