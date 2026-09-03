data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/build/remediation.zip"
}

locals {
  function_name = "${var.name_prefix}-sg-remediation"

  security_group_arn = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:security-group/${var.security_group_id}"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowLambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-remediation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name = "${var.name_prefix}-remediation-role"
  }
}

resource "aws_cloudwatch_log_group" "remediation" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 3

  tags = {
    Name = "${var.name_prefix}-remediation-logs"
  }
}

data "aws_iam_policy_document" "lambda_execution" {
  statement {
    sid    = "WriteRemediationLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.remediation.arn}:*"
    ]
  }

  statement {
    sid    = "RevokeProjectSecurityGroupIngress"
    effect = "Allow"

    actions = [
      "ec2:RevokeSecurityGroupIngress"
    ]

    resources = [
      local.security_group_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_execution" {
  name        = "${var.name_prefix}-remediation-policy"
  description = "Allows remediation of public ingress on one project security group"
  policy      = data.aws_iam_policy_document.lambda_execution.json

  tags = {
    Name = "${var.name_prefix}-remediation-policy"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_execution.arn
}

resource "aws_lambda_function" "remediation" {
  function_name = local.function_name
  description   = "Revokes public ingress added to the hardened EC2 security group"

  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256

  role    = aws_iam_role.lambda.arn
  handler = "handler.lambda_handler"
  runtime = "python3.13"

  architectures = ["arm64"]
  memory_size   = 128
  timeout       = 30

  environment {
    variables = {
      TARGET_SECURITY_GROUP_ID = var.security_group_id
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    Name = local.function_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_execution,
    aws_cloudwatch_log_group.remediation
  ]
}

resource "aws_cloudwatch_event_rule" "public_ingress" {
  name        = "${var.name_prefix}-detect-public-ingress"
  description = "Detects ingress authorization on the project EC2 security group"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]

    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["AuthorizeSecurityGroupIngress"]

      requestParameters = {
        groupId = [var.security_group_id]
      }
    }
  })

  tags = {
    Name = "${var.name_prefix}-detect-public-ingress"
  }
}

resource "aws_cloudwatch_event_target" "remediation" {
  rule      = aws_cloudwatch_event_rule.public_ingress.name
  target_id = "SecurityGroupRemediation"
  arn       = aws_lambda_function.remediation.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.public_ingress.arn
}

