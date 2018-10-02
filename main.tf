data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  codebuild_project_arn = "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.codebuild_project_name}"
}

data "aws_iam_policy_document" "codebuild_trigger_policy_doc" {
  statement {
    sid = "AllowStartBuild"

    actions = [
      "codebuild:StartBuild",
    ]

    resources = [
      "${local.codebuild_project_arn}",
    ]
  }
}

resource "aws_iam_policy" "codebuild_trigger_policy" {
  name   = "${var.codebuild_project_name}-cloudwatch-trigger-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.codebuild_trigger_policy_doc.json}"
}

data "aws_iam_policy_document" "codebuild_trigger_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_trigger_role" {
  name               = "${var.codebuild_project_name}-cloudwatch-trigger"
  assume_role_policy = "${data.aws_iam_policy_document.codebuild_trigger_assume_role_policy.json}"
}

resource "aws_iam_policy_attachment" "this" {
  name       = "cloudwatch-codebuild-allow-trigger"
  roles      = ["${aws_iam_role.cloudwatch_trigger_role.name}"]
  policy_arn = "${aws_iam_policy.codebuild_trigger_policy.arn}"
}

resource "aws_cloudwatch_event_rule" "codebuild_trigger" {
  name                = "${var.cloudwatch_event_name}"
  description         = "Scheduled ${var.codebuild_project_name} build"
  schedule_expression = "${var.schedule_expression}"
}

resource "aws_cloudwatch_event_target" "codebuild_target" {
  target_id = "TriggerCodebuild"
  rule      = "${aws_cloudwatch_event_rule.codebuild_trigger.name}"
  arn       = "${local.codebuild_project_arn}"
  role_arn  = "${aws_iam_role.cloudwatch_trigger_role.arn}"
}
