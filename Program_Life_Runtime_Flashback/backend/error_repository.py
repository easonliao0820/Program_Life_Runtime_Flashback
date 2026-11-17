
import os
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError


TABLE_NAME = os.getenv("PLAYER_ERRORS_TABLE", "PlayerErrors")
AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")

_table = boto3.resource(
    "dynamodb",
    region_name=AWS_REGION,
).Table(TABLE_NAME)


def save_player_error(player_id: str, data: dict) -> bool:
    """儲存錯誤紀錄；重送相同 event_id 不會產生重複紀錄。"""

    event_id = data["event_id"]

    if (
        len(event_id) != 32
        or any(c not in "0123456789abcdef" for c in event_id)
    ):
        raise ValueError("無效的錯誤事件 ID")

    occurred = datetime.fromisoformat(
        data["occurred_at"].replace("Z", "+00:00")
    )

    if occurred.tzinfo is None:
        raise ValueError("錯誤發生時間必須包含時區")

    occurred_at = occurred.astimezone(timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%S.%fZ"
    )

    received_at = datetime.now(timezone.utc).isoformat()

    item = {
        "PK": f"PLAYER#{player_id}",
        "SK": f"ERROR#{occurred_at}#{event_id}",
        "eventId": event_id,
        "createdAt": occurred_at,
        "receivedAt": received_at,
        "sectionId": data["section_id"],
        "levelId": data["level_id"],
        "attempt": data["attempt"],
        "errorKind": data["error_kind"],
        "errorType": data["error_type"],
        "errorMessage": data["error_message"],
        "line": data["line"],
        "sourceLine": data["source_line"],
        "code": data["code"],
        "backend": data["backend"],
    }

    try:
        _table.put_item(
            Item=item,
            ConditionExpression=(
                "attribute_not_exists(PK) "
                "AND attribute_not_exists(SK)"
            ),
        )
        return True

    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code")

        if code == "ConditionalCheckFailedException":
            return False

        raise
