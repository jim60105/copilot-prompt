# Secure API Design Patterns Reference

> Reference for AI agents implementing secure API design across REST, GraphQL, and gRPC.

## Table of Contents

- [1. Authentication Patterns](#1-authentication-patterns)
- [2. Authorization Patterns](#2-authorization-patterns)
- [3. Input Validation and Data Sanitization](#3-input-validation-and-data-sanitization)
- [4. Rate Limiting and Throttling](#4-rate-limiting-and-throttling)
- [5. API Gateway and Edge Security](#5-api-gateway-and-edge-security)
- [6. CORS and Cross-Origin Security](#6-cors-and-cross-origin-security)
- [7. Error Handling and Information Disclosure](#7-error-handling-and-information-disclosure)
- [8. API Documentation and OpenAPI Security](#8-api-documentation-and-openapi-security)
- [9. Transport and Data Security](#9-transport-and-data-security)
- [10. Logging, Monitoring, and Incident Response](#10-logging-monitoring-and-incident-response)

---

## 1. Authentication Patterns

Verify the identity of every API caller using cryptographically sound mechanisms. Never roll custom authentication; use proven protocols and libraries.

### OAuth 2.0 Flows

Use Authorization Code + PKCE for SPAs and mobile apps. Use Client Credentials for machine-to-machine (M2M) communication.

**Anti-pattern — Implicit flow (deprecated, token in URL fragment):**

```
GET /authorize?response_type=token&client_id=app123&redirect_uri=https://app.example.com/callback
# Token exposed in browser history, referrer headers, and logs
```

**Correct — Authorization Code + PKCE:**

```python
# FastAPI OAuth2 with PKCE verification
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2AuthorizationCodeBearer

oauth2_scheme = OAuth2AuthorizationCodeBearer(
    authorizationUrl="/authorize",
    tokenUrl="/token",
    scopes={"read": "Read access", "write": "Write access"},
)

async def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)  # Validate signature, exp, aud, iss
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload
```

```javascript
// Express passport OAuth2 config
const passport = require("passport");
const { Strategy } = require("passport-oauth2");

passport.use(
  new Strategy(
    {
      authorizationURL: "https://auth.example.com/authorize",
      tokenURL: "https://auth.example.com/token",
      clientID: process.env.CLIENT_ID,
      clientSecret: process.env.CLIENT_SECRET,
      callbackURL: "/callback",
      pkce: true,
      state: true, // CSRF protection
    },
    (accessToken, refreshToken, profile, done) => {
      return done(null, profile);
    }
  )
);
```

### JWT Best Practices

**Anti-pattern — No algorithm validation:**

```python
# DANGEROUS: Accepts any algorithm, including "none"
payload = jwt.decode(token, SECRET_KEY)
```

**Correct — Strict JWT validation:**

```python
from jwt import decode, InvalidTokenError

ALLOWED_ALGORITHMS = ["RS256", "ES256"]  # Asymmetric only

def verify_token(token: str) -> dict:
    try:
        return decode(
            token,
            PUBLIC_KEY,
            algorithms=ALLOWED_ALGORITHMS,  # Explicit allowlist
            audience="https://api.example.com",
            issuer="https://auth.example.com",
            options={
                "require": ["exp", "iat", "aud", "iss", "sub"],
                "verify_exp": True,
            },
        )
    except InvalidTokenError:
        return None
```

**Key rules:**

- Set access token expiry to 5–15 minutes; use refresh tokens for longer sessions
- Enforce algorithm allowlist — never accept `"none"` or `HS256` with public keys
- Validate `aud`, `iss`, `exp`, `iat`, and `sub` on every request
- Implement refresh token rotation: invalidate the old token when issuing a new one
- Store refresh tokens hashed in the database; detect reuse to revoke token families

### API Key Management

**Anti-pattern — API key in URL:**

```
GET /api/data?api_key=sk_live_abc123
# Key logged in access logs, browser history, referrer headers
```

**Correct — Key in header, stored hashed:**

```python
import hashlib, secrets

def generate_api_key() -> tuple[str, str]:
    raw_key = secrets.token_urlsafe(32)
    hashed = hashlib.sha256(raw_key.encode()).hexdigest()
    return raw_key, hashed  # Return raw to user once; store hashed

def verify_api_key(provided_key: str, stored_hash: str) -> bool:
    return hashlib.sha256(provided_key.encode()).hexdigest() == stored_hash
```

```http
# Client sends key in header
GET /api/data HTTP/1.1
X-API-Key: sk_live_abc123
```

**Key rules:**

- Never transmit API keys in URLs or query parameters
- Hash keys at rest (SHA-256 minimum); only show the full key once at creation
- Scope keys to specific endpoints, methods, and IP ranges
- Implement key rotation with grace periods (old key valid for 24–72 hours)
- Log key usage but never log the key value itself

### mTLS for Service-to-Service

Use mutual TLS when services must prove identity to each other. Validate client certificates against an internal CA.

### Session-Based vs Token-Based

- Use token-based (JWT/OAuth2) for stateless APIs, microservices, and mobile clients
- Use session-based for server-rendered apps with tight session control needs
- Never store JWTs in localStorage; use httpOnly, secure, sameSite cookies if browser-based

### Multi-Factor Authentication

Require MFA step-up for sensitive operations (fund transfers, role changes, PII export). Issue short-lived, narrowly scoped tokens after MFA verification.

---

## 2. Authorization Patterns

Enforce access control on every request at object, function, and property levels. Never rely on client-side enforcement or security through obscurity.

### RBAC vs ABAC vs ReBAC

| Model | Use When | Example |
|-------|----------|---------|
| RBAC  | Simple role hierarchies | `admin`, `editor`, `viewer` |
| ABAC  | Context-dependent policies | "Allow if user.department == resource.department AND time < 17:00" |
| ReBAC | Relationship-driven access | "Allow if user is member of resource's parent org" |

### Object-Level Authorization (BOLA Prevention)

**Anti-pattern — No ownership check:**

```python
@app.get("/api/orders/{order_id}")
async def get_order(order_id: int):
    return db.query(Order).filter(Order.id == order_id).first()
    # Any authenticated user can access any order
```

**Correct — Enforce ownership:**

```python
@app.get("/api/orders/{order_id}")
async def get_order(order_id: int, user: User = Depends(get_current_user)):
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == user.id  # Scoped to requesting user
    ).first()
    if not order:
        raise HTTPException(status_code=404)  # 404, not 403 — prevent enumeration
    return order
```

### Function-Level Authorization (BFLA Prevention)

**Anti-pattern — UI-only restriction:**

```javascript
// Client hides admin button, but endpoint is unprotected
app.delete("/api/users/:id", async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.sendStatus(204);
});
```

**Correct — Middleware-enforced authorization:**

```javascript
const requireRole = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.role)) {
    return res.status(403).json({ error: "Insufficient permissions" });
  }
  next();
};

app.delete("/api/users/:id", requireRole("admin"), async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.sendStatus(204);
});
```

### Property-Level Authorization

**Anti-pattern — Mass assignment:**

```python
@app.put("/api/users/{user_id}")
async def update_user(user_id: int, data: dict):
    db.query(User).filter(User.id == user_id).update(data)
    # Client can set is_admin=true, role="superuser", etc.
```

**Correct — Explicit allowed fields with response filtering:**

```python
from pydantic import BaseModel

class UserUpdateRequest(BaseModel):
    display_name: str | None = None
    email: str | None = None
    # is_admin, role NOT included — cannot be set

class UserPublicResponse(BaseModel):
    id: int
    display_name: str
    email: str
    # ssn, password_hash NOT included — cannot be leaked

@app.put("/api/users/{user_id}", response_model=UserPublicResponse)
async def update_user(user_id: int, data: UserUpdateRequest, user=Depends(get_current_user)):
    if user_id != user.id:
        raise HTTPException(status_code=404)
    db.query(User).filter(User.id == user_id).update(data.model_dump(exclude_unset=True))
```

### Policy Engines

Use external policy engines for complex authorization:

```rego
# OPA/Rego policy example
package api.authz

default allow := false

allow if {
    input.method == "GET"
    input.path == ["api", "orders", order_id]
    data.orders[order_id].owner == input.user.id
}
```

**Key rules:**

- Apply authorization checks server-side on every request — never trust client-side gating
- Return 404 (not 403) for resources the user should not know exist
- Use allowlist for writable/readable fields per role — never blocklist
- Centralize policy logic; avoid scattering authorization checks across handlers
- Audit and test authorization with automated integration tests per role

---

## 3. Input Validation and Data Sanitization

Validate all input at the API boundary using strict schemas. Reject anything that does not match the expected shape, type, and range.

### Schema Validation

**Anti-pattern — No validation, raw request body:**

```python
@app.post("/api/items")
async def create_item(request: Request):
    data = await request.json()  # Arbitrary keys, types, sizes
    db.insert(data)
```

**Correct — Pydantic schema enforcement (FastAPI):**

```python
from pydantic import BaseModel, Field, field_validator
import re

class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    price: float = Field(..., gt=0, le=1_000_000)
    category: str = Field(..., pattern=r"^[a-z_]+$")

    @field_validator("name")
    @classmethod
    def sanitize_name(cls, v: str) -> str:
        if re.search(r"[<>\"';]", v):
            raise ValueError("Invalid characters in name")
        return v.strip()

@app.post("/api/items", status_code=201)
async def create_item(item: ItemCreate):
    return db.insert(item.model_dump())
```

**Correct — Zod validation (Express):**

```javascript
const { z } = require("zod");

const ItemSchema = z.object({
  name: z.string().min(1).max(200),
  price: z.number().positive().max(1_000_000),
  category: z.string().regex(/^[a-z_]+$/),
});

app.post("/api/items", (req, res) => {
  const result = ItemSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({ errors: result.error.issues });
  }
  db.insert(result.data);
  res.status(201).json(result.data);
});
```

### Content-Type Enforcement

**Anti-pattern — Accept any content type:**

```python
# No Content-Type check — vulnerable to XXE, SSRF via XML payloads
```

**Correct — Reject unexpected content types:**

```python
from fastapi import Request, HTTPException

@app.middleware("http")
async def enforce_content_type(request: Request, call_next):
    if request.method in ("POST", "PUT", "PATCH"):
        content_type = request.headers.get("content-type", "")
        if not content_type.startswith("application/json"):
            raise HTTPException(status_code=415, detail="Unsupported Media Type")
    return await call_next(request)
```

### Request Body Size Limits

```python
# FastAPI / Starlette
app = FastAPI()
app.add_middleware(
    TrustedHostMiddleware, allowed_hosts=["api.example.com"]
)
# Set via reverse proxy (nginx: client_max_body_size 1m;)
```

```javascript
// Express
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ limit: "1mb", extended: false }));
```

### GraphQL-Specific Validation

**Anti-pattern — Unbounded query depth:**

```graphql
# Malicious deeply nested query
query {
  user { orders { items { reviews { author { orders { items { ... } } } } } } }
}
```

**Correct — Depth and complexity limits:**

```javascript
const depthLimit = require("graphql-depth-limit");
const { createComplexityLimitRule } = require("graphql-validation-complexity");

const server = new ApolloServer({
  schema,
  validationRules: [
    depthLimit(5),
    createComplexityLimitRule(1000),
  ],
  introspection: process.env.NODE_ENV !== "production", // Disable in production
});
```

### File Upload Security

```python
import magic

ALLOWED_MIME_TYPES = {"image/png", "image/jpeg", "application/pdf"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

async def validate_upload(file: UploadFile):
    if file.size > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="File too large")
    content = await file.read(2048)
    mime = magic.from_buffer(content, mime=True)
    if mime not in ALLOWED_MIME_TYPES:
        raise HTTPException(status_code=422, detail="Invalid file type")
    await file.seek(0)
    # Send to malware scanner before storing
```

**Key rules:**

- Validate on the server side even if the client validates
- Use allowlists for types, ranges, and patterns — never blocklists
- Enforce `Content-Type` headers; reject unexpected media types
- Set request body size limits at both application and reverse proxy layers
- For GraphQL: limit query depth (≤5), complexity (≤1000), and disable introspection in production
- Validate file uploads by magic bytes, not file extension
- Prevent parameter pollution: use first-value-wins or reject duplicates

---

## 4. Rate Limiting and Throttling

Protect APIs from abuse, brute force, and resource exhaustion by limiting request rates per identity and per resource.

### Rate Limit Strategies

| Strategy       | Behavior | Best For |
|----------------|----------|----------|
| Fixed Window   | Reset counter at interval boundary | Simple, low-overhead |
| Sliding Window | Weighted average of current + previous window | Smoother distribution |
| Token Bucket   | Tokens refill at steady rate; allows bursts | Bursty traffic |
| Leaky Bucket   | Requests processed at constant rate | Strict throughput control |

### Implementation

**Anti-pattern — No rate limiting:**

```python
@app.post("/api/login")
async def login(creds: LoginRequest):
    # No limit — vulnerable to credential stuffing
    return authenticate(creds)
```

**Correct — Redis-based sliding window (FastAPI with slowapi):**

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/api/login")
@limiter.limit("5/minute")  # 5 attempts per minute per IP
async def login(request: Request, creds: LoginRequest):
    return authenticate(creds)

@app.get("/api/data")
@limiter.limit("100/minute")  # General endpoint
async def get_data(request: Request, user=Depends(get_current_user)):
    return fetch_data(user)
```

**Correct — Express rate limiter:**

```javascript
const rateLimit = require("express-rate-limit");
const RedisStore = require("rate-limit-redis");
const Redis = require("ioredis");

const loginLimiter = rateLimit({
  store: new RedisStore({ sendCommand: (...args) => redisClient.call(...args) }),
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: true, // X-RateLimit-Limit, X-RateLimit-Remaining
  legacyHeaders: false,
  message: { error: "Too many login attempts, try again later" },
  keyGenerator: (req) => req.ip,
});

app.post("/api/login", loginLimiter, loginHandler);
```

### Rate Limit Headers

Always include standard rate limit headers in responses:

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1699900000
Retry-After: 30  # Include on 429 responses
```

### GraphQL Cost-Based Rate Limiting

Assign cost to operations instead of counting raw requests:

```javascript
const costMap = {
  Query: { users: { complexity: 10 }, user: { complexity: 1 } },
  User: { orders: { complexity: 5 } },
};
// Budget: 1000 points per minute per user
```

**Key rules:**

- Apply stricter limits to authentication endpoints (5–10/minute)
- Use per-user limits for authenticated endpoints; per-IP for unauthenticated
- Return `429 Too Many Requests` with `Retry-After` header
- Use distributed stores (Redis) for rate limiting across multiple instances
- Implement per-endpoint limits — not just global limits
- For GraphQL, use cost-based limiting rather than request counting
- Add anti-automation measures (CAPTCHA, device fingerprinting) for business-critical flows

---

## 5. API Gateway and Edge Security

Offload cross-cutting security concerns to the API gateway. Apply defense-in-depth — never rely solely on the gateway.

### Gateway Responsibilities

```
Client → WAF → API Gateway → Backend Service
              │
              ├── TLS termination
              ├── Authentication (JWT validation)
              ├── Rate limiting
              ├── Request size enforcement
              ├── Request/response logging
              └── Request transformation
```

### API Versioning

Prefer URL path versioning for clarity:

```http
GET /api/v1/users HTTP/1.1
GET /api/v2/users HTTP/1.1
```

Set deprecation timelines and return `Deprecation` and `Sunset` headers:

```http
HTTP/1.1 200 OK
Deprecation: true
Sunset: Sat, 01 Mar 2025 00:00:00 GMT
Link: <https://api.example.com/v2/users>; rel="successor-version"
```

### Circuit Breaker Pattern

Prevent cascading failures when downstream services degrade:

```python
import circuitbreaker

@circuitbreaker.circuit(failure_threshold=5, recovery_timeout=30)
def call_downstream_service(request_data):
    response = httpx.post("https://internal-service/api", json=request_data, timeout=5.0)
    response.raise_for_status()
    return response.json()
```

**Key rules:**

- Terminate TLS at the gateway; use mTLS between gateway and backends
- Validate JWTs at the gateway, but re-validate authorization at the service
- Log all requests at the gateway for audit and anomaly detection
- Use WAF rules to block known attack patterns (SQLi, XSS, path traversal)
- Version all public APIs; communicate deprecation with standard headers
- Implement circuit breakers with sensible timeouts for all downstream calls
- Never expose internal service topology in error messages or headers

---

## 6. CORS and Cross-Origin Security

Configure CORS to allow only known origins. Misconfigured CORS can bypass same-origin protections entirely.

### CORS Configuration

**Anti-pattern — Wildcard with credentials:**

```python
# DANGEROUS: Allows any origin to send credentialed requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
)
```

**Correct — Explicit origin allowlist:**

```python
from fastapi.middleware.cors import CORSMiddleware

ALLOWED_ORIGINS = [
    "https://app.example.com",
    "https://admin.example.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
    max_age=3600,  # Cache preflight for 1 hour
)
```

**Correct — Express CORS:**

```javascript
const cors = require("cors");

const corsOptions = {
  origin: ["https://app.example.com", "https://admin.example.com"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Authorization", "Content-Type"],
  maxAge: 3600,
};

app.use(cors(corsOptions));
```

### CSRF Protection for Cookie-Based APIs

If using cookies for authentication, enforce CSRF tokens:

```javascript
const csrf = require("csurf");

app.use(csrf({ cookie: { httpOnly: true, secure: true, sameSite: "strict" } }));

app.get("/api/csrf-token", (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});
```

**Key rules:**

- Never use `allow_origins=["*"]` with `allow_credentials=True`
- Maintain an explicit allowlist of origins — do not reflect the `Origin` header
- Restrict `allow_methods` and `allow_headers` to what is actually needed
- Set `Access-Control-Max-Age` (3600s recommended) to reduce preflight requests
- For cookie-based auth: set `SameSite=Strict` or `Lax`, `Secure`, `HttpOnly`
- Implement CSRF token validation for any state-changing cookie-authenticated request

---

## 7. Error Handling and Information Disclosure

Return consistent, generic error responses. Never leak internal implementation details, stack traces, or database information to clients.

### RFC 7807 Problem Details

**Anti-pattern — Leaking internals:**

```python
@app.exception_handler(Exception)
async def error_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": str(exc),  # "psycopg2.OperationalError: connection to 10.0.1.5:5432 refused"
            "stack": traceback.format_exc(),
            "query": "SELECT * FROM users WHERE id = 42",
        },
    )
```

**Correct — RFC 7807 structured error, no internals:**

```python
import uuid
import logging

logger = logging.getLogger(__name__)

class ProblemDetail(BaseModel):
    type: str = "about:blank"
    title: str
    status: int
    detail: str | None = None
    instance: str | None = None

@app.exception_handler(Exception)
async def error_handler(request: Request, exc: Exception):
    error_id = str(uuid.uuid4())
    logger.error("Unhandled error %s: %s", error_id, exc, exc_info=True)  # Full details in logs only
    return JSONResponse(
        status_code=500,
        content=ProblemDetail(
            type="https://api.example.com/errors/internal",
            title="Internal Server Error",
            detail="An unexpected error occurred. Reference: " + error_id,
            instance=str(request.url.path),
            status=500,
        ).model_dump(),
        media_type="application/problem+json",
    )
```

**Correct — Express centralized error handler:**

```javascript
const { v4: uuidv4 } = require("uuid");

app.use((err, req, res, _next) => {
  const errorId = uuidv4();
  console.error(`Error ${errorId}:`, err); // Full details to logs only

  const status = err.statusCode || 500;
  res.status(status).type("application/problem+json").json({
    type: `https://api.example.com/errors/${status === 500 ? "internal" : "client"}`,
    title: status === 500 ? "Internal Server Error" : err.message,
    status,
    detail: `Reference: ${errorId}`,
    instance: req.originalUrl,
  });
});
```

### Status Code Usage

| Code | Use | Security Note |
|------|-----|---------------|
| 401  | Missing or invalid authentication | Do not distinguish "user not found" vs "wrong password" |
| 403  | Authenticated but not authorized | Only use if the user should know the resource exists |
| 404  | Resource not found OR forbidden (when hiding existence) | Prefer 404 over 403 to prevent enumeration |
| 422  | Validation errors | Return field-level errors for client correction |
| 429  | Rate limited | Include `Retry-After` header |

**Key rules:**

- Return `application/problem+json` content type for all error responses
- Generate a unique error ID per incident; return the ID to the client, log the details server-side
- Never include stack traces, SQL queries, file paths, or server versions in responses
- Use 404 instead of 403 to prevent resource enumeration when appropriate
- Implement fail-closed: on authorization errors or service failures, deny access by default
- Use consistent error response schema across all endpoints

---

## 8. API Documentation and OpenAPI Security

Treat API documentation as a security-sensitive asset. Define security schemes explicitly and control documentation access.

### Security Scheme Definitions

```yaml
# OpenAPI 3.1 security schemes
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    apiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
    oauth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/authorize
          tokenUrl: https://auth.example.com/token
          scopes:
            read:users: Read user data
            write:users: Modify user data

security:
  - bearerAuth: []

paths:
  /api/users:
    get:
      security:
        - oauth2: [read:users]
      responses:
        "401":
          description: Authentication required
        "403":
          description: Insufficient scope
```

### Marking Sensitive Fields

```yaml
components:
  schemas:
    User:
      properties:
        id:
          type: integer
        email:
          type: string
          format: email
          x-sensitive: true  # Custom extension for PII marking
        ssn:
          type: string
          writeOnly: true  # Never returned in responses
          x-sensitive: true
```

**Key rules:**

- Define security schemes in OpenAPI spec for every endpoint
- Disable Swagger UI and OpenAPI spec access in production for internal APIs
- Mark PII and sensitive fields with custom extensions (`x-sensitive`)
- Use `writeOnly` for fields that should never appear in responses
- Maintain an API inventory; track all published endpoints and their security posture
- Set deprecation timelines and remove deprecated endpoints on schedule
- Auto-generate documentation from code to prevent spec drift

---

## 9. Transport and Data Security

Encrypt data in transit and at rest. Validate the integrity of requests and responses across the wire.

### TLS Enforcement

**Anti-pattern — Accepting HTTP:**

```nginx
# No redirect — allows plaintext traffic
server {
    listen 80;
    listen 443 ssl;
}
```

**Correct — Enforce HTTPS with HSTS:**

```nginx
server {
    listen 80;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5:!RC4;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}
```

### Request Signing (Webhook Delivery)

**Anti-pattern — No signature verification:**

```python
@app.post("/webhooks/payment")
async def handle_webhook(request: Request):
    data = await request.json()  # No verification — anyone can send fake events
    process_payment(data)
```

**Correct — HMAC signature verification:**

```python
import hmac
import hashlib

WEBHOOK_SECRET = os.environ["WEBHOOK_SECRET"]

@app.post("/webhooks/payment")
async def handle_webhook(request: Request):
    body = await request.body()
    signature = request.headers.get("X-Signature-256")
    if not signature:
        raise HTTPException(status_code=401, detail="Missing signature")

    expected = "sha256=" + hmac.new(
        WEBHOOK_SECRET.encode(), body, hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(signature, expected):
        raise HTTPException(status_code=401, detail="Invalid signature")

    data = json.loads(body)
    process_payment(data)
```

### PII Handling

```python
from cryptography.fernet import Fernet

FIELD_KEY = Fernet(os.environ["FIELD_ENCRYPTION_KEY"])

class UserRecord:
    def encrypt_pii(self, ssn: str) -> bytes:
        return FIELD_KEY.encrypt(ssn.encode())

    def decrypt_pii(self, encrypted: bytes) -> str:
        return FIELD_KEY.decrypt(encrypted).decode()
```

**Key rules:**

- Enforce TLS 1.2+ on all endpoints; disable TLS 1.0/1.1
- Set HSTS with `max-age ≥ 63072000` (2 years), `includeSubDomains`, and `preload`
- Implement certificate pinning for mobile API clients
- Sign webhooks with HMAC-SHA256; use `hmac.compare_digest` for timing-safe comparison
- Apply field-level encryption for PII (SSN, payment data) at rest
- Follow data minimization: collect and return only the fields necessary for the operation
- Use AWS Signature V4 or similar for signed requests in cloud-to-cloud scenarios

---

## 10. Logging, Monitoring, and Incident Response

Log every API interaction with sufficient detail for security investigation. Never log secrets or PII.

### Structured Request Logging

**Anti-pattern — Logging sensitive data:**

```python
logger.info(f"Login: user={username} password={password} token={token}")
# Credentials and tokens in logs — catastrophic if logs are breached
```

**Correct — Structured logging with redaction:**

```python
import structlog
import time

logger = structlog.get_logger()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    start = time.perf_counter()

    response = await call_next(request)
    duration_ms = (time.perf_counter() - start) * 1000

    logger.info(
        "api_request",
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        duration_ms=round(duration_ms, 2),
        user_id=getattr(request.state, "user_id", None),
        correlation_id=correlation_id,
        ip=request.client.host,
        user_agent=request.headers.get("user-agent"),
        # NEVER log: Authorization header, request body, cookies
    )
    response.headers["X-Correlation-ID"] = correlation_id
    return response
```

**Correct — Express structured logging:**

```javascript
const pino = require("pino");
const logger = pino({ redact: ["req.headers.authorization", "req.headers.cookie"] });

app.use((req, res, next) => {
  const correlationId = req.headers["x-correlation-id"] || uuidv4();
  req.correlationId = correlationId;
  res.setHeader("X-Correlation-ID", correlationId);

  const start = process.hrtime.bigint();
  res.on("finish", () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1e6;
    logger.info({
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      durationMs: Math.round(durationMs * 100) / 100,
      userId: req.user?.id,
      correlationId,
      ip: req.ip,
    });
  });
  next();
});
```

### Audit Trail

Log security-relevant events with immutable, append-only storage:

```python
def audit_log(event: str, user_id: str, resource: str, details: dict):
    logger.info(
        "audit_event",
        event=event,           # "data_access", "role_change", "export_pii"
        user_id=user_id,
        resource=resource,
        details=details,
        timestamp=datetime.utcnow().isoformat(),
    )
```

### Anomaly Detection Signals

Monitor for and alert on:

| Signal | Threshold Example |
|--------|-------------------|
| Auth failures per user | > 10 in 5 minutes |
| 4xx error spike | > 50% increase from baseline |
| Unusual geographic access | New country for existing user |
| Abnormal request volume | > 3x rolling average |
| Sensitive endpoint access | Any access to PII export endpoints |
| Response time degradation | p99 > 2x normal (possible attack) |

**Key rules:**

- Use structured logging (JSON) — never unstructured text
- Never log: passwords, tokens, API keys, session IDs, PII, or full request/response bodies with sensitive content
- Attach correlation IDs (propagated via `X-Correlation-ID` header) across all services
- Implement separate audit logs for data access, modifications, and authentication events
- Set up real-time alerting for auth failure spikes, error rate increases, and unusual access patterns
- Store logs in tamper-evident, append-only storage with retention policies
- Use distributed tracing (OpenTelemetry) for cross-service request tracking
- Review and rotate logging configurations regularly to prevent log injection
