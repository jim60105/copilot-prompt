# OWASP Top 10:2025 — Python Security Reference

Reference for AI agents performing Python security reviews, threat modeling, and secure code generation.

## Table of Contents

- [A01: Broken Access Control](#a01-broken-access-control)
- [A02: Security Misconfiguration](#a02-security-misconfiguration)
- [A03: Software Supply Chain Failures](#a03-software-supply-chain-failures)
- [A04: Cryptographic Failures](#a04-cryptographic-failures)
- [A05: Injection](#a05-injection)
- [A06: Insecure Design](#a06-insecure-design)
- [A07: Authentication Failures](#a07-authentication-failures)
- [A08: Software or Data Integrity Failures](#a08-software-or-data-integrity-failures)
- [A09: Security Logging and Alerting Failures](#a09-security-logging-and-alerting-failures)
- [A10: Mishandling of Exceptional Conditions](#a10-mishandling-of-exceptional-conditions)

---

## A01: Broken Access Control

Failure to enforce that users act only within their intended permissions. Remains the most common web application vulnerability. In 2025, SSRF (previously A10:2021) is consolidated here as a CWE under broken access control.

### Python-Specific Risks

- Missing authorization decorators on views/endpoints
- Insecure Direct Object References (IDOR): accessing objects by user-supplied ID without ownership check
- Path traversal via unsanitized user input in file operations (`os.path.join` with absolute user paths)
- Relying solely on client-side or frontend checks
- Overly permissive CORS configuration
- Server-Side Request Forgery (SSRF): fetching user-supplied URLs without validation

### Vulnerable Code

```python
# IDOR — no ownership verification
@app.route("/api/orders/<int:order_id>")
@login_required
def get_order(order_id):
    order = Order.query.get(order_id)  # Any authenticated user can access any order
    return jsonify(order.to_dict())

# Path traversal
@app.route("/files")
def get_file():
    filename = request.args.get("name")
    return send_file(os.path.join("/uploads", filename))  # ../../etc/passwd

# SSRF — user controls the URL entirely
@app.route("/fetch")
def fetch_url():
    url = request.args.get("url")
    response = requests.get(url)  # Can reach http://169.254.169.254/metadata
    return response.text
```

### Secure Code

```python
# Object-level permission check
@app.route("/api/orders/<int:order_id>")
@login_required
def get_order(order_id):
    order = Order.query.get_or_404(order_id)
    if order.user_id != current_user.id:
        abort(403)
    return jsonify(order.to_dict())

# Safe file access with path confinement
@app.route("/files")
def get_file():
    filename = request.args.get("name")
    safe_path = Path("/uploads").resolve() / filename
    if not safe_path.resolve().is_relative_to(Path("/uploads").resolve()):
        abort(400)
    return send_file(safe_path)

# SSRF protection — validate URL and resolved IP
from urllib.parse import urlparse
import ipaddress, socket

ALLOWED_SCHEMES = {"https"}
BLOCKED_NETWORKS = [
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("169.254.0.0/16"),  # Cloud metadata
    ipaddress.ip_network("::1/128"),
]

def validate_url(url: str) -> bool:
    parsed = urlparse(url)
    if parsed.scheme not in ALLOWED_SCHEMES:
        return False
    if not parsed.hostname:
        return False
    try:
        resolved_ip = ipaddress.ip_address(socket.gethostbyname(parsed.hostname))
    except (socket.gaierror, ValueError):
        return False
    return all(resolved_ip not in net for net in BLOCKED_NETWORKS)

@app.route("/fetch")
def fetch_url():
    url = request.args.get("url")
    if not validate_url(url):
        abort(400, "URL not allowed")
    response = requests.get(url, timeout=5, allow_redirects=False)
    return response.text
```

### Mitigation Strategies

- Deny by default; require explicit authorization for every endpoint
- Enforce object-level permission checks (not just role checks)
- Use `pathlib.Path.resolve()` and `is_relative_to()` to prevent path traversal
- Return 404 (not 403) for unauthorized resources to prevent enumeration
- Log and alert on access control failures
- SSRF: validate URLs, block private/internal IPs and cloud metadata endpoints
- SSRF: resolve DNS and validate IP before requests; disable redirects or re-validate

---

## A02: Security Misconfiguration

Insecure default configurations, incomplete setup, open cloud storage, misconfigured HTTP headers, verbose error messages, or XXE vulnerabilities. Moved up from #5 in 2021. XXE (XML External Entities) is now covered here.

### Python-Specific Risks

- Django: `DEBUG=True`, default `SECRET_KEY`, empty `ALLOWED_HOSTS`
- Flask: `app.run(debug=True)` in production, weak secret key
- FastAPI: Swagger/ReDoc docs exposed in production, permissive CORS
- Exposed `__pycache__`, `.pyc`, `.env`, `requirements.txt` via static file serving
- Default admin credentials left active
- Missing security headers (CSP, HSTS, X-Content-Type-Options)
- XML parsers with external entity processing enabled (XXE)

### Vulnerable Configuration

```python
# Django — INSECURE
DEBUG = True
SECRET_KEY = "django-insecure-abc123"
ALLOWED_HOSTS = ["*"]

# Flask — INSECURE
app.secret_key = "dev"
app.run(debug=True, host="0.0.0.0")

# XXE — INSECURE XML parsing
from lxml import etree
parser = etree.XMLParser(resolve_entities=True)
tree = etree.parse(user_upload, parser)
```

### Secure Configuration

```python
# Django — SECURE
DEBUG = False
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
ALLOWED_HOSTS = ["example.com", "www.example.com"]
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000

# Flask — SECURE
app.secret_key = os.environ["FLASK_SECRET_KEY"]
app.config["SESSION_COOKIE_SECURE"] = True
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"

# FastAPI — disable docs in production, restrictive CORS
app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://example.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

# XXE — SECURE: use defusedxml or disable entities
from defusedxml import ElementTree
tree = ElementTree.parse(user_upload)
```

### Mitigation Strategies

- Disable debug modes, interactive docs, and verbose errors in production
- Set `ALLOWED_HOSTS` / CORS origins to explicit values — never `*` with credentials
- Configure security headers via middleware (`django-csp`, `flask-talisman`)
- Use `defusedxml` for all XML parsing; disable entity resolution in `lxml`
- Run `python manage.py check --deploy` for Django security checks

---

## A03: Software Supply Chain Failures

Renamed and significantly expanded from "Vulnerable and Outdated Components" (A06:2021). Covers the entire software supply chain: known vulnerabilities, unpinned dependencies, typosquatting, transitive dependency risks, CI/CD pipeline security, SBOM management, vendor compromise, and malicious packages.

### Python-Specific Risks

- Outdated packages with known CVEs in `requirements.txt`
- Unpinned dependencies pulling in vulnerable versions
- Typosquatting attacks on PyPI (e.g., `python-nmap` vs `nmap`)
- Transitive dependency vulnerabilities not visible in direct deps
- No Software Bill of Materials (SBOM) for deployed applications
- CI/CD secrets exposed in logs or untrusted workflows
- Unvetted PyPI packages with embedded malicious code
- Lack of hash verification during package installation

### Vulnerability Scanning

```bash
# pip-audit — recommended by PyPA
pip-audit
pip-audit -r requirements.txt

# safety (alternative scanner)
safety check

# Generate CycloneDX SBOM
pip-audit --format=cyclonedx-json -o sbom.json
```

### Dependency Pinning and Hash Verification

```text
# requirements.txt — pin exact versions with hashes
flask==3.0.0 \
    --hash=sha256:...
requests==2.31.0 \
    --hash=sha256:...

# Generate pinned requirements with hashes using pip-compile
pip install pip-tools
pip-compile --generate-hashes requirements.in -o requirements.txt

# Install with hash verification
pip install --require-hashes -r requirements.txt
```

### Typosquatting Prevention

Verify package names before installing: check official docs, download stats, maintainer reputation, and source repository. Common typosquat targets: `python-dateutil` vs `python3-dateutil`, `python-nmap` vs `nmap`, `urllib3` vs `urllib`, `beautifulsoup4` vs `beautifulsoup`.

### CI/CD Pipeline Security

- Pin GitHub Actions by commit SHA, not tags
- Never expose secrets in logs; use `::add-mask::` in GitHub Actions
- Use `pull_request` (not `pull_request_target`) for untrusted code
- Restrict CI/CD secrets to specific branches and environments

### Mitigation Strategies

- Pin all dependencies to exact versions with hashes
- Use `pip-compile --generate-hashes` and `--require-hashes` for integrity verification
- Run `pip-audit` or `safety` in CI/CD to block vulnerable dependencies
- Enable Dependabot or Renovate for automated dependency updates
- Generate and maintain SBOM (CycloneDX or SPDX format)
- Verify package names carefully — check download stats and maintainer on PyPI
- Audit transitive dependencies with `pipdeptree`
- Pin CI/CD actions by commit SHA, not mutable tags
- Use virtual environments and private PyPI mirrors for production
- Implement staged rollouts and change management for dependency updates

---

## A04: Cryptographic Failures

Failure to properly protect data in transit and at rest, including use of weak algorithms or poor key management.

### Python-Specific Risks

- Using `hashlib.md5()` / `hashlib.sha1()` for password hashing
- Using `random` module for security-sensitive values (predictable PRNG)
- Hardcoded secrets, API keys, or encryption keys in source code
- Weak TLS configuration or disabled certificate verification (`verify=False`)
- Storing secrets in `.env` files committed to version control

### Vulnerable Code

```python
# Weak password hashing
password_hash = hashlib.md5(password.encode()).hexdigest()

# Predictable token generation
token = "".join(random.choices("abcdef0123456789", k=32))

# Hardcoded secret
SECRET_KEY = "super-secret-key-12345"

# Disabled TLS verification
response = requests.get(url, verify=False)
```

### Secure Code

```python
import secrets
from argon2 import PasswordHasher

# Strong password hashing
ph = PasswordHasher()
password_hash = ph.hash(password)

# Cryptographically secure token
token = secrets.token_urlsafe(32)

# Load secret from environment
SECRET_KEY = os.environ["SECRET_KEY"]  # Fail loudly if missing
```

### Key Management Patterns

- Load secrets from environment variables or a secrets manager
- Use `cryptography` library (not `pycrypto`) for encryption
- Generate keys with `os.urandom()` or `secrets.token_bytes()`
- Rotate secrets periodically; support multiple active keys during rotation

### Mitigation Strategies

- Use `bcrypt` or `argon2-cffi` for password hashing — never raw hash functions
- Use `secrets` module for all security-sensitive random values
- Enforce TLS 1.2+ and valid certificates; pin certificates for critical services
- Audit codebase for hardcoded secrets using tools like `detect-secrets` or `trufflehog`
- Classify data and apply encryption based on sensitivity

---

## A05: Injection

Untrusted data sent to an interpreter as part of a command or query. Includes SQL, OS command, and template injection.

### Python-Specific Risks

- Raw SQL string formatting with `cursor.execute(f"...")`
- `os.system()` or `subprocess` with `shell=True` and user input
- Jinja2 server-side template injection (SSTI) via `Template(user_input)`
- ORM escape hatches: `extra()`, `raw()`, `RawSQL()` in Django
- `eval()`, `exec()`, `compile()` with user-controlled input

### SQL Injection

```python
# VULNERABLE — string formatting
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
cursor.execute("SELECT * FROM users WHERE name = '%s'" % name)

# SECURE — parameterized queries
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# SQLAlchemy — use bound parameters
db.session.execute(text("SELECT * FROM users WHERE id = :id"), {"id": user_id})

# Django ORM — safe by default, but watch for raw()
User.objects.raw("SELECT * FROM users WHERE id = %s", [user_id])  # Safe
User.objects.raw(f"SELECT * FROM users WHERE id = {user_id}")     # VULNERABLE
```

### Command Injection

```python
# VULNERABLE — shell=True with user input
subprocess.call(f"convert {filename} output.png", shell=True)
os.system(f"ping {host}")

# SECURE — list arguments, no shell
subprocess.run(["convert", filename, "output.png"], check=True)

# Use shlex.quote() when shell is unavoidable
import shlex
subprocess.run(f"echo {shlex.quote(user_input)}", shell=True)
```

### Template Injection (SSTI)

```python
# VULNERABLE — user input as template source
template = Template(user_input)  # SSTI: user_input = "{{ config }}"

# SECURE — user input as template data only
template = Template("Hello, {{ name }}!")
output = template.render(name=user_input)
```

### Mitigation Strategies

- Use parameterized queries for ALL database operations — no exceptions
- Never use `shell=True` with user input; pass arguments as lists
- Never pass user input as template source — only as template data
- Never use `eval()`, `exec()`, or `compile()` with user-controlled input
- Use ORM query builders; audit all uses of `raw()`, `extra()`, `RawSQL()`

---

## A06: Insecure Design

Missing or ineffective security controls at the design level. Unlike implementation bugs, insecure design cannot be fixed by perfect code alone. Moved from #4 to #6 in 2025.

### Python-Specific Risks

- No rate limiting on authentication or sensitive endpoints
- Business logic flaws: missing quantity limits, price manipulation
- No account lockout after failed login attempts
- APIs returning more data than the client needs (over-fetching)

### Vulnerable vs Secure Design

```python
# VULNERABLE — no rate limiting, brute force possible
@app.route("/login", methods=["POST"])
def login():
    user = User.query.filter_by(email=request.json["email"]).first()
    if user and user.check_password(request.json["password"]):
        return create_token(user)
    return jsonify({"error": "Invalid credentials"}), 401

# SECURE — rate limited with explicit serialization
from flask_limiter import Limiter
limiter = Limiter(app, default_limits=["100 per hour"])

@app.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    user = User.query.filter_by(email=request.json["email"]).first()
    if user and user.check_password(request.json["password"]):
        return create_token(user)
    return jsonify({"error": "Invalid credentials"}), 401

# VULNERABLE — over-fetching
return jsonify(user.__dict__)  # Exposes password hash, internal fields

# SECURE — explicit serialization
return jsonify({"id": user.id, "name": user.name, "email": user.email})
```

### Mitigation Strategies

- Implement rate limiting on all authentication and sensitive endpoints
- Validate business logic constraints server-side
- Use explicit serialization schemas (Pydantic, Marshmallow) — never serialize ORM objects directly
- Apply fail-secure defaults: deny on error, lock on suspicious activity
- Enforce account lockout or progressive delays after repeated failures

---

## A07: Authentication Failures

Weaknesses in authentication mechanisms that allow attackers to compromise passwords, keys, or session tokens. Renamed from "Identification and Authentication Failures" in 2021.

### Python-Specific Risks

- Session fixation: not regenerating session ID after login
- JWT misconfiguration: `algorithm="none"`, missing expiry, secret in source code
- Storing passwords in plaintext or with reversible encryption
- Missing MFA on privileged accounts
- OAuth2 state parameter omission (CSRF in OAuth flow)

### JWT Pitfalls

```python
# VULNERABLE — algorithm confusion, no expiry
payload = jwt.decode(token, options={"verify_signature": False})  # DANGER
token = jwt.encode({"user_id": 1}, SECRET_KEY, algorithm="HS256")  # No expiry

# SECURE — explicit algorithm, expiry, audience
from datetime import datetime, timedelta, timezone

token = jwt.encode(
    {
        "user_id": 1,
        "exp": datetime.now(timezone.utc) + timedelta(hours=1),
        "aud": "myapp",
    },
    os.environ["JWT_SECRET"],
    algorithm="HS256",
)

payload = jwt.decode(
    token,
    os.environ["JWT_SECRET"],
    algorithms=["HS256"],  # Explicit list — prevent algorithm confusion
    audience="myapp",
)
```

### Session Management

- Django: `login(request, user)` automatically cycles session key
- Flask: call `session.clear()` before setting new session data after authentication
- Set `session.permanent = True` and configure `PERMANENT_SESSION_LIFETIME`

### Mitigation Strategies

- Use established auth libraries (`Flask-Login`, `django.contrib.auth`, `FastAPI` OAuth2 utilities)
- Always specify `algorithms=["HS256"]` (list) when decoding JWTs — prevent algorithm confusion
- Set JWT expiry (`exp`) and validate it; use short-lived access tokens with refresh tokens
- Store JWT secrets in environment variables — never in source code
- Regenerate session IDs after authentication
- Implement account lockout after repeated failed attempts
- Enforce MFA for admin and privileged accounts
- Validate OAuth2 `state` parameter to prevent CSRF

---

## A08: Software or Data Integrity Failures

Failure to protect against integrity violations: insecure deserialization, untrusted CI/CD pipelines, unsigned updates. Renamed from "Software and Data Integrity Failures" in 2021 (changed "and" to "or").

### Python-Specific Risks

- `pickle.loads()` on untrusted data — arbitrary code execution
- `yaml.load()` without `SafeLoader` — arbitrary code execution
- `jsonpickle.decode()` on untrusted input — code execution via object reconstruction
- Unsigned packages or pip installs without hash verification
- CI/CD pipeline injection via unvalidated pull request triggers

### Dangerous Deserialization

```python
import pickle
import yaml

# VULNERABLE — arbitrary code execution
data = pickle.loads(untrusted_bytes)     # RCE
data = yaml.load(untrusted_string)       # RCE (PyYAML < 6.0 default)
data = yaml.load(untrusted_string, Loader=yaml.FullLoader)  # Still risky

import jsonpickle
obj = jsonpickle.decode(untrusted_json)  # RCE

import shelve
db = shelve.open("data.db")             # Uses pickle internally
```

### Secure Alternatives

```python
import json
import yaml

# SECURE — use safe formats and explicit schemas
data = json.loads(untrusted_string)  # No code execution possible
data = yaml.safe_load(untrusted_string)  # SafeLoader only

# Structured deserialization with Pydantic
from pydantic import BaseModel, EmailStr

class UserInput(BaseModel):
    name: str
    email: EmailStr
```

### Mitigation Strategies

- Never use `pickle`, `shelve`, `marshal`, or `jsonpickle` with untrusted data
- Always use `yaml.safe_load()` — never `yaml.load()` with untrusted input
- Use `json` for data interchange; use Pydantic or Marshmallow for validation
- Verify dependency integrity with hash pinning (`--require-hashes`)
- Sign artifacts and verify signatures in deployment pipelines

---

## A09: Security Logging and Alerting Failures

Insufficient logging, alerting, and active response capabilities, preventing detection of and response to breaches and attacks. Renamed from "Security Logging and Monitoring Failures" in 2021 to emphasize active alerting, honeytokens, and incident playbooks over passive monitoring.

### Python-Specific Risks

- Using `print()` instead of `logging` module
- Logging sensitive data: passwords, tokens, API keys, PII
- Log injection via unsanitized user input in log messages
- No logging of authentication events or access control failures
- Missing centralized log aggregation, alerting, and honeytokens

### Logging Guidelines

**Log**: authentication events, authorization failures, input validation failures, system events, administrative actions.

**Never log**: passwords, session/JWT/API tokens, credit card numbers, SSNs, PII, or full request bodies with sensitive data.

### Log Injection Prevention

```python
import logging

# VULNERABLE — user input directly in log format string
logger.info(f"Login attempt for user: {username}")
# Attacker input: "admin\n2024-01-01 INFO Login successful for user: admin"

# SECURE — use logging parameters (processed by formatter, not string interpolation)
logger.info("Login attempt for user: %s", username)

# Sanitize for structured logging
def sanitize_log_value(value: str) -> str:
    return value.replace("\n", "\\n").replace("\r", "\\r")

logger.info("Login attempt for user: %s", sanitize_log_value(username))
```

### Structured Logging and Alerting

```python
# Structured JSON logging
import structlog
logger = structlog.get_logger()
logger.info("auth.login_success", user_id=user.id, ip=request.remote_addr)

# Alert on security events
def alert_on_brute_force(user_id: str, failed_count: int):
    if failed_count >= 5:
        logger.critical(
            "security.brute_force_detected",
            user_id=user_id,
            failed_attempts=failed_count,
            action="account_locked",
        )
```

### Mitigation Strategies

- Use Python `logging` module with appropriate levels — never bare `print()`
- Log security events: authentication, authorization, validation failures
- Scrub sensitive data before logging; use allowlists for loggable fields
- Use parameterized logging (`%s`) — avoid f-strings in log calls
- Implement structured logging (JSON) for machine-parseable output
- Aggregate logs centrally; set up automated alerts for anomalous patterns
- Deploy honeytokens and canary values to detect breaches
- Define incident response playbooks for common security alert types
- Monitor for: repeated auth failures, privilege escalation, unusual access patterns

---

## A10: Mishandling of Exceptional Conditions

**New in 2025.** Improper error handling, failing open instead of closed, uncaught exceptions, resource leaks, sensitive information in error messages, missing parameter handling, race conditions from error states, and transaction rollback failures. SSRF (previously A10:2021) moved to A01.

### Python-Specific Risks

- Bare `except:` or `except Exception: pass` that swallow errors silently
- Failing open instead of closed when errors occur
- Not rolling back database transactions on error
- Resource leaks when exceptions bypass cleanup (files, connections, locks)
- Exposing tracebacks and internal details in production error responses
- Using `assert` for error handling (stripped by `python -O`)
- Race conditions introduced by partially completed operations on error

### Related CWEs

CWE-209 (sensitive error messages), CWE-248 (uncaught exception), CWE-390 (error without action), CWE-396 (generic exception catch), CWE-636 (failing open).

### Vulnerable Code — Swallowing Errors

```python
# VULNERABLE — bare except swallows all errors including SystemExit, KeyboardInterrupt
try:
    result = process_payment(order)
except:
    pass  # Payment failure silently ignored — order proceeds unpaid

# VULNERABLE — catching Exception too broadly
try:
    user = authenticate(credentials)
except Exception:
    user = AnonymousUser()  # Failing OPEN — auth error grants access

# VULNERABLE — assert stripped by python -O
def withdraw(account, amount):
    assert amount > 0, "Amount must be positive"  # Removed in optimized mode
    assert account.balance >= amount, "Insufficient funds"
    account.balance -= amount
```

### Secure Code — Specific Exception Handling

```python
# SECURE — catch specific exceptions, fail closed
try:
    result = process_payment(order)
except PaymentDeclinedError:
    logger.warning("Payment declined for order %s", order.id)
    order.status = "payment_failed"
    raise
except PaymentGatewayError as e:
    logger.error("Payment gateway error for order %s: %s", order.id, e)
    order.status = "payment_pending"
    raise

# SECURE — fail closed on auth errors
try:
    user = authenticate(credentials)
except AuthenticationError:
    logger.warning("Authentication failed for %s", credentials.username)
    raise HTTPException(status_code=401, detail="Authentication failed")
except Exception:
    logger.exception("Unexpected error during authentication")
    raise HTTPException(status_code=500, detail="Internal server error")

# SECURE — explicit validation instead of assert
def withdraw(account, amount):
    if amount <= 0:
        raise ValueError("Amount must be positive")
    if account.balance < amount:
        raise InsufficientFundsError(f"Balance {account.balance} < {amount}")
    account.balance -= amount
```

### Vulnerable Code — Resource Leaks and Transaction Failures

```python
# VULNERABLE — resource leak on exception
def process_file(path):
    f = open(path)
    data = json.load(f)  # If this raises, file handle leaks
    f.close()
    return data

# VULNERABLE — transaction not rolled back on error
def transfer_funds(from_acct, to_acct, amount):
    from_acct.balance -= amount
    db.session.flush()
    # If next line raises, from_acct is debited but to_acct is not credited
    to_acct.balance += amount
    db.session.commit()

# VULNERABLE — sensitive info in error response
@app.errorhandler(Exception)
def handle_error(e):
    return jsonify({
        "error": str(e),
        "traceback": traceback.format_exc(),  # Exposes internals
        "db_url": app.config["SQLALCHEMY_DATABASE_URI"],  # Credential leak
    }), 500
```

### Secure Code — Resource Management and Transactions

```python
# SECURE — context manager ensures cleanup
def process_file(path):
    with open(path) as f:
        return json.load(f)

# SECURE — transaction with proper rollback
def transfer_funds(from_acct, to_acct, amount):
    try:
        from_acct.balance -= amount
        to_acct.balance += amount
        db.session.commit()
    except Exception:
        db.session.rollback()
        logger.exception("Transfer failed: %s -> %s, amount=%s", from_acct.id, to_acct.id, amount)
        raise

# Or use nested transaction context
def transfer_funds(from_acct, to_acct, amount):
    with db.session.begin_nested():
        from_acct.balance -= amount
        to_acct.balance += amount
    db.session.commit()

# SECURE — sanitized error response
@app.errorhandler(Exception)
def handle_error(e):
    logger.exception("Unhandled exception")  # Full details in server logs only
    return jsonify({"error": "Internal server error"}), 500
```

### Global Exception Middleware

```python
# FastAPI — centralized exception handling
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error"},
    )
```

### Mitigation Strategies

- Catch specific exceptions; fail closed on unexpected errors
- Use context managers (`with` statement) for all resource management
- Roll back database transactions on error — use `try/except/rollback` or `begin_nested()`
- Implement centralized error handlers and global exception middleware
- Never expose tracebacks or internal details in production error responses
- Use explicit validation (`if`/`raise`) instead of `assert` for error handling
- Log full exception details server-side; return generic messages to clients
- Test error paths: verify that failures leave the system in a consistent state
