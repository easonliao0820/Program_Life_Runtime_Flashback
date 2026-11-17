
from unittest.mock import MagicMock, patch

from botocore.exceptions import ClientError

import session_repository


def test_revoke_success():
    mock_table = MagicMock()

    with patch.object(
        session_repository,
        "_sessions_table",
        mock_table,
    ):
        result = session_repository.revoke_session(
            "test-player",
            "test-session",
            "test-token-hash",
        )

    assert result is True
    mock_table.update_item.assert_called_once()

    kwargs = mock_table.update_item.call_args.kwargs

    assert kwargs["Key"] == {
        "PK": "PLAYER#test-player",
        "SK": "SESSION#test-session",
    }

    assert kwargs["ExpressionAttributeValues"][":token_hash"] == (
        "test-token-hash"
    )
    assert kwargs["ExpressionAttributeValues"][":true"] is True

    print("[PASS] Session 撤銷成功")


def test_revoke_condition_failed():
    mock_table = MagicMock()

    mock_table.update_item.side_effect = ClientError(
        {
            "Error": {
                "Code": "ConditionalCheckFailedException",
                "Message": "Condition failed",
            }
        },
        "UpdateItem",
    )

    with patch.object(
        session_repository,
        "_sessions_table",
        mock_table,
    ):
        result = session_repository.revoke_session(
            "test-player",
            "test-session",
            "invalid-token-hash",
        )

    assert result is False

    print("[PASS] 條件不符合時正確拒絕撤銷")


def test_revoke_database_error():
    mock_table = MagicMock()

    mock_table.update_item.side_effect = ClientError(
        {
            "Error": {
                "Code": "AccessDeniedException",
                "Message": "Access denied",
            }
        },
        "UpdateItem",
    )

    with patch.object(
        session_repository,
        "_sessions_table",
        mock_table,
    ):
        try:
            session_repository.revoke_session(
                "test-player",
                "test-session",
                "test-token-hash",
            )
        except ClientError as exc:
            assert exc.response["Error"]["Code"] == (
                "AccessDeniedException"
            )
        else:
            raise AssertionError(
                "資料庫錯誤應向上拋出例外"
            )

    print("[PASS] DynamoDB 錯誤正確向上拋出")


if __name__ == "__main__":
    test_revoke_success()
    test_revoke_condition_failed()
    test_revoke_database_error()

    print("\n三項 revoke_session 測試全部通過")
