# Terraform AWS Teams Chatbot Alert Notifier ![](https://img.shields.io/badge/Terraform-Module-blue?style=plastic) ![](https://img.shields.io/badge/AWS-CloudWatch%20%7C%20SNS%20%7C%20Chatbot-orange?style=plastic)

[![](we-are-technative.png)](https://www.technative.nl)

## Overview

The **terraform-aws-module-alert-notifier** module provides a centralized alerting solution for AWS environments by forwarding operational and infrastructure events directly to Microsoft Teams through AWS Chatbot (Amazon Q Developer).

This module creates and configures the required AWS resources to collect alerts from multiple sources and deliver them to a Microsoft Teams channel:

- **CloudWatch Alarms** publish notifications to an SNS topic.
- **EventBridge Rules** publish operational events to the same SNS topic.
- **AWS Chatbot Microsoft Teams Channel Configuration** subscribes to the SNS topic.
- Alerts are delivered directly into a designated Microsoft Teams channel.

This enables engineering and operations teams to receive real-time notifications for infrastructure issues, operational events, and application health alerts without leaving Microsoft Teams.

---

## Architecture

```text
+--------------------+
| CloudWatch Alarms  |
+--------------------+
          |
          v
+--------------------+
|      SNS Topic     |
|  alert_notifier    |
+--------------------+
          ^
          |
+--------------------+
|   EventBridge      |
|      Rules         |
+--------------------+
          |
          v
+----------------------------------+
| AWS Chatbot Teams Configuration  |
+----------------------------------+
          |
          v
+--------------------+
| Microsoft Teams    |
| Alert Channel      |
+--------------------+
```

---

## Features

- Microsoft Teams integration using AWS Chatbot (Amazon Q Developer)
- Centralized SNS topic for alert aggregation
- CloudWatch alarm notifications
- EventBridge event notifications
- Custom EventBridge rule support
- KMS encryption support
- Dead Letter Queue (DLQ) support
- Automated CloudWatch alarm management through Lambda
- Read-only permissions for AWS Chatbot access
- Infrastructure-as-Code implementation using Terraform

---

## Use Cases

This module can be used to notify Teams channels about:

### CloudWatch Alarms

- EC2 CPU utilization
- EC2 memory utilization (CloudWatch Agent)
- EC2 root filesystem disk utilization (`/`)
- EC2 system filesystem disk utilization (`/sys/fs/cgroup`)
- EC2 device filesystem disk utilization (`/dev`)
- RDS free storage space
- RDS swap usage
- RDS freeable memory
- ECS task count

### EventBridge Events

## Default EventBridge Rules

The module automatically creates EventBridge rules for:

- CloudWatch alarm state changes
- AWS Health operational issues
- AWS Config non-compliance events
- AWS Backup failures
- AWS Systems Manager (SSM) Patch Manager failures
- RDS health and maintenance events
- CloudWatch alarm deletion events
---

## How It Works

### CloudWatch Alarm Flow

1. A CloudWatch alarm changes state.
2. The alarm publishes a notification to the SNS topic.
3. AWS Chatbot is subscribed to the SNS topic.
4. AWS Chatbot forwards the notification to Microsoft Teams.
5. Team members receive the alert in the configured Teams channel.

### EventBridge Flow

1. An AWS event matches an EventBridge rule.
2. EventBridge forwards the event to the SNS topic.
3. AWS Chatbot receives the SNS notification.
4. AWS Chatbot forwards the event to Microsoft Teams.
5. Team members receive the event notification in the configured Teams channel.

---

## Resources Created

### Messaging

- SNS Topic for alert aggregation

### Microsoft Teams Integration

- AWS Chatbot Teams Channel Configuration
- IAM Role for AWS Chatbot

### Event Processing

- EventBridge Rules
- EventBridge Targets

### Automation

- Lambda function for CloudWatch alarm creation and management
- Lambda IAM role and permissions

### Security

- KMS grants
- SNS topic policies
- IAM policies and attachments

---

## Microsoft Teams Setup Guide for AWS Chatbot (Amazon Q Developer) Integration

Before deploying this module, a Microsoft Teams Team and channel must exist and the Amazon Q Developer application must be installed in Microsoft Teams.

### Step 1 - Create a Team and Channel

1. Open Microsoft Teams.
2. On the left panel, click **Teams and Channels**.
3. Click **See all your teams**.
4. Click **Create a team**.
5. Enter a Team name and channel name.
6. Click **Create**.

Your Team and channel are now created.

---

### Step 2 - Add Amazon Q Developer App in Teams

1. Click the **+ (Apps)** button on the left panel.
2. Search for **Amazon Q**.
3. Select **Amazon Q Developer** and click **Add**.
4. Select the channel created in the previous step.
5. Click **Go**.

You will see Amazon Q messages appear in the channel, indicating that the setup completed successfully.

---

### Step 3 - Get the Channel Link

The channel link is required for AWS Chatbot configuration.

1. Open the Teams channel that will receive AWS alerts.
2. Click the **⋯ (More options)** menu.
3. Click **Copy link**.

Example:

```text
https://teams.cloud.microsoft/l/channel/19%3A_HgthlQuhFhjLA_YGkliM3Qewhf-98GAWRoQ1fVVKSwM1%40thread.tacv2/Observability?groupId=1yg9904-6bd2-4c3b-bbef-4aeeb0f9dd70&tenantId=47125f55-4e4c-4bc9-8fe9-ghfuui4b7d1
```

Provide this link to the AWS administrator responsible for configuring the AWS Chatbot Microsoft Teams integration.
Most of the times this link doesn't work so change teams.cloud.microsoft to teams.microsoft.com and try.

---

## Usage

```hcl
module "teams_alert_notifier" {
  source = "github.com/TechNative-B-V/terraform-aws-module-alert-notifier"

  team_id          = "xxxxxxxx"
  teams_channel_id = "xxxxxxxx"
  teams_tenant_id  = "xxxxxxxx"

  kms_key_arn = aws_kms_key.notifications.arn
  sqs_dlq_arn = aws_sqs_queue.alerts_dlq.arn

  eventbridge_rules = {
    ec2_termination = {
      description = "Notify when EC2 instances are terminated"
      state       = "ENABLED"

      event_pattern = jsonencode({
        source      = ["aws.ec2"]
        detail-type = ["EC2 Instance State-change Notification"]
      })
    }
  }
}
```

---

## Prerequisites

Before using this module:

### Microsoft Teams

1. Create or identify the Teams channel that will receive alerts.
2. Install the Amazon Q Developer application in Microsoft Teams.
3. Provide the Teams channel link to the AWS administrator.
4. Obtain:
   - Team ID
   - Teams Channel ID
   - Teams Tenant ID

### AWS Permissions

The deploying identity must have permissions to create:

- SNS Topics
- IAM Roles
- AWS Chatbot Configurations
- EventBridge Rules
- Lambda Functions
- KMS Grants

---

## Example Alert

A CloudWatch alarm notification received in Microsoft Teams may look similar to:

```text
ALARM: HighCPUUtilization

Region: eu-west-1
Resource: i-0123456789abcdef
Threshold: CPUUtilization > 80%
Current Value: 92%

State: ALARM
```

---

## Security

This module follows AWS security best practices:

- SNS topic access is restricted through IAM policies.
- KMS encryption is supported.
- AWS Chatbot operates using a dedicated IAM role.
- Chatbot permissions are limited using:
  - CloudWatchReadOnlyAccess
  - ReadOnlyAccess guardrails

---


## Outputs

### SNS Topic ARN

```hcl
output "sns_topic_arn"
```

ARN of the SNS topic used for alert distribution.

---

## Authors

TechNative B.V.
<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | > 4.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_role_lambda_cw_alarm_creator"></a> [iam\_role\_lambda\_cw\_alarm\_creator](#module\_iam\_role\_lambda\_cw\_alarm\_creator) | github.com/wearetechnative/terraform-aws-iam-role | 9229bbd0280807cbc49f194ff6d2741265dc108a |
| <a name="module_lambda_cw_alarm_creator"></a> [lambda\_cw\_alarm\_creator](#module\_lambda\_cw\_alarm\_creator) | github.com/wearetechnative/terraform-aws-lambda.git | 5ba61dffd4fd93e7ec4d4883f75acab7d56847bd |

## Resources

| Name | Type |
|------|------|
| [aws_chatbot_slack_channel_configuration.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/chatbot_slack_channel_configuration) | resource |
| [aws_chatbot_teams_channel_configuration.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/chatbot_teams_channel_configuration) | resource |
| [aws_cloudwatch_event_rule.cloudwatch_instance_termininate_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.refresh_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.instance_terminate_lambda_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.lambda_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.chatbot_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_readonly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_grant.give_lambda_role_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_grant) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_eventbridge_instance_terminate_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.alert_notifier](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudwatch_alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eventbus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_cw_alarm_creator_dlq_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_ec2_read_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_ecs_read_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_elasticache_read_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_rds_read_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eventbridge_rules"></a> [eventbridge\_rules](#input\_eventbridge\_rules) | EventBridge rule settings. | <pre>map(object({<br>    description : string<br>    state : string<br>    event_pattern : string<br>    })<br>  )</pre> | `{}` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key. | `string` | n/a | yes |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda function timeout. | `number` | `180` | no |
| <a name="input_notification_type"></a> [notification\_type](#input\_notification\_type) | Select an endpoint for the alerts(slack or teams) | `string` | n/a | yes |
| <a name="input_slack_channel_id"></a> [slack\_channel\_id](#input\_slack\_channel\_id) | channel id of your slack channel | `string` | `null` | no |
| <a name="input_slack_team_id"></a> [slack\_team\_id](#input\_slack\_team\_id) | ID of the Slack workspace authorized with AWS Chatbot | `string` | `null` | no |
| <a name="input_source_directory_location"></a> [source\_directory\_location](#input\_source\_directory\_location) | Source Directory location for the custom alarm creator actions.py. | `string` | `null` | no |
| <a name="input_sqs_dlq_arn"></a> [sqs\_dlq\_arn](#input\_sqs\_dlq\_arn) | ARN of the Dead Letter Queue. | `string` | n/a | yes |
| <a name="input_team_id"></a> [team\_id](#input\_team\_id) | Teams Id | `string` | `null` | no |
| <a name="input_teams_channel_id"></a> [teams\_channel\_id](#input\_teams\_channel\_id) | Teams Channel Id | `string` | `null` | no |
| <a name="input_teams_tenant_id"></a> [teams\_tenant\_id](#input\_teams\_tenant\_id) | Teams Tenant Id | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | n/a |
<!-- END_TF_DOCS -->