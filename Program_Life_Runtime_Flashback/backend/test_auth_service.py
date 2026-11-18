
from unittest.mock import patch

from auth_service import create_access_token, verify_access_token


TEST_SECRET = "local-test-secret-for-jwt-at-least-32-characters"
TEST_PLAYER_ID = "test-player-123"


def main():
    # 測試時使用假的密鑰，不會連線 AWS SSM。
    with patch("auth_service._get_jwt_secret", return_value=TEST_SECRET):

        # 測試 1：簽發 Access Token
        token = create_access_token(TEST_PLAYER_ID)
        print("測試 1 - JWT 簽發成功")

        # 測試 2：驗證 Access Token
        player_id = verify_access_token(token)
        assert player_id == TEST_PLAYER_ID
        print("測試 2 - JWT 驗證成功")

        # 測試 3：拒絕無效 Token
        try:
            verify_access_token("invalid-token")
        except ValueError:
            print("測試 3 - 無效 Token 已正確拒絕")
        else:
            raise AssertionError("無效 Token 未被拒絕")

    print("全部 JWT 測試通過！")


if __name__ == "__main__":
    main()
