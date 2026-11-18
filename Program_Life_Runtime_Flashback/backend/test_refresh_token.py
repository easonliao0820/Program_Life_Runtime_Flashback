
from unittest.mock import patch

from auth_service import (
    create_refresh_token,
    verify_refresh_token,
    hash_refresh_token,
)


def main():
    player_id = "test-player-001"
    session_id = "test-session-001"

    # 使用測試用密鑰，避免連接 AWS SSM
    with patch(
        "auth_service._get_jwt_secret",
        return_value="local-test-secret-key-at-least-32-characters",
    ):
        refresh_token = create_refresh_token(player_id, session_id)

        verified_player_id, verified_session_id = verify_refresh_token(
            refresh_token
        )

        assert verified_player_id == player_id
        assert verified_session_id == session_id

        token_hash = hash_refresh_token(refresh_token)

        assert len(token_hash) == 64
        assert token_hash == hash_refresh_token(refresh_token)

        print("Refresh Token 產生成功")
        print("Refresh Token 驗證成功")
        print("Player ID 與 Session ID 一致")
        print("SHA-256 雜湊驗證成功")
        print("第一階段測試全部通過")


if __name__ == "__main__":
    main()
