resource "aws_chatbot_slack_channel_configuration" "slack" {
  count = var.notification_type == "slack" ? 1 : 0  
  configuration_name = "slack-client"
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  slack_channel_id   = var.slack_channel_id
  slack_team_id      = var.slack_team_id
  sns_topic_arns     = [aws_sns_topic.alert_notifier.arn]
  logging_level      = "INFO"
  guardrail_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}