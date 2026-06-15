resource "aws_chatbot_teams_channel_configuration" "test" {
  count = var.notification_type == "teams" ? 1 : 0
  channel_id         = var.teams_channel_id
  configuration_name = "teams_client"
  iam_role_arn       = aws_iam_role.chatbot_role.arn
  team_id            = var.team_id
  tenant_id          = var.teams_tenant_id
  sns_topic_arns     = [aws_sns_topic.alert_notifier.arn]
  channel_name       = "Observability"
  logging_level      = "INFO"
  guardrail_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

resource "aws_iam_role" "chatbot_role" {
  name = "ChatbotTeamsRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_readonly" {
  role       = aws_iam_role.chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}