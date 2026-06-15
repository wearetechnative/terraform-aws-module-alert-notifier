# VARIABLES
variable "eventbridge_rules" {
  description = "EventBridge rule settings."
  type = map(object({
    description : string
    state : string
    event_pattern : string
    })
  )
  default = {}
}

variable "sqs_dlq_arn" {
  description = "ARN of the Dead Letter Queue."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key."
  type        = string
}

variable "source_directory_location" {
  description = "Source Directory location for the custom alarm creator actions.py."
  type        = string
  default     = null
}

variable "lambda_timeout" {
  description = "Lambda function timeout."
  type        = number
  default     = 180
}

# variable "endpoint" {
#   description = "endpoint of amazonz q client"
#   type = string
# }

variable "team_id" {
  description = "Teams Id"
  type = string
  default = null
  validation {
    condition = (
      var.notification_type != "teams" ||
      var.team_id != null
    )
    error_message = "teams_id requires a value because you have selected 'teams' as notification type"
  }
}

variable "teams_channel_id" {
  description = "Teams Channel Id"
  type = string
  default = null
  validation   {
    condition = (
      var.notification_type != "teams" ||
      var.teams_channel_id != null
    )
    error_message = "teams_channel_id requires a value because you have selected 'teams' as notification type"
  }
}

variable "teams_tenant_id" {
  description = "Teams Tenant Id"
  type = string
  default = null
  validation {
    condition = (
      var.notification_type != "teams" ||
      var.teams_tenant_id != null
    )
    error_message = "Teams_Tenant_id requires a value because you have selected 'teams' as notification type"
  }
} 

variable "notification_type" {
  description = "Select an endpoint for the alerts(slack or teams)"
  type = string
  validation {
    condition = var.notification_type == "teams" || var.notification_type == "slack"
    error_message = "The value of notifcation type can either be 'teams' or 'slack'"
  }
}

variable "slack_channel_id" {
  description = "channel id of your slack channel"
  type = string
  default = null
  validation {
    condition = (
      var.notification_type != "slack" ||
      var.slack_channel_id != null
    )
    error_message = "Slack_channel_id requires a value you have selected 'slack' as notification type"
  }
}
variable "slack_team_id" {
  description = "ID of the Slack workspace authorized with AWS Chatbot"
  type = string 
  default = null 
  validation {
    condition = (
      var.notification_type != "slack" ||
      var.slack_team_id != null
    )
    error_message = "Slack_team_id requires a value because you have selected 'slack' as notification type"
  }
}
