Create one or more examples here...
module "teams-notifier" {

  source = "git@github.com:wearetechnative/terraform-aws-module-alert-notifier.git"

  sqs_dlq_arn = data.terraform_remote_state.sqs_dlq.outputs.dlq_arn
  kms_key_arn = data.terraform_remote_state.kms.outputs.default_kms_key_arn
  team_id = "#######"
  teams_channel_id = "#######"
  teams_tenant_id = "#######"


  # time in seconds max 900
  lambda_timeout = 120
}  