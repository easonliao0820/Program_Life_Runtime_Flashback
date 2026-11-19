
import os
import boto3

AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")

CHARACTERS_TABLE = os.getenv(
    "CHARACTERS_TABLE", "characters"
)
KNOWLEDGE_TABLE = os.getenv(
    "KNOWLEDGE_TABLE", "knowledge"
)
STORIES_TABLE = os.getenv(
    "STORIES_TABLE", "stories"
)

dynamodb = boto3.resource(
    "dynamodb",
    region_name=AWS_REGION
)

characters_table = dynamodb.Table(CHARACTERS_TABLE)
knowledge_table = dynamodb.Table(KNOWLEDGE_TABLE)
stories_table = dynamodb.Table(STORIES_TABLE)


def get_character(character_id: str) -> dict | None:
    """根據角色 ID 取得角色設定。"""
    response = characters_table.get_item(
        Key={"id": character_id}
    )
    return response.get("Item")


def get_knowledge(knowledge_id: str) -> dict | None:
    """根據知識 ID 取得教學內容。"""
    response = knowledge_table.get_item(
        Key={"id": knowledge_id}
    )
    return response.get("Item")


def get_story(story_id: str) -> dict | None:
    """根據劇情 ID 取得劇情內容。"""
    response = stories_table.get_item(
        Key={"id": story_id}
    )
    return response.get("Item")
