# Python Secure Coding Reference

> Reference for AI agents implementing secure Python code. Use imperative patterns; prefer allowlisting, least privilege, and defense in depth.

## Table of Contents

- [1. Input Validation and Sanitization](#1-input-validation-and-sanitization)
- [2. Authentication and Authorization Patterns](#2-authentication-and-authorization-patterns)
- [3. Cryptography Best Practices](#3-cryptography-best-practices)
- [4. Secure Data Handling](#4-secure-data-handling)
- [5. File and Path Operations](#5-file-and-path-operations)
- [6. Subprocess and System Interaction](#6-subprocess-and-system-interaction)
- [7. Serialization and Deserialization](#7-serialization-and-deserialization)
- [8. Web Framework Security](#8-web-framework-security)
- [9. Error Handling and Information Disclosure](#9-error-handling-and-information-disclosure)
- [10. Concurrency and Race Conditions](#10-concurrency-and-race-conditions)

---

## 1. Input Validation and Sanitization

Validate all inputs at the boundary using allowlists and strict type coercion. Reject anything not explicitly permitted.

### Allowlisting vs Denylisting

```python
# ❌ Anti-pattern: denylisting dangerous characters
def sanitize(value: str) -> str:
    for char in ["<", ">", "&", "'", '"']:
        value = value.replace(char, "")
    return value

# ✅ Correct: allowlist permitted characters
import re

def validate_username(value: str) -> str:
    if not re.fullmatch(r"[a-zA-Z0-9_\-]{3,32}", value):
        raise ValueError("Invalid username")
    return value
```

### Type Coercion and Validation

```python
# ❌ Anti-pattern: manual validation
def process(data: dict):
    age = int(data.get("age", 0))  # no bounds, no type safety

# ✅ Correct: pydantic model with constraints
from pydantic import BaseModel, Field, EmailStr

class UserInput(BaseModel):
    username: str = Field(min_length=3, max_length=32, pattern=r"^[a-zA-Z0-9_\-]+$")
    age: int = Field(ge=0, le=150)
    email: EmailStr
```

### ReDoS Prevention

```python
# ❌ Anti-pattern: catastrophic backtracking
import re
re.match(r"(a+)+$", user_input)  # exponential time on "aaaaaaaaaaaaaaaaX"

# ✅ Correct: use atomic patterns or limit input length, prefer re2
import re2  # google-re2: linear-time guarantees

def safe_match(pattern: str, value: str, max_len: int = 1000) -> bool:
    if len(value) > max_len:
        raise ValueError("Input too long")
    return bool(re2.fullmatch(pattern, value))
```

### File Upload Validation

```python
# ❌ Anti-pattern: trust file extension and user-supplied name
def save_upload(file):
    file.save(f"/uploads/{file.filename}")

# ✅ Correct: validate type, size, and sanitize name
import uuid
import magic
from pathlib import PurePosixPath

ALLOWED_TYPES = {"image/png", "image/jpeg", "application/pdf"}
MAX_SIZE = 10 * 1024 * 1024  # 10 MB

def save_upload(file_content: bytes, original_name: str, upload_dir: Path) -> Path:
    if len(file_content) > MAX_SIZE:
        raise ValueError("File too large")
    mime = magic.from_buffer(file_content[:2048], mime=True)
    if mime not in ALLOWED_TYPES:
        raise ValueError(f"Disallowed file type: {mime}")
    ext = PurePosixPath(original_name).suffix.lower()
    if ext not in {".png", ".jpg", ".jpeg", ".pdf"}:
        raise ValueError("Invalid extension")
    safe_name = f"{uuid.uuid4().hex}{ext}"
    dest = upload_dir / safe_name
    dest.write_bytes(file_content)
    return dest
```

### Email, URL, and Path Validation

- Use `pydantic.EmailStr` (backed by `email-validator`) for emails.
- Use `pydantic.HttpUrl` or `urllib.parse.urlparse` + scheme allowlist for URLs.
- Validate paths with `pathlib.Path.resolve()` and check against an allowed base directory.

```python
from urllib.parse import urlparse

ALLOWED_SCHEMES = {"https"}

def validate_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.scheme not in ALLOWED_SCHEMES:
        raise ValueError("Only HTTPS URLs allowed")
    if not parsed.hostname:
        raise ValueError("Missing hostname")
    return url
```

**Key rules:**

- Always use `re.fullmatch`, never `re.match` for validation (avoids partial matches).
- Limit input length before regex evaluation.
- Prefer pydantic or marshmallow for structured input over manual checks.
- Validate MIME type by reading file magic bytes, never trust extension alone.

---

## 2. Authentication and Authorization Patterns

Hash passwords with modern, memory-hard algorithms. Enforce least-privilege at every layer.

### Password Hashing

```python
# ❌ Anti-pattern: plain hash
import hashlib
hashed = hashlib.sha256(password.encode()).hexdigest()

# ✅ Correct: argon2-cffi (preferred) or bcrypt
from argon2 import PasswordHasher

ph = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=4)
hashed = ph.hash(password)

# Verification
try:
    ph.verify(hashed, password_attempt)
except argon2.exceptions.VerifyMismatchError:
    raise AuthenticationError("Invalid credentials")
```

```python
# Alternative: bcrypt
import bcrypt
hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
assert bcrypt.checkpw(password_attempt.encode(), hashed)
```

### JWT Best Practices

```python
# ❌ Anti-pattern: no expiry, algorithm confusion
import jwt
token = jwt.encode({"user": "admin"}, key, algorithm="HS256")
data = jwt.decode(token, key, algorithms=["HS256", "none"])  # allows "none"!

# ✅ Correct: explicit algorithm, expiry, issuer, audience
import jwt
from datetime import datetime, timedelta, timezone

def create_token(user_id: str, secret: str) -> str:
    return jwt.encode(
        {
            "sub": user_id,
            "iat": datetime.now(timezone.utc),
            "exp": datetime.now(timezone.utc) + timedelta(hours=1),
            "iss": "myapp",
            "aud": "myapp-api",
        },
        secret,
        algorithm="HS256",
    )

def verify_token(token: str, secret: str) -> dict:
    return jwt.decode(
        token, secret,
        algorithms=["HS256"],  # single allowed algorithm
        options={"require": ["exp", "iss", "sub"]},
        issuer="myapp",
        audience="myapp-api",
    )
```

### Decorator-Based Permission Checks

```python
from functools import wraps

def require_role(*roles: str):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            user = get_current_user()
            if user.role not in roles:
                raise PermissionError("Insufficient permissions")
            return fn(*args, **kwargs)
        return wrapper
    return decorator

@require_role("admin", "editor")
def delete_article(article_id: int): ...
```

### Session Management

- Set `HttpOnly`, `Secure`, `SameSite=Lax` (or `Strict`) on session cookies.
- Regenerate session ID after login to prevent session fixation.
- Enforce absolute session timeout (e.g., 24h) and idle timeout (e.g., 30min).
- Store sessions server-side; never store sensitive data in client-side cookies.

**Key rules:**

- Never store plaintext passwords. Use argon2-cffi as the default recommendation.
- Always pin JWT algorithm to a single value in `algorithms=[...]`.
- Always require `exp` claim in JWTs. Keep token lifetime short (<1h for access tokens).
- Use refresh tokens (opaque, stored server-side) for long-lived sessions.
- Apply RBAC checks at the route/endpoint level, not just in the UI.

---

## 3. Cryptography Best Practices

Use the `cryptography` library for all cryptographic operations. Never implement custom cryptographic algorithms.

### Symmetric Encryption (Fernet)

```python
# ❌ Anti-pattern: ECB mode, manual IV
from Crypto.Cipher import AES
cipher = AES.new(key, AES.MODE_ECB)  # ECB leaks patterns

# ✅ Correct: Fernet (AES-128-CBC + HMAC-SHA256, built-in IV + timestamp)
from cryptography.fernet import Fernet

key = Fernet.generate_key()  # store securely
f = Fernet(key)
token = f.encrypt(plaintext.encode())
plaintext = f.decrypt(token).decode()
```

### Asymmetric Encryption (RSA)

```python
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes

private_key = rsa.generate_private_key(public_exponent=65537, key_size=4096)
public_key = private_key.public_key()

ciphertext = public_key.encrypt(
    plaintext.encode(),
    padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()), algorithm=hashes.SHA256(), label=None),
)
```

### Secure Randomness

```python
# ❌ Anti-pattern: random module is NOT cryptographically secure
import random
token = "".join(random.choices("abcdef0123456789", k=32))

# ✅ Correct: secrets module
import secrets
token = secrets.token_urlsafe(32)     # URL-safe base64
hex_token = secrets.token_hex(32)     # hex string
```

### Hashing and Key Derivation

```python
import hashlib

# Integrity hashing (non-password)
digest = hashlib.sha256(data).hexdigest()
digest = hashlib.blake2b(data, digest_size=32).hexdigest()

# Key derivation (password → key)
from cryptography.hazmat.primitives.kdf.scrypt import Scrypt
import os

salt = os.urandom(16)
kdf = Scrypt(salt=salt, length=32, n=2**17, r=8, p=1)
key = kdf.derive(password.encode())
```

### Envelope Encryption

Encrypt data with a unique data encryption key (DEK), then encrypt the DEK with a key encryption key (KEK).

```python
from cryptography.fernet import Fernet

def envelope_encrypt(plaintext: bytes, kek: bytes) -> tuple[bytes, bytes]:
    dek = Fernet.generate_key()
    encrypted_data = Fernet(dek).encrypt(plaintext)
    encrypted_dek = Fernet(kek).encrypt(dek)
    return encrypted_data, encrypted_dek
```

**Key rules:**

- Never use `random` for security-sensitive values. Always use `secrets`.
- Never use MD5 or SHA-1 for security purposes.
- Use RSA key size ≥ 3072 bits (prefer 4096).
- Always use OAEP padding for RSA encryption, PSS for RSA signatures.
- Validate TLS certificates; never set `verify=False` in production.
- Store keys in a secrets manager, never in source code.

---

## 4. Secure Data Handling

Minimize data exposure. Store secrets outside the codebase. Compare sensitive values in constant time.

### Secrets Management

```python
# ❌ Anti-pattern: hardcoded secrets
DB_PASSWORD = "supersecret123"

# ✅ Correct: environment variables with validation
import os

def get_required_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value

DB_PASSWORD = get_required_env("DB_PASSWORD")
```

```python
# ✅ Vault integration (hvac)
import hvac

client = hvac.Client(url="https://vault.example.com", token=os.environ["VAULT_TOKEN"])
secret = client.secrets.kv.v2.read_secret_version(path="db/creds")
db_password = secret["data"]["data"]["password"]
```

### Secure String Comparison

```python
# ❌ Anti-pattern: timing side-channel
if token == expected_token:  # early exit leaks length info
    ...

# ✅ Correct: constant-time comparison
import hmac

if hmac.compare_digest(token.encode(), expected_token.encode()):
    ...
```

### Memory Handling

```python
# Clear sensitive data after use (best-effort in CPython)
import ctypes

def secure_clear(s: bytearray):
    """Zero out a bytearray in place."""
    ctypes.memset((ctypes.c_char * len(s)).from_buffer(s), 0, len(s))

password = bytearray(b"secret")
try:
    process(password)
finally:
    secure_clear(password)
```

### PII and Data Minimization

- Collect only necessary PII fields. Strip unnecessary data at the boundary.
- Hash or tokenize identifiers when full values are not needed.
- Apply field-level encryption for sensitive columns (SSN, credit card).
- Log redacted values only: `email=j***@example.com`.

**Key rules:**

- Never commit secrets to version control. Use `.env` files excluded via `.gitignore`, or vault.
- Always use `hmac.compare_digest` for token/signature comparison.
- Use `bytearray` (mutable) instead of `str`/`bytes` (immutable) for secrets when clearing is needed.
- Redact PII in all log output.

---

## 5. File and Path Operations

Canonicalize all paths before use. Never construct file paths from raw user input.

### Path Traversal Prevention

```python
# ❌ Anti-pattern: direct concatenation
def read_file(user_path: str) -> bytes:
    return open(f"/data/{user_path}", "rb").read()  # "../../../etc/passwd"

# ✅ Correct: resolve and check prefix
from pathlib import Path

BASE_DIR = Path("/data").resolve()

def safe_read(user_path: str) -> bytes:
    target = (BASE_DIR / user_path).resolve()
    if not target.is_relative_to(BASE_DIR):
        raise ValueError("Path traversal detected")
    return target.read_bytes()
```

### Secure Temporary Files

```python
# ❌ Anti-pattern: predictable temp file
with open("/tmp/myapp_data.txt", "w") as f:
    f.write(secret)

# ✅ Correct: tempfile module (unpredictable name, secure permissions)
import tempfile

with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=True) as f:
    f.write(secret)
    f.flush()
    process(f.name)
# File auto-deleted on close
```

### Symlink Attack Prevention

```python
import os
from pathlib import Path

def safe_open(path: Path, base_dir: Path):
    resolved = path.resolve()
    if not resolved.is_relative_to(base_dir.resolve()):
        raise ValueError("Symlink escape detected")
    if resolved.is_symlink():
        raise ValueError("Symlinks not allowed")
    return resolved.open("r")
```

### File Permission Management

```python
import os, stat

# Set restrictive permissions: owner read/write only
os.chmod(filepath, stat.S_IRUSR | stat.S_IWUSR)  # 0o600

# Create file with restricted permissions from the start
fd = os.open(filepath, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w") as f:
    f.write(secret_data)
```

**Key rules:**

- Always call `.resolve()` on user-supplied paths and verify prefix with `.is_relative_to()`.
- Use `tempfile` module for all temporary files—never construct temp paths manually.
- Set file permissions to `0o600` for sensitive files.
- Check `os.path.islink()` or `Path.is_symlink()` before operating on files when symlink attacks are a concern.

---

## 6. Subprocess and System Interaction

Never pass untrusted input through a shell. Use list-form arguments to prevent injection.

### Shell Injection Prevention

```python
# ❌ Anti-pattern: shell=True with user input
import subprocess
subprocess.run(f"grep {user_input} /var/log/app.log", shell=True)  # injection!

# ✅ Correct: list arguments, no shell
subprocess.run(["grep", "--", user_input, "/var/log/app.log"], check=True, capture_output=True)
```

### When Shell Is Unavoidable

```python
# ✅ Use shlex.quote for shell escaping
import shlex
cmd = f"echo {shlex.quote(user_input)}"
subprocess.run(cmd, shell=True, check=True)
```

### Avoiding Dangerous Functions

```python
# ❌ Never use these with untrusted input:
os.system(f"rm {filename}")          # shell injection
os.popen(f"cat {filename}")          # shell injection
eval(user_expression)                # arbitrary code execution
exec(user_code)                      # arbitrary code execution

# ✅ Use subprocess.run with list form:
subprocess.run(["rm", "--", filename], check=True)
```

### Environment Variable Injection

```python
# ❌ Anti-pattern: inherit full environment
subprocess.run(cmd, env=os.environ)  # leaks secrets to child process

# ✅ Correct: explicit minimal environment
safe_env = {"PATH": "/usr/bin", "LANG": "C.UTF-8"}
subprocess.run(cmd, env=safe_env, check=True)
```

**Key rules:**

- Default to `shell=False` (the default). Use list-form `[cmd, arg1, arg2]`.
- Never pass unsanitized user input to `os.system`, `os.popen`, `eval`, or `exec`.
- Use `shlex.quote` only when shell mode is truly required.
- Pass a minimal, explicit `env` dict to child processes.
- Always use `check=True` to catch subprocess failures.

---

## 7. Serialization and Deserialization

Treat deserialization of untrusted data as code execution. Use safe-by-default formats.

### Pickle: Never With Untrusted Data

```python
# ❌ Anti-pattern: arbitrary code execution
import pickle
data = pickle.loads(untrusted_bytes)  # can execute arbitrary code

# ✅ Correct: use JSON or other safe formats
import json
data = json.loads(untrusted_string)  # safe: only produces dicts, lists, primitives
```

### YAML: Always safe_load

```python
# ❌ Anti-pattern: yaml.load allows arbitrary Python objects
import yaml
data = yaml.load(untrusted_string)  # can instantiate arbitrary objects

# ✅ Correct: yaml.safe_load or yaml.SafeLoader
data = yaml.safe_load(untrusted_string)
# or
data = yaml.load(untrusted_string, Loader=yaml.SafeLoader)
```

### XML: Prevent XXE

```python
# ❌ Anti-pattern: stdlib XML parsers allow external entities
from xml.etree.ElementTree import parse
tree = parse(untrusted_file)  # XXE, billion laughs attack

# ✅ Correct: defusedxml
import defusedxml.ElementTree as ET
tree = ET.parse(untrusted_file)  # blocks DTD, external entities, entity expansion
```

### Safer Alternatives

- **JSON** — safe by default, use `json.loads` / `json.dumps`.
- **MessagePack** — `msgpack.unpackb(data, raw=False)` — compact binary, no code execution.
- **Protocol Buffers** — schema-defined, typed, no arbitrary code execution.

**Key rules:**

- Never `pickle.loads` or `pickle.load` on data from untrusted sources.
- Never use `yaml.load` without `Loader=yaml.SafeLoader`. Prefer `yaml.safe_load`.
- Replace `xml.etree.ElementTree` with `defusedxml.ElementTree` for untrusted XML.
- Prefer JSON for data interchange; use protobuf or msgpack for performance-critical paths.

---

## 8. Web Framework Security

Apply framework-specific security defaults. Never disable protections without compensating controls.

### Django

#### CSRF and Clickjacking

```python
# settings.py — ensure these are NOT disabled
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",         # CSRF protection
    "django.middleware.clickjacking.XFrameOptionsMiddleware",  # clickjacking
]
X_FRAME_OPTIONS = "DENY"
CSRF_COOKIE_HTTPONLY = True
```

#### ORM Safety

```python
# ❌ Anti-pattern: raw SQL with string formatting
User.objects.raw(f"SELECT * FROM auth_user WHERE username = '{name}'")

# ✅ Correct: parameterized queries
User.objects.raw("SELECT * FROM auth_user WHERE username = %s", [name])
# or use the ORM
User.objects.filter(username=name)
```

#### Template Safety

```python
# ❌ Anti-pattern: marking untrusted content as safe
from django.utils.safestring import mark_safe
return mark_safe(user_input)  # XSS

# ✅ Django auto-escapes by default in templates. Never mark_safe user input.
# Use |escape filter explicitly when needed.
```

#### Security Settings Checklist

```python
# settings.py (production)
SECRET_KEY = get_required_env("DJANGO_SECRET_KEY")
DEBUG = False
ALLOWED_HOSTS = ["example.com"]
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_CONTENT_TYPE_NOSNIFF = True
```

### Flask

#### CSRF Protection

```python
from flask_wtf.csrf import CSRFProtect

app = Flask(__name__)
app.config["SECRET_KEY"] = get_required_env("FLASK_SECRET_KEY")
csrf = CSRFProtect(app)
```

#### Secure Session Configuration

```python
app.config.update(
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    PERMANENT_SESSION_LIFETIME=timedelta(hours=1),
)
```

#### Jinja2 Auto-Escaping

```python
# Jinja2 auto-escapes HTML in .html templates by default.
# ❌ Never use |safe with user input:
{{ user_input | safe }}  {# XSS #}

# ✅ Let auto-escaping work:
{{ user_input }}
```

### FastAPI

#### Dependency Injection for Auth

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    payload = verify_token(token, SECRET_KEY)
    user = await get_user(payload["sub"])
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
    return user

@app.get("/me")
async def read_me(user: User = Depends(get_current_user)):
    return user
```

#### CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

# ❌ Anti-pattern:
app.add_middleware(CORSMiddleware, allow_origins=["*"])  # too permissive

# ✅ Correct: explicit origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://example.com"],
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization"],
    allow_credentials=True,
)
```

#### Rate Limiting

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.get("/api/search")
@limiter.limit("10/minute")
async def search(request: Request, q: str):
    ...
```

**Key rules (all frameworks):**

- Never set `DEBUG = True` in production.
- Always use parameterized queries or the ORM—never string-format SQL.
- Never mark user input as safe/trusted in templates.
- Configure CORS with explicit origin allowlists.
- Set all cookie security flags: `Secure`, `HttpOnly`, `SameSite`.
- Apply rate limiting on authentication and sensitive endpoints.

---

## 9. Error Handling and Information Disclosure

Expose minimal information to clients. Log full details server-side only.

### Stack Trace Exposure

```python
# ❌ Anti-pattern: leaking internals
@app.errorhandler(Exception)
def handle_error(e):
    return {"error": str(e), "trace": traceback.format_exc()}, 500

# ✅ Correct: generic message to client, full details to log
import logging
logger = logging.getLogger(__name__)

@app.errorhandler(Exception)
def handle_error(e):
    logger.exception("Unhandled exception")  # full trace to server log
    return {"error": "An internal error occurred"}, 500
```

### Custom Error Handlers

```python
class AppError(Exception):
    """Base application error with safe external message."""
    def __init__(self, message: str, status_code: int = 400, internal: str | None = None):
        self.message = message        # safe for client
        self.internal = internal      # logged only
        self.status_code = status_code

@app.errorhandler(AppError)
def handle_app_error(e: AppError):
    if e.internal:
        logger.error(f"AppError: {e.internal}")
    return {"error": e.message}, e.status_code
```

### Exception Handling Patterns

```python
# ❌ Anti-pattern: swallowing security exceptions
try:
    verify_signature(token)
except Exception:
    pass  # silently continues with unverified token

# ✅ Correct: catch specific exceptions, never swallow auth/crypto errors
try:
    verify_signature(token)
except InvalidSignatureError:
    logger.warning("Invalid token signature", extra={"token_prefix": token[:8]})
    raise HTTPException(status_code=401, detail="Invalid token")
```

**Key rules:**

- Never return `traceback`, exception messages, or SQL errors to the client.
- Use a two-tier error model: safe message for the response, detailed message for the log.
- Never use bare `except: pass` for security-sensitive operations.
- Log at `WARNING` or `ERROR` for auth failures; include non-sensitive context.
- Disable `DEBUG` mode in production for all frameworks.

---

## 10. Concurrency and Race Conditions

Eliminate TOCTOU gaps. Use atomic operations and database-level locking for critical sections.

### TOCTOU Vulnerabilities

```python
# ❌ Anti-pattern: check-then-act race condition
import os

if os.path.exists(filepath):     # T1: check
    os.remove(filepath)          # T2: use — file may have changed

# ✅ Correct: act and handle failure atomically
try:
    os.remove(filepath)
except FileNotFoundError:
    pass  # already gone — expected in concurrent context
```

### Database-Level Locking

```python
# ❌ Anti-pattern: read-modify-write without locking
user = User.objects.get(id=user_id)
user.balance -= amount
user.save()  # lost update if concurrent

# ✅ Correct: SELECT FOR UPDATE (Django ORM)
from django.db import transaction

with transaction.atomic():
    user = User.objects.select_for_update().get(id=user_id)
    if user.balance < amount:
        raise InsufficientFundsError()
    user.balance -= amount
    user.save()
```

```python
# ✅ Alternative: F() expressions for atomic updates
from django.db.models import F

User.objects.filter(id=user_id).update(balance=F("balance") - amount)
```

### Atomic File Operations

```python
# ❌ Anti-pattern: direct write (partial content on crash)
with open(target, "w") as f:
    f.write(new_content)

# ✅ Correct: write-to-temp then atomic rename
import tempfile, os

def atomic_write(target: str, content: str):
    dir_name = os.path.dirname(target)
    with tempfile.NamedTemporaryFile("w", dir=dir_name, delete=False) as tmp:
        tmp.write(content)
        tmp.flush()
        os.fsync(tmp.fileno())
    os.replace(tmp.name, target)  # atomic on POSIX
```

### Thread Safety With Secrets

```python
# ❌ Anti-pattern: shared mutable secret state
api_key = None  # global mutable

def rotate_key():
    global api_key
    api_key = fetch_new_key()  # race with readers

# ✅ Correct: threading.Lock or thread-local
import threading

_lock = threading.Lock()
_api_key: str = ""

def get_key() -> str:
    with _lock:
        return _api_key

def rotate_key():
    new_key = fetch_new_key()
    with _lock:
        global _api_key
        _api_key = new_key
```

**Key rules:**

- Never separate permission/existence checks from the operation—use EAFP (try/except).
- Use `SELECT FOR UPDATE` or `F()` expressions for database write contention.
- Use `os.replace()` (atomic rename) for safe file updates.
- Protect shared mutable state with `threading.Lock`.
- Prefer database constraints (unique, check) over application-level checks for invariants.
