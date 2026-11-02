"""Offline contract tests. No real Google, Gemini, SSM or AWS calls."""
import io
import json
import os
import unittest
from unittest.mock import patch, Mock
from urllib.error import HTTPError, URLError

os.environ.setdefault('GOOGLE_OAUTH_CLIENT_ID', 'offline-test-client')

from fastapi.testclient import TestClient
import main
import ai_service


class AITests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, {
            'AI_REQUIRE_LOGIN': 'false', 'AI_RATE_LIMIT_ENABLED': 'false',
            'AI_DAILY_QUOTA_ENABLED': 'false',
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        self.client = TestClient(main.app)

    def test_anonymous_and_logged_in(self):
        with patch('main.generate', return_value='提示'), patch('main.verify_google_token') as verify:
            for headers in ({}, {'Authorization': 'Bearer sample'}):
                r = self.client.post('/ai/generate', json={'prompt': '問題'}, headers=headers)
                self.assertEqual(r.json(), {'text': '提示'})
            verify.assert_not_called()

    def test_login_switch(self):
        with patch.dict(os.environ, {'AI_REQUIRE_LOGIN': 'true'}), patch('main.generate', return_value='提示'), patch('main.verify_google_token', return_value={'sub': 'player'}) as verify:
            self.assertEqual(self.client.post('/ai/generate', json={'prompt': 'p'}).status_code, 401)
            self.assertEqual(self.client.post('/ai/generate', json={'prompt': 'p'}, headers={'Authorization': 'Bearer valid'}).status_code, 200)
            verify.assert_called_once_with('valid')

    def test_auth_still_verifies(self):
        from fastapi import HTTPException
        with patch('main.verify_google_token', side_effect=HTTPException(401, 'invalid')):
            self.assertEqual(self.client.post('/auth/google', json={'id_token': 'bad'}).status_code, 401)
        with patch('main.verify_google_token', return_value={'sub': '123', 'name': 'player'}):
            self.assertEqual(self.client.post('/auth/google', json={'id_token': 'valid'}).json()['player']['id'], '123')

    def test_reserved_switches(self):
        for key in ('AI_RATE_LIMIT_ENABLED', 'AI_DAILY_QUOTA_ENABLED'):
            with patch.dict(os.environ, {key: 'true'}), patch('main.generate') as generate:
                self.assertEqual(self.client.post('/ai/generate', json={'prompt': 'p'}).status_code, 503)
                generate.assert_not_called()

    def test_prompt_bounds(self):
        for prompt in ('', '  ', 'p' * 4001):
            self.assertEqual(self.client.post('/ai/generate', json={'prompt': prompt}).status_code, 422)

    def test_lambda_uses_ssm(self):
        ai_service.get_api_key.cache_clear()
        self.addCleanup(ai_service.get_api_key.cache_clear)
        ssm = Mock()
        ssm.get_parameter.return_value = {'Parameter': {'Value': 'test-secret'}}
        with patch.dict(os.environ, {'AWS_LAMBDA_FUNCTION_NAME': 'test', 'API_KEY': 'ignored'}), patch('ai_service.boto3.client', return_value=ssm):
            self.assertEqual(ai_service.get_api_key(), 'test-secret')
            ssm.get_parameter.assert_called_once_with(Name='/godot-backend/API_KEY', WithDecryption=True)

    def test_generation_and_output_limit(self):
        raw = json.dumps({'candidates': [{'content': {'parts': [{'text': 'a' * 4500}]}}]}).encode()
        response = Mock()
        response.__enter__ = Mock(return_value=io.BytesIO(raw))
        response.__exit__ = Mock(return_value=False)
        with patch('ai_service.get_api_key', return_value='test-secret'), patch('ai_service.urlrequest.urlopen', return_value=response) as call:
            self.assertEqual(len(ai_service.generate('p')), 4000)
            req = call.call_args.args[0]
            self.assertEqual(json.loads(req.data)['generationConfig']['maxOutputTokens'], 512)
            self.assertEqual(call.call_args.kwargs['timeout'], 8)

    def test_upstream_errors_no_secret(self):
        for error, status in ((HTTPError('url', 429, 'test-secret', {}, None), 429), (URLError('test-secret'), 503), (TimeoutError('test-secret'), 503)):
            with patch('ai_service.get_api_key', return_value='test-secret'), patch('ai_service.urlrequest.urlopen', side_effect=error) as call:
                r = self.client.post('/ai/generate', json={'prompt': 'p'})
                self.assertEqual(r.status_code, status)
                self.assertNotIn('test-secret', r.text)
                self.assertEqual(call.call_count, 1)

    def test_concurrency_guard(self):
        ai_service._slots.acquire()
        try:
            with patch('ai_service.get_api_key') as key:
                self.assertEqual(self.client.post('/ai/generate', json={'prompt': 'p'}).status_code, 503)
                key.assert_not_called()
        finally:
            ai_service._slots.release()

    def test_invalid_and_empty_upstream(self):
        for raw in (b'not-json', b'{}', b'x' * 65537):
            response = Mock()
            response.__enter__ = Mock(return_value=io.BytesIO(raw))
            response.__exit__ = Mock(return_value=False)
            with patch('ai_service.get_api_key', return_value='test-secret'), patch('ai_service.urlrequest.urlopen', return_value=response):
                self.assertEqual(self.client.post('/ai/generate', json={'prompt': 'p'}).status_code, 502)


if __name__ == '__main__':
    unittest.main()
