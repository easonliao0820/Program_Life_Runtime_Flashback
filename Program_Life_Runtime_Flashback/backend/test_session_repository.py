
from datetime import datetime, timezone
from unittest.mock import patch

from botocore.exceptions import ClientError

from session_repository import rotate_refresh_token


PLAYER_ID = "test-player-001"
SESSION_ID = "test-session-001"


def make_client_error(code):
    return ClientError(
        {
            "Error": {
                "Code": code,
                "Message": "模擬 DynamoDB 錯誤",
            }
        },
        "UpdateItem",
    )


def test_rotation_success():
    with patch("session_repository._sessions_table") as mock_table:
        result = rotate_refresh_token(
            player_id=PLAYER_ID,
            session_id=SESSION_ID,
            old_token_hash="old-hash",
            new_token_hash="new-hash",
            new_expires_at=2000000000,
        )

        assert result is True
        mock_table.update_item.assert_called_once()

        arguments = mock_table.update_item.call_args.kwargs

        assert arguments["Key"] == {
            "PK": f"PLAYER#{PLAYER_ID}",
            "SK": f"SESSION#{SESSION_ID}",
        }

        values = arguments["ExpressionAttributeValues"]

        assert values[":old_hash"] == "old-hash"
        assert values[":new_hash"] == "new-hash"
        assert values[":false"] is False

        assert values[":current_time"] <= int(
            datetime.now(timezone.utc).timestamp()
        )

        condition = arguments["ConditionExpression"]

        assert "refreshTokenHash = :old_hash" in condition
        assert "revoked = :false" in condition
        assert "expiresAt > :current_time" in condition

        print("測試 1：Token 輪替成功")


def test_rotation_rejected():
    with patch("session_repository._sessions_table") as mock_table:
        mock_table.update_item.side_effect = make_client_error(
            "ConditionalCheckFailedException"
        )

        result = rotate_refresh_token(
            player_id=PLAYER_ID,
            session_id=SESSION_ID,
            old_token_hash="old-hash",
            new_token_hash="new-hash",
            new_expires_at=2000000000,
        )

        assert result is False

        print("測試 2：條件不符合時正確拒絕輪替")


def test_database_error():
    with patch("session_repository._sessions_table") as mock_table:
        mock_table.update_item.side_effect = make_client_error(
            "AccessDeniedException"
        )

        try:
            rotate_refresh_token(
                player_id=PLAYER_ID,
                session_id=SESSION_ID,
                old_token_hash="old-hash",
                new_token_hash="new-hash",
                new_expires_at=2000000000,
            )

        except ClientError as exc:
            assert exc.response["Error"]["Code"] == (
                "AccessDeniedException"
            )
            print("測試 3：資料庫異常正確向上傳遞")

        else:
            raise AssertionError("資料庫異常不應被忽略")


if __name__ == "__main__":
    test_rotation_success()
    test_rotation_rejected()
    test_database_error()

    print("第二階段測試全部通過")
