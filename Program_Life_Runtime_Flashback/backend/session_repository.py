
import os
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError


PLAYERS_TABLE = os.getenv("PLAYERS_TABLE", "Players")
AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")

_dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
_sessions_table = _dynamodb.Table(PLAYERS_TABLE)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def create_session(
    player_id: str,
    session_id: str,
    refresh_token_hash: str,
    expires_at: int,
) -> None:
    """建立新的玩家登入工作階段。"""

    _sessions_table.put_item(
        Item={
            "PK": f"PLAYER#{player_id}",
            "SK": f"SESSION#{session_id}",
            "refreshTokenHash": refresh_token_hash,
            "expiresAt": expires_at,
            "createdAt": _now(),
            "updatedAt": _now(),
            "revoked": False,
        },
        ConditionExpression=(
            "attribute_not_exists(PK) "
            "AND attribute_not_exists(SK)"
        ),
    )


def get_session(player_id: str, session_id: str) -> dict | None:
    """查詢玩家的登入工作階段。"""

    response = _sessions_table.get_item(
        Key={
            "PK": f"PLAYER#{player_id}",
            "SK": f"SESSION#{session_id}",
        },
        ConsistentRead=True,
    )

    return response.get("Item")


def rotate_refresh_token(
    player_id: str,
    session_id: str,
    old_token_hash: str,
    new_token_hash: str,
    new_expires_at: int,
) -> bool:
    """只有舊 Token Hash 符合且工作階段有效時才輪替。"""

    try:
        _sessions_table.update_item(
            Key={
                "PK": f"PLAYER#{player_id}",
                "SK": f"SESSION#{session_id}",
            },
            UpdateExpression=(
                "SET refreshTokenHash = :new_hash, "
                "expiresAt = :new_expires_at, "
                "updatedAt = :now"
            ),
            ConditionExpression=(
                "refreshTokenHash = :old_hash "
                "AND revoked = :false "
                "AND expiresAt > :current_time"
            ),
            ExpressionAttributeValues={
                ":old_hash": old_token_hash,
                ":new_hash": new_token_hash,
                ":new_expires_at": new_expires_at,
                ":now": _now(),
                ":false": False,
                ":current_time": int(
                    datetime.now(timezone.utc).timestamp()
                ),
            },
        )

        return True

    except ClientError as exc:
        error_code = exc.response.get("Error", {}).get("Code")

        if error_code == "ConditionalCheckFailedException":
            return False

        raise


def revoke_session(
    player_id: str,
    session_id: str,
    refresh_token_hash: str,
) -> bool:
    """撤銷指定 Session，只有目前有效的 Refresh Token 才能撤銷。"""

    try:
        _sessions_table.update_item(
            Key={
                "PK": f"PLAYER#{player_id}",
                "SK": f"SESSION#{session_id}",
            },
            UpdateExpression=(
                "SET revoked = :true, "
                "updatedAt = :now"
            ),
            ConditionExpression=(
                "refreshTokenHash = :token_hash "
                "AND revoked = :false "
                "AND expiresAt > :current_time"
            ),
            ExpressionAttributeValues={
                ":token_hash": refresh_token_hash,
                ":true": True,
                ":false": False,
                ":now": _now(),
                ":current_time": int(
                    datetime.now(timezone.utc).timestamp()
                ),
            },
        )

        return True

    except ClientError as exc:
        error_code = exc.response.get("Error", {}).get("Code")

        if error_code == "ConditionalCheckFailedException":
            return False

        raise
