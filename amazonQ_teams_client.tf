resource "aws_cloudformation_stack" "configure_client" {
  name = "teams_client"

  parameters = {
    TeamId = var.team_id
    TeamsChannelId = var.teams_channel_id
    TeamsTenantId = var.teams_tenant_id
    AlarmTopicArn  = aws_sns_topic.alert_notifier.arn
  }

  
  template_body = jsonencode({
    Parameters = {
        TeamId = {
            Type = "String"
        }

        TeamsTenantId = {
            Type = "String"
        }

        TeamsChannelId = {
            Type = "String"
        }

        AlarmTopicArn = {
            Type = "String"
        }
    }

    Resources = {
        ChatbotRole = {
        Type = "AWS::IAM::Role"

        Properties = {
            RoleName = "ChatbotTeamsRole"

            AssumeRolePolicyDocument = {
            Version = "2012-10-17"

            Statement = [
                {
                Effect = "Allow"

                Principal = {
                    Service = "chatbot.amazonaws.com"
                }

                Action = "sts:AssumeRole"
                }
            ]
            }

            ManagedPolicyArns = [
            "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
            ]
        }
        }

        TeamsChannel = {
        Type = "AWS::Chatbot::MicrosoftTeamsChannelConfiguration"

        Properties = {
            ConfigurationName = "observability-alerts"

            IamRoleArn = {
            "Fn::GetAtt" = [
                "ChatbotRole",
                "Arn"
            ]
            }

            TeamsTenantId = {
            Ref = "TeamsTenantId"
            }

            TeamId = {
            Ref = "TeamId"
            }

            TeamsChannelId = {
                Ref = "TeamsChannelId"
            }

            TeamsChannelName = "Observability"

            LoggingLevel = "INFO"

            SnsTopicArns = [
               {
                Ref = "AlarmTopicArn"
               } 
                
            ]

            GuardrailPolicies = [
            "arn:aws:iam::aws:policy/ReadOnlyAccess"
            ]

            UserRoleRequired = false
        }
        }
    }
    })
}