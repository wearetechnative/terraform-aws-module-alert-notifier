import json
import os
import boto3
from datetime import datetime, timezone

sns = boto3.client("sns")

DESTINATION_TOPIC_ARN = os.environ["DESTINATION_TOPIC_ARN"]


def lambda_handler(event, context):
    for record in event.get("Records", []):
        source_topic_arn = record.get("Sns", {}).get("TopicArn")
        raw_message = record.get("Sns", {}).get("Message", "")

        parsed_message = parse_json_or_text(raw_message)

        if is_chatbot_custom_message(parsed_message):
            chatbot_message = parsed_message

        else:
            normalized = normalize_event(parsed_message, source_topic_arn)
            chatbot_message = render_chatbot_message(normalized)

        sns.publish(
            TopicArn=DESTINATION_TOPIC_ARN,
            Message=json.dumps(chatbot_message, default=str),
        )

    return {"statusCode": 200}


def parse_json_or_text(value):
    if not isinstance(value, str):
        return value

    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return {
            "rawText": value
        }


def is_chatbot_custom_message(message):
    return (
        isinstance(message, dict)
        and message.get("version") == "1.0"
        and message.get("source") == "custom"
        and isinstance(message.get("content"), dict)
        and "description" in message["content"]
    )


def normalize_event(message, source_topic_arn=None):
    if is_cloudwatch_alarm(message):
        return normalize_cloudwatch_alarm(message)

    if is_eventbridge_event(message):
        return normalize_eventbridge_event(message)

    return normalize_generic_message(message, source_topic_arn)


def is_cloudwatch_alarm(message):
    return (
        isinstance(message, dict)
        and "AlarmName" in message
        and "NewStateValue" in message
        and "Trigger" in message
    )


def is_eventbridge_event(message):
    return (
        isinstance(message, dict)
        and "detail-type" in message
        and "source" in message
        and "detail" in message
    )


def normalize_cloudwatch_alarm(alarm):
    trigger = alarm.get("Trigger", {})
    dimensions = trigger.get("Dimensions", [])

    resource = first_dimension_value(dimensions) or first_resource(alarm)

    alarm_name = alarm.get("AlarmName", "Unknown CloudWatch alarm")
    state = alarm.get("NewStateValue", "UNKNOWN")
    old_state = alarm.get("OldStateValue", "UNKNOWN")
    reason = alarm.get("NewStateReason", "No reason provided")

    severity = alarm.get("AlarmDescription") or infer_severity_from_state(state)

    return {
        "severity": severity,
        "title": f"CloudWatch alarm: {alarm_name}",
        "state": state,
        "old_state": old_state,
        "service": "CloudWatch",
        "account": alarm.get("AWSAccountId", "Unknown account"),
        "region": alarm.get("Region", "Unknown region"),
        "resource": resource,
        "reason": reason,
        "event_type": "CloudWatchAlarm",
        "summary": f"{alarm_name} is {state}",
        "related_resources": compact_list([
            alarm.get("AlarmArn"),
            resource,
        ]),
        "next_steps": [
            "Check the CloudWatch alarm details",
            "Check the affected resource metrics",
            "Verify whether the threshold and missing data settings are correct",
        ],
        "raw": alarm,
    }


def normalize_eventbridge_event(event):
    detail = event.get("detail", {})

    source = event.get("source", "Unknown source")
    detail_type = event.get("detail-type", "Unknown event")
    region = event.get("region", "Unknown region")
    account = event.get("account", "Unknown account")
    resources = event.get("resources", [])

    resource = first_resource(event) or detail.get("resource") or detail.get("instance-id")

    reason = (
        detail.get("reason")
        or detail.get("message")
        or detail.get("state")
        or json.dumps(detail, indent=2, default=str)[:1500]
    )

    return {
        "severity": infer_severity_from_eventbridge(source, detail_type, detail),
        "title": f"{detail_type}",
        "state": detail.get("state", "EVENT"),
        "old_state": None,
        "service": source,
        "account": account,
        "region": region,
        "resource": resource,
        "reason": reason,
        "event_type": detail_type,
        "summary": f"{detail_type} from {source}",
        "related_resources": compact_list(resources),
        "next_steps": [
            "Review the EventBridge event details",
            "Check the affected AWS resource",
            "Investigate recent changes around the event time",
        ],
        "raw": event,
    }


def normalize_generic_message(message, source_topic_arn=None):
    if isinstance(message, dict):
        title = (
            message.get("title")
            or message.get("subject")
            or message.get("Subject")
            or message.get("name")
            or "AWS notification"
        )

        reason = (
            message.get("message")
            or message.get("Message")
            or message.get("description")
            or json.dumps(message, indent=2, default=str)[:3000]
        )
    else:
        title = "AWS notification"
        reason = str(message)

    return {
        "severity": "INFO",
        "title": title,
        "state": "EVENT",
        "old_state": None,
        "service": "SNS",
        "account": "Unknown account",
        "region": "Unknown region",
        "resource": source_topic_arn,
        "reason": reason,
        "event_type": "GenericNotification",
        "summary": title,
        "related_resources": compact_list([source_topic_arn]),
        "next_steps": [
            "Review the notification payload",
            "Check the source system that published this message",
        ],
        "raw": message,
    }


def render_chatbot_message(normalized):
    emoji = severity_emoji(normalized["severity"], normalized["state"])

    description_lines = [
        f"**Severity:** {normalized['severity']}",
        f"**State:** {format_state_transition(normalized)}",
        f"**Service:** {normalized['service']}",
        f"**Account:** {normalized['account']}",
        f"**Region:** {normalized['region']}",
    ]

    if normalized.get("resource"):
        description_lines.append(f"**Resource:** `{normalized['resource']}`")

    description_lines.extend([
        "",
        f"**Reason:** {normalized['reason']}",
    ])

    return {
        "version": "1.0",
        "source": "custom",
        "content": {
            "textType": "client-markdown",
            "title": f"{emoji} {normalized['title']}",
            "description": "\n".join(description_lines)[:8000],
            "nextSteps": normalized.get("next_steps", [])[:10],
        },
        "metadata": {
            "threadId": make_thread_id(normalized),
            "summary": normalized.get("summary", normalized["title"])[:250],
            "eventType": normalized.get("event_type", "AwsNotification"),
            "relatedResources": normalized.get("related_resources", [])[:10],
            "additionalContext": {
                "generatedAt": datetime.now(timezone.utc).isoformat(),
                "service": normalized.get("service"),
                "severity": normalized.get("severity"),
            },
        },
    }


def format_state_transition(normalized):
    old_state = normalized.get("old_state")
    state = normalized.get("state")

    if old_state:
        return f"{old_state} → {state}"

    return state


def make_thread_id(normalized):
    resource = normalized.get("resource")
    event_type = normalized.get("event_type")
    title = normalized.get("title")

    base = resource or title or event_type or "aws-notification"

    return str(base).replace(" ", "-")[:250]


def first_dimension_value(dimensions):
    if not dimensions:
        return None

    preferred_names = ["InstanceId", "DBInstanceIdentifier", "LoadBalancer", "FunctionName"]

    for preferred in preferred_names:
        for dimension in dimensions:
            if dimension.get("name") == preferred:
                return dimension.get("value")

    return dimensions[0].get("value")


def first_resource(event):
    resources = event.get("resources") or event.get("Resources") or []

    if isinstance(resources, list) and resources:
        return resources[0]

    return None


def compact_list(values):
    result = []

    for value in values:
        if value and value not in result:
            result.append(value)

    return result


def infer_severity_from_state(state):
    if state == "ALARM":
        return "P1"

    if state == "INSUFFICIENT_DATA":
        return "WARNING"

    if state == "OK":
        return "RECOVERY"

    return "INFO"


def infer_severity_from_eventbridge(source, detail_type, detail):
    text = f"{source} {detail_type} {json.dumps(detail, default=str)}".lower()

    if any(word in text for word in ["failed", "failure", "error", "terminated", "stopped"]):
        return "WARNING"

    if any(word in text for word in ["critical", "alarm", "breach"]):
        return "P1"

    return "INFO"


def severity_emoji(severity, state):
    if state == "OK" or severity == "RECOVERY":
        return ":white_check_mark:"

    if severity in ["P1", "CRITICAL"]:
        return ":rotating_light:"

    if severity in ["P2", "WARNING"]:
        return ":warning:"

    return ":information_source:"