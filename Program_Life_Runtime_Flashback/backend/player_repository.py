
import os
import uuid
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.types import TypeSerializer
from botocore.exceptions import ClientError
from session_repository import (
    create_session,
    get_session,
    rotate_refresh_token,
)


PLAYERS_TABLE = os.getenv("PLAYERS_TABLE", "Players")
AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")

_dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
_players_table = _dynamodb.Table(PLAYERS_TABLE)
_client = boto3.client("dynamodb", region_name=AWS_REGION)
_serializer = TypeSerializer()


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _get_google_identity(google_sub: str):
    """依 Google sub 查詢已綁定的玩家。"""
    response = _players_table.get_item(
        Key={
            "PK": f"GOOGLE#{google_sub}",
            "SK": "IDENTITY",
        },
        ConsistentRead=True,
    )
    return response.get("Item")


def _serialize_item(item: dict) -> dict:
    """將 Python dict 轉成 DynamoDB low-level API 使用的格式。"""
    return {
        key: _serializer.serialize(value)
        for key, value in item.items()
    }


def _update_last_login(player_id: str, info: dict, now: str):
    """更新既有玩家的登入時間與 Google 個人資料。"""
    _players_table.update_item(
        Key={
            "PK": f"PLAYER#{player_id}",
            "SK": "PROFILE",
        },
        UpdateExpression=(
            "SET #lastLoginAt = :now, "
            "#updatedAt = :now, "
            "#email = :email, "
            "#displayName = :displayName, "
            "#avatarUrl = :avatarUrl"
        ),
        ExpressionAttributeNames={
            "#lastLoginAt": "lastLoginAt",
            "#updatedAt": "updatedAt",
            "#email": "email",
            "#displayName": "displayName",
            "#avatarUrl": "avatarUrl",
        },
        ExpressionAttributeValues={
            ":now": now,
            ":email": info.get("email", ""),
            ":displayName": info.get("name", ""),
            ":avatarUrl": info.get("picture", ""),
        },
    )


def get_or_create_google_player(info: dict) -> dict:
    """
    取得或建立 Google 玩家。

    已存在：沿用原本 playerId。
    不存在：產生 UUID，並以 DynamoDB transaction 建立三筆資料。
    """
    google_sub = info.get("sub")

    if not google_sub:
        raise ValueError("Google 身分資料缺少 sub")

    now = _now()

    # 第一次查詢：避免每次登入都建立新玩家。
    identity = _get_google_identity(google_sub)

    if identity:
        player_id = identity["playerId"]
        _update_last_login(player_id, info, now)
        return {
            "id": player_id,
            "name": info.get("name", ""),
            "email": info.get("email", ""),
            "avatar_url": info.get("picture", ""),
        }

    # 尚未綁定：建立新的遊戲玩家 UUID。
    player_id = str(uuid.uuid4())

    profile = {
        "PK": f"PLAYER#{player_id}",
        "SK": "PROFILE",
        "playerId": player_id,
        "accountType": "google",
        "googleSub": google_sub,
        "email": info.get("email", ""),
        "displayName": info.get("name", ""),
        "avatarUrl": info.get("picture", ""),
        "createdAt": now,
        "lastLoginAt": now,
        "updatedAt": now,
        "version": 1,
    }

    progress = {
        "PK": f"PLAYER#{player_id}",
        "SK": "PROGRESS",
        "currentChapter": None,
        "chapterProgress": {},
        "firstTryCompleted": 0,
        "totalLevels": 0,
        "endingType": None,
        "lastPlayedAt": None,
        "updatedAt": now,
        "version": 1,
    }

    google_identity = {
        "PK": f"GOOGLE#{google_sub}",
        "SK": "IDENTITY",
        "playerId": player_id,
        "provider": "google",
        "createdAt": now,
    }

    try:
        # 三筆資料一起成功或一起失敗，避免只建立一部分。
        _client.transact_write_items(
            TransactItems=[
                {
                    "Put": {
                        "TableName": PLAYERS_TABLE,
                        "Item": _serialize_item(profile),
                        "ConditionExpression": (
                            "attribute_not_exists(PK) "
                            "AND attribute_not_exists(SK)"
                        ),
                    }
                },
                {
                    "Put": {
                        "TableName": PLAYERS_TABLE,
                        "Item": _serialize_item(progress),
                        "ConditionExpression": (
                            "attribute_not_exists(PK) "
                            "AND attribute_not_exists(SK)"
                        ),
                    }
                },
                {
                    "Put": {
                        "TableName": PLAYERS_TABLE,
                        "Item": _serialize_item(google_identity),
                        "ConditionExpression": (
                            "attribute_not_exists(PK) "
                            "AND attribute_not_exists(SK)"
                        ),
                    }
                },
            ]
        )

    except ClientError:
        # 可能是另一個同時登入的請求先建立了 Google 身分。
        # 重新查詢；若已存在，就使用先建立的 playerId。
        identity = _get_google_identity(google_sub)

        if identity:
            existing_player_id = identity["playerId"]
            _update_last_login(existing_player_id, info, _now())

            return {
                "id": existing_player_id,
                "name": info.get("name", ""),
                "email": info.get("email", ""),
                "avatar_url": info.get("picture", ""),
            }

        # 若查不到既有身分，代表不是單純的重複登入競爭，
        # 將原始錯誤交給 API 層處理。
        raise

    return {
        "id": player_id,
        "name": info.get("name", ""),
        "email": info.get("email", ""),
        "avatar_url": info.get("picture", ""),
    }

def get_player_by_id(player_id: str) -> dict | None:
    """依玩家 UUID 查詢 DynamoDB 中的玩家基本資料。"""
    if not player_id:
        return None

    response = _players_table.get_item(
        Key={
            "PK": f"PLAYER#{player_id}",
            "SK": "PROFILE",
        },
        ConsistentRead=True,
    )

    item = response.get("Item")

    if not item:
        return None

    return {
        "id": item["playerId"],
        "name": item.get("displayName", ""),
        "email": item.get("email", ""),
        "avatar_url": item.get("avatarUrl", ""),
    }