#!/usr/bin/env python3
import jwt
import time
import sys
import os

KEY_ID = "XKU8846XS8"
ISSUER_ID = "e0939399-8b49-4818-b044-e769c1fbff8e"
KEY_PATH = os.path.expanduser("~/.appstoreconnect/AuthKey_XKU8846XS8.p8")

with open(KEY_PATH, "r") as f:
    private_key = f.read()

now = int(time.time())
payload = {
    "iss": ISSUER_ID,
    "iat": now,
    "exp": now + 1200,
    "aud": "appstoreconnect-v1"
}

token = jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})
print(token)
