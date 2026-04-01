variable "aws_region" {
  type        = string
  description = "AWS region for Lambda, EventBridge, and IAM."
}

variable "assume_role_arn" {
  type        = string
  sensitive   = true
  default     = ""
  description = <<-EOT
    If non-empty, the AWS provider assumes this IAM role for all resource changes.
    The caller credentials (e.g. GitHub OIDC session) must be allowed sts:AssumeRole on this ARN.
    Leave empty to use the ambient credential chain only.
  EOT
}

variable "function_name" {
  type        = string
  description = "Lambda function name (also used for IAM/log group name prefix)."
  default     = "fg-scenemodels-email-queue-worker"
}

variable "lambda_zip_path" {
  type        = string
  description = "Path to bundle.zip relative to this Terraform working directory (CI: ../lambda/email-queue-worker/bundle.zip from repo root)."
}

variable "api_base_url" {
  type        = string
  description = "Public site/API base URL without trailing slash (reviewer links, queue API)."
}

variable "email_queue_bearer_token" {
  type        = string
  sensitive   = true
  description = "Must match server EMAIL_QUEUE_BEARER_TOKEN."
}

variable "ses_from" {
  type        = string
  description = "Verified SES From identity (email or domain)."
}

variable "ses_send_identity" {
  type        = string
  description = "SES verified identity name for IAM (domain or email), used in arn:aws:ses:region:account:identity/NAME."
  default     = "flightgear.org"
}

variable "notify_reviewer_emails" {
  type        = string
  description = "Comma-separated addresses for position_request.created digests."
}

variable "queue_batch_size" {
  type        = string
  description = "EMAIL_QUEUE_BEARER_TOKEN queue receive batch size."
  default     = "10"
}

variable "visibility_timeout_sec" {
  type        = string
  description = "Queue message visibility timeout (seconds)."
  default     = "900"
}

variable "schedule_expression" {
  type        = string
  description = "EventBridge schedule (e.g. rate(5 minutes))."
  default     = "rate(5 minutes)"
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds."
  default     = 120
}

variable "lambda_memory_mb" {
  type        = number
  description = "Lambda memory size in MB."
  default     = 256
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention for the function log group."
  default     = 14
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to supported resources."
  default     = {}
}
