# Terraform AWS Teams Chatbot Alert Notifier ![](https://img.shields.io/badge/Terraform-Module-blue?style=plastic) ![](https://img.shields.io/badge/AWS-CloudWatch%20%7C%20SNS%20%7C%20Chatbot-orange?style=plastic)

[![](we-are-technative.png)](https://www.technative.nl)

## Overview

The **terraform-aws-module-alert-notifier** module provides a centralized alerting solution for AWS environments by forwarding operational and infrastructure events directly to Microsoft Teams through AWS Chatbot.

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

- Microsoft Teams integration using AWS Chatbot
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

- High CPU utilization
- High memory utilization
- Low disk space
- Application health issues
- Database performance degradation
- Service availability issues

### EventBridge Events

- EC2 instance termination
- ECS service events
- RDS events
- ElastiCache events
- Custom AWS service events
- Security and operational events

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

- Lambda function for CloudWatch alarm management
- Lambda IAM role and permissions

### Security

- KMS grants
- SNS topic policies
- IAM policies and attachments

---

## Usage

```hcl
module "teams_alert_notifier" {
  source = "github.com/TechNative-B-V/terraform-aws-module-alert-notifier"

  team_id           = "xxxxxxxx"
  teams_channel_id  = "xxxxxxxx"
  teams_tenant_id   = "xxxxxxxx"

  kms_key_arn = aws_kms_key.notifications.arn
  sqs_dlq_arn = aws_sqs_queue.alerts_dlq.arn

  eventbridge_rules = {
    ec2_termination = {
      description   = "Notify when EC2 instances are terminated"
      state         = "ENABLED"
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
2. Configure AWS Chatbot for Microsoft Teams in the AWS Console.
3. Obtain:
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

## Operational Considerations

- AWS Chatbot delivers messages on a best-effort basis.
- EventBridge rules should be scoped carefully to avoid excessive notifications.
- Consider creating dedicated Teams channels for:
  - Critical alerts
  - Infrastructure alerts
  - Security events
  - Application monitoring

---

## Outputs

### SNS Topic ARN

```hcl
output "sns_topic_arn"
```

ARN of the SNS topic used for alert distribution.

---

## Best Practices

When consuming this module:

- Keep alerting channels focused and actionable.
- Route only relevant EventBridge events.
- Use severity-based CloudWatch alarms.
- Review notification noise regularly.
- Integrate with incident management processes.

Terraform module documentation should clearly describe module purpose, inputs, outputs, usage examples, and repository structure to improve maintainability and adoption. :contentReference[oaicite:0]{index=0}

---

## Terraform Documentation

This repository uses:

- terraform-docs
- pre-commit
- tflint

Generate documentation using:

```bash
terraform-docs .
```

Install pre-commit hooks:

```bash
pre-commit install
```

---

## Contributing

1. Create a feature branch.
2. Implement changes.
3. Run formatting and validation checks.
4. Update documentation.
5. Submit a Pull Request.

---

## License

MIT License

---

## Authors

TechNative B.V.