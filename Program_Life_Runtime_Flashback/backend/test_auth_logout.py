
from unittest.mock import patch

from fastapi.testclient import TestClient
from botocore.exceptions import ClientError

from main import app

client = TestClient(app)

TEST_REFRESH_TOKEN = "test-refresh-token"


@patch("main.revoke_session", return_value=True)
@patch(
    "main.hash_refresh_token",
    return_value="test-token-hash",
)
@patch(
    "main.verify_refresh_token",
    return_value=("test-player", "test-session"),
)
def test_logout_success(mock_verify, mock_hash, mock_revoke):
    response = client.post(
        "/auth/logout",
        json={"refresh_token": TEST_REFRESH_TOKEN},
    )

    assert response.status_code == 200
    assert response.json()["success"] is True

    mock_revoke.assert_called_once_with(
        player_id="test-player",
        session_id="test-session",
        refresh_token_hash="test-token-hash",
    )

    print("[PASS] 有效 Refresh Token 登出成功")


@patch(
    "main.verify_refresh_token",
    side_effect=ValueError("Invalid token"),
)
def test_logout_invalid_token(mock_verify):
    response = client.post(
        "/auth/logout",
        json={"refresh_token": TEST_REFRESH_TOKEN},
    )

    assert response.status_code == 401

    print("[PASS] 無效 Refresh Token 正確拒絕")


@patch("main.revoke_session", return_value=False)
@patch(
    "main.hash_refresh_token",
    return_value="old-token-hash",
)
@patch(
    "main.verify_refresh_token",
    return_value=("test-player", "test-session"),
)
def test_logout_old_token(mock_verify, mock_hash, mock_revoke):
    response = client.post(
        "/auth/logout",
        json={"refresh_token": TEST_REFRESH_TOKEN},
    )

    assert response.status_code == 401

    print("[PASS] 已輪替或失效的 Token 正確拒絕")


@patch(
    "main.revoke_session",
    side_effect=ClientError(
        {
            "Error": {
                "Code": "AccessDeniedException",
                "Message": "Access denied",
            }
        },
        "UpdateItem",
    ),
)
@patch(
    "main.hash_refresh_token",
    return_value="test-token-hash",
)
@patch(
    "main.verify_refresh_token",
    return_value=("test-player", "test-session"),
)
def test_logout_database_error(mock_verify, mock_hash, mock_revoke):
    response = client.post(
        "/auth/logout",
        json={"refresh_token": TEST_REFRESH_TOKEN},
    )

    assert response.status_code == 503

    print("[PASS] DynamoDB 異常正確回傳 503")


if __name__ == "__main__":
    test_logout_success()
    test_logout_invalid_token()
    test_logout_old_token()
    test_logout_database_error()

    print("\n四項 Logout API 測試全部通過")
