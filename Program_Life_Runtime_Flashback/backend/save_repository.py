
import json
import os
from datetime import datetime, timezone

import boto3


PLAYERS_TABLE = os.getenv("PLAYERS_TABLE", "Players")
AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")

_dynamodb = boto3.resource(
    "dynamodb",
    region_name=AWS_REGION,
)

_table = _dynamodb.Table(PLAYERS_TABLE)

# 限制單筆存檔大小，避免超過 DynamoDB 400 KB 限制。
MAX_SAVE_BYTES = 280 * 1024


def save_player_game(
    player_id: str,
    save_data: dict,
) -> str:
    """儲存玩家的雲端遊戲進度。"""

    save_json = json.dumps(
        save_data,
        ensure_ascii=False,
        separators=(",", ":"),
        allow_nan=False,
    )

    if len(save_json.encode("utf-8")) > MAX_SAVE_BYTES:
        raise ValueError("遊戲存檔超過大小限制")

    updated_at = datetime.now(
        timezone.utc
    ).isoformat()

    _table.put_item(
        Item={
            "PK": f"PLAYER#{player_id}",
            "SK": "SAVE#MAIN",
            "saveJson": save_json,
            "schemaVersion": 2,
            "updatedAt": updated_at,
        }
    )

    return updated_at


def load_player_game(
    player_id: str,
) -> dict | None:
    """讀取玩家的雲端遊戲進度。"""

    response = _table.get_item(
        Key={
            "PK": f"PLAYER#{player_id}",
            "SK": "SAVE#MAIN",
        },
        ConsistentRead=True,
    )

    item = response.get("Item")

    if item is None:
        return None

    return {
        "save": json.loads(item["saveJson"]),
        "updated_at": item["updatedAt"],
    }
