# Default sns topic which receives all events/payloads and forwards it to lambda notification forwarder.
resource "aws_sns_topic" "alert_notifier" {
  name              = "aws-to-teams"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sns_topic" "alert_forwarder" {
  name              = "event_parser"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sns_topic_policy" "alert_forwarder" {
  arn    = aws_sns_topic.alert_forwarder.arn
  policy = data.aws_iam_policy_document.alert_forwarder_topic_policy.json
}

data "aws_iam_policy_document" "alert_forwarder_topic_policy" {
  statement {
    sid    = "AllowTopicOwnerActions"
    effect = "Allow"

    actions = [
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:GetTopicAttributes",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:Subscribe",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    resources = [aws_sns_topic.alert_forwarder.arn]
  }

  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.alert_forwarder.arn]
  }
}


resource "aws_sns_topic_subscription" "lambda_event_parser" {

  topic_arn = aws_sns_topic.alert_forwarder.arn
  protocol  = "lambda"

  endpoint               = module.lambda_event_parser.lambda_function_arn
  endpoint_auto_confirms = true
  raw_message_delivery   = false
  redrive_policy         = jsonencode({ deadLetterTargetArn = var.sqs_dlq_arn })
}
