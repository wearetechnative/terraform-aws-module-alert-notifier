# Default sns topic which receives all events/payloads and forwards it to lambda notification forwarder.
resource "aws_sns_topic" "alert_notifier" {
  name              = "aws-to-teams"
  kms_master_key_id = var.kms_key_arn
}

