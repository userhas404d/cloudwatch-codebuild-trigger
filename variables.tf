variable "cloudwatch_event_name" {
  type        = "string"
  description = "Name of the cloudwatch event"
}

variable "schedule_expression" {
  type        = "string"
  description = "The scheduling expression. Default is 2am every day."
  default     = "cron(0 2 * * ? *)"
}

variable "codebuild_project_name" {
  type        = "string"
  description = "Name of the codebuild project to trigger"
}
