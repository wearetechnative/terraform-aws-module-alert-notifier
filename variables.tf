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

# variable "monitoring_account_configuration" {
#   description = "Configuration settings of the monitoring account."
#   type = object({
#     sqs_name    = string
#     sqs_region  = string
#     sqs_account = number
#   })
# }

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

variable "endpoint" {
  description = "endpoint of amazonz q client"
  type = string
}

variable "team_id" {
  description = "Teams Id"
  type = string
}

variable "teams_channel_id" {
  description = "Teams Channel Id"
  type = string
}

variable "teams_tenant_id" {
  description = "Teams Tenant Id"
  type = string
} 