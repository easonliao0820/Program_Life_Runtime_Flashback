
import os
from unittest.mock import patch

# 避免測試時需要真實的 Google Client ID，
# 並禁止 boto3 嘗試查詢 EC2 Metadata。
os.environ["GOOGLE_OAUTH_CLIENT_ID"] = "local-test-client-id"
os.environ["AWS_EC2_METADATA_DISABLED"] = "true"
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"

from fastapi.testclient import TestClient

import main
from auth_service import (
    create_refresh_token,
    hash_refresh_token,
    verify_access_token,
    verify_refresh_token,
)


PLAYER_ID = "test-player-001"
SESSION_ID = "test-session-001"
TEST_SECRET = "local-test-secret-key-at-least-32-characters"

client = TestClient(main.app)


def make_session(token):
    return {
        "PK": f"PLAYER#{PLAYER_ID}",
        "SK": f"SESSION#{SESSION_ID}",
        "refreshTokenHash": hash_refresh_token(token),
        "expiresAt": 2000000000,
        "revoked": False,
    }


def test_refresh_flow():
    # 用記憶體模擬 DynamoDB 的 Session。
    session_store = {}

    def fake_get_session(player_id, session_id):
        if player_id != PLAYER_ID or session_id != SESSION_ID:
            return None

        return session_store.get("session")

    def fake_get_player(player_id):
        if player_id == PLAYER_ID:
            return {"id": PLAYER_ID, "name": "Test Player"}

        return None

    def fake_rotate(
        player_id,
        session_id,
        old_token_hash,
        new_token_hash,
        new_expires_at,
    ):
        session = session_store.get("session")

        if session is None:
            return False

        if session["refreshTokenHash"] != old_token_hash:
            return False

        if session["revoked"]:
            return False

        session["refreshTokenHash"] = new_token_hash
        session["expiresAt"] = new_expires_at

        return True

    with (
        patch("auth_service._get_jwt_secret", return_value=TEST_SECRET),
        patch("main.get_session", side_effect=fake_get_session),
        patch("main.get_player_by_id", side_effect=fake_get_player),
        patch("main.rotate_refresh_token", side_effect=fake_rotate),
    ):
        old_token = create_refresh_token(
            PLAYER_ID,
            SESSION_ID,
        )

        session_store["session"] = make_session(old_token)

        # 測試 1：有效 Token 可以成功輪替。
        response = client.post(
            "/auth/refresh",
            json={"refresh_token": old_token},
        )

        assert response.status_code == 200, response.text

        data = response.json()

        assert data["success"] is True
        assert data["token_type"] == "Bearer"
        assert data["expires_in"] == 900
        assert data["refresh_expires_in"] == 604800

        new_access_token = data["access_token"]
        new_refresh_token = data["refresh_token"]

        assert new_refresh_token != old_token
        assert verify_access_token(new_access_token) == PLAYER_ID

        verified_player, verified_session = verify_refresh_token(
            new_refresh_token
        )

        assert verified_player == PLAYER_ID
        assert verified_session == SESSION_ID

        print("測試 1：有效 Refresh Token 輪替成功（200）")

        # 測試 2：舊 Token 不能再次使用。
        response = client.post(
            "/auth/refresh",
            json={"refresh_token": old_token},
        )

        assert response.status_code == 401, response.text

        print("測試 2：舊 Refresh Token 重複使用遭拒絕（401）")

        # 測試 3：新的 Refresh Token 可以繼續使用。
        response = client.post(
            "/auth/refresh",
            json={"refresh_token": new_refresh_token},
        )

        assert response.status_code == 200, response.text

        print("測試 3：新 Refresh Token 可以繼續輪替（200）")

        # 測試 4：無效 Token 被拒絕。
        response = client.post(
            "/auth/refresh",
            json={"refresh_token": "invalid-token"},
        )

        assert response.status_code == 401, response.text

        print("測試 4：無效 Refresh Token 遭拒絕（401）")

        # 測試 5：Session 不存在。
        session_store.clear()

        response = client.post(
            "/auth/refresh",
            json={"refresh_token": new_refresh_token},
        )

        assert response.status_code == 401, response.text

        print("測試 5：不存在的 Session 遭拒絕（401）")

        # 測試 6：DynamoDB 發生服務異常。
        from botocore.exceptions import ClientError

        error = ClientError(
            {
                "Error": {
                    "Code": "ServiceUnavailable",
                    "Message": "模擬資料庫異常",
                }
            },
            "GetItem",
        )

        with patch("main.get_session", side_effect=error):
            response = client.post(
                "/auth/refresh",
                json={"refresh_token": new_refresh_token},
            )

            assert response.status_code == 503, response.text

        print("測試 6：DynamoDB 異常正確回傳（503）")

    print("第三階段 API 測試全部通過")


if __name__ == "__main__":
    test_refresh_flow()
