# OWASP API Security Top 10 (2023) — Reference

> Agent reference for secure API development. All 10 categories with vulnerable/secure
> code patterns. Use imperative form. Language-agnostic principles with practical examples.

## Table of Contents

- [API1:2023 — Broken Object Level Authorization (BOLA)](#api12023--broken-object-level-authorization-bola)
- [API2:2023 — Broken Authentication](#api22023--broken-authentication)
- [API3:2023 — Broken Object Property Level Authorization](#api32023--broken-object-property-level-authorization)
- [API4:2023 — Unrestricted Resource Consumption](#api42023--unrestricted-resource-consumption)
- [API5:2023 — Broken Function Level Authorization (BFLA)](#api52023--broken-function-level-authorization-bfla)
- [API6:2023 — Unrestricted Access to Sensitive Business Flows](#api62023--unrestricted-access-to-sensitive-business-flows)
- [API7:2023 — Server Side Request Forgery (SSRF)](#api72023--server-side-request-forgery-ssrf)
- [API8:2023 — Security Misconfiguration](#api82023--security-misconfiguration)
- [API9:2023 — Improper Inventory Management](#api92023--improper-inventory-management)
- [API10:2023 — Unsafe Consumption of APIs](#api102023--unsafe-consumption-of-apis)

---

## API1:2023 — Broken Object Level Authorization (BOLA)

The #1 API security risk. Attackers manipulate object IDs in API requests to access resources
belonging to other users. APIs expose endpoints that handle object identifiers, creating a wide
attack surface for access control issues.

### API-Specific Risks

- Sequential/predictable IDs allow enumeration (`/api/orders/1001`, `/api/orders/1002`)
- Missing ownership checks at data access layer
- GraphQL node queries bypassing REST-layer authorization
- Batch/list endpoints leaking other users' objects
- Nested resource access (`/users/123/documents/456`) skipping parent ownership verification

### Vulnerable Example

```python
# FastAPI — no ownership check
@app.get("/api/orders/{order_id}")
async def get_order(order_id: int):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404)
    return order  # Any authenticated user can access any order
```

```javascript
// Express — no ownership check
app.get("/api/orders/:orderId", authenticate, async (req, res) => {
  const order = await Order.findById(req.params.orderId);
  if (!order) return res.status(404).json({ error: "Not found" });
  res.json(order); // Any authenticated user can access any order
});
```

```graphql
# GraphQL — no ownership check in resolver
query {
  order(id: "order-belonging-to-another-user") {
    id totalAmount items { name price }
  }
}
```

```bash
# Attack: enumerate sequential IDs
curl -H "Authorization: Bearer <user_a_token>" https://api.example.com/api/orders/1001
curl -H "Authorization: Bearer <user_a_token>" https://api.example.com/api/orders/1002
```

### Secure Example

```python
# FastAPI — enforce ownership at data access layer
@app.get("/api/orders/{order_id}")
async def get_order(order_id: uuid.UUID, current_user: User = Depends(get_current_user)):
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == current_user.id  # ownership check
    ).first()
    if not order:
        raise HTTPException(status_code=404)  # 404, not 403 — avoid confirming existence
    return OrderResponse.model_validate(order)
```

```javascript
// Express — enforce ownership
app.get("/api/orders/:orderId", authenticate, async (req, res) => {
  const order = await Order.findOne({
    _id: req.params.orderId,
    userId: req.user.id, // ownership check
  });
  if (!order) return res.status(404).json({ error: "Not found" });
  res.json(order);
});
```

```python
# GraphQL (Strawberry) — ownership in resolver
@strawberry.type
class Query:
    @strawberry.field
    async def order(self, info: Info, id: strawberry.ID) -> Order:
        user = info.context.user
        order = await Order.objects.filter(id=id, user_id=user.id).first()
        if not order:
            raise NotFoundException("Order not found")
        return order
```

### Prevention Strategies

- Enforce authorization checks per object at the data access layer, not at the routing layer
- Use UUIDs/GUIDs instead of sequential integer IDs
- Return `404 Not Found` instead of `403 Forbidden` to avoid confirming resource existence
- Write authorization tests: "User A must not access User B's resources"
- Implement a centralized authorization service or policy engine (OPA, Casbin)
- Add automated BOLA detection in integration tests

---

## API2:2023 — Broken Authentication

Weak or improperly implemented authentication mechanisms allow attackers to assume other users'
identities. APIs are especially vulnerable because authentication tokens are bearer credentials —
whoever holds the token holds the identity.

### API-Specific Risks

- Missing authentication on endpoints (assumed "internal" APIs)
- Weak JWT implementation: no algorithm enforcement, `alg: none` accepted, weak signing secrets
- Long-lived tokens without rotation or revocation
- API keys in URLs (logged in proxies, browser history, referer headers)
- No rate limiting on authentication endpoints enabling credential stuffing
- Credential leakage in client-side code or public repositories

### Vulnerable Example

```python
# Accepting any JWT algorithm — algorithm confusion attack
import jwt

def verify_token(token: str):
    # VULNERABLE: attacker can switch to HS256 using the public RSA key as secret
    payload = jwt.decode(token, PUBLIC_KEY, algorithms=["RS256", "HS256"])
    return payload
```

```javascript
// Express — weak JWT, no expiry check
app.use((req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  // VULNERABLE: no algorithm enforcement, using weak secret
  const payload = jwt.verify(token, "secret123");
  req.user = payload;
  next();
});
```

```bash
# API key leaked in URL — visible in server logs, proxy logs, referer headers
curl "https://api.example.com/data?api_key=sk_live_abc123xyz"
```

### Secure Example

```python
# FastAPI — strict JWT validation with proper configuration
from jose import jwt, JWTError

ALGORITHM = "RS256"  # enforce single algorithm
JWKS_URL = "https://auth.example.com/.well-known/jwks.json"

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    try:
        jwks = await fetch_jwks(JWKS_URL)
        payload = jwt.decode(
            token,
            jwks,
            algorithms=[ALGORITHM],  # strict algorithm enforcement
            audience="https://api.example.com",
            issuer="https://auth.example.com",
        )
        if payload.get("exp", 0) < time.time():
            raise HTTPException(status_code=401, detail="Token expired")
        user = await get_user_by_sub(payload["sub"])
        if not user:
            raise HTTPException(status_code=401)
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

```javascript
// Express — OAuth2 with JWKS validation
const { expressjwt: jwtMiddleware } = require("express-jwt");
const jwksRsa = require("jwks-rsa");

const authenticate = jwtMiddleware({
  secret: jwksRsa.expressJwtSecret({
    jwksUri: "https://auth.example.com/.well-known/jwks.json",
    cache: true,
    rateLimit: true,
  }),
  audience: "https://api.example.com",
  issuer: "https://auth.example.com",
  algorithms: ["RS256"], // strict algorithm enforcement
});
```

```bash
# API key in header, not URL
curl -H "Authorization: Bearer sk_live_abc123xyz" https://api.example.com/data
```

### Prevention Strategies

- Use established auth standards: OAuth 2.0, OpenID Connect
- Enforce a single signing algorithm in JWT validation — never accept `alg: none`
- Use short-lived access tokens (5–15 min) with refresh token rotation
- Send API keys in headers (`Authorization`, `X-API-Key`), never in URLs
- Rate limit authentication endpoints (login, token refresh, password reset)
- Implement token revocation (blocklist or short expiry + refresh)
- Store secrets in environment variables or secret managers, never in code
- Use strong, unique signing secrets (≥256 bits for HMAC, ≥2048-bit RSA)

---

## API3:2023 — Broken Object Property Level Authorization

Combines "Excessive Data Exposure" and "Mass Assignment." APIs expose more object properties
than the client needs, or accept properties the client should not be able to set. This leads to
data leaks and privilege escalation via property manipulation.

### API-Specific Risks

- Returning full database objects via `to_dict()`, `to_json()`, `serialize()`
- Exposing internal fields: `password_hash`, `is_admin`, `internal_notes`, `ssn`
- Mass assignment: accepting arbitrary fields on create/update (e.g., setting `role: "admin"`)
- GraphQL introspection revealing all fields, including sensitive ones

### Vulnerable Example

```python
# Django REST — returning full model object
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = "__all__"  # VULNERABLE: exposes password_hash, is_admin, ssn
```

```python
# Flask — mass assignment via dict unpacking
@app.put("/api/users/<user_id>")
def update_user(user_id):
    user = User.query.get_or_404(user_id)
    data = request.get_json()
    for key, value in data.items():
        setattr(user, key, value)  # VULNERABLE: attacker can set is_admin=True
    db.session.commit()
    return jsonify(user.to_dict())
```

```bash
# Attack: mass assignment — escalate to admin
curl -X PUT https://api.example.com/api/users/me \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "role": "admin", "is_verified": true}'
```

### Secure Example

```python
# FastAPI + Pydantic — explicit response and update schemas
class UserResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    # Exclude: password_hash, is_admin, ssn, internal_notes

class UserUpdate(BaseModel):
    name: str | None = None
    email: str | None = None
    # Only allow specific fields — role, is_admin are excluded

@app.put("/api/users/me", response_model=UserResponse)
async def update_user(
    updates: UserUpdate,
    current_user: User = Depends(get_current_user),
):
    update_data = updates.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    db.commit()
    return UserResponse.model_validate(current_user)
```

```javascript
// Express — allowlisted fields for update and response
const ALLOWED_UPDATE_FIELDS = ["name", "email", "avatar"];
const RESPONSE_FIELDS = ["id", "name", "email", "avatar", "createdAt"];

app.put("/api/users/me", authenticate, async (req, res) => {
  const updates = {};
  for (const field of ALLOWED_UPDATE_FIELDS) {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  }
  const user = await User.findByIdAndUpdate(req.user.id, updates, { new: true })
    .select(RESPONSE_FIELDS.join(" "));
  res.json(user);
});
```

### Prevention Strategies

- Define explicit response schemas — cherry-pick returned fields, never use `fields = "__all__"`
- Define explicit input schemas with allowlisted fields for create/update operations
- Use schema-based validation (Pydantic, marshmallow, Joi, Zod) for both input and output
- Block mass assignment: never spread/unpack request body directly into model updates
- Disable GraphQL introspection in production or restrict to authorized roles
- Review API responses in CI for unintended field exposure

---

## API4:2023 — Unrestricted Resource Consumption

APIs that do not limit resource consumption enable denial-of-service, financial drain, and data
exfiltration via excessive requests. Without rate limits, pagination caps, and complexity controls,
attackers can overwhelm infrastructure or extract large datasets.

### API-Specific Risks

- No rate limiting per user, IP, or endpoint
- Unlimited pagination (`?page_size=999999`) or missing pagination entirely
- No file upload size limits
- GraphQL: unbounded query depth, breadth, and batching
- No spending caps on pay-per-use APIs (SMS, email, AI inference)
- Regex denial of service (ReDoS) via crafted input

### Vulnerable Example

```python
# FastAPI — no pagination limit
@app.get("/api/users")
async def list_users(page_size: int = 10):
    # VULNERABLE: attacker can request page_size=1000000
    return db.query(User).limit(page_size).all()
```

```graphql
# GraphQL — deeply nested query (unbounded depth)
query {
  users {
    friends {
      friends {
        friends {
          friends { id name email }
        }
      }
    }
  }
}
```

```bash
# Attack: request excessive data
curl "https://api.example.com/api/users?page_size=1000000"

# Attack: GraphQL batching — send 1000 queries in one request
curl -X POST https://api.example.com/graphql \
  -H "Content-Type: application/json" \
  -d '[{"query":"{ user(id:1) { email } }"},{"query":"{ user(id:2) { email } }"},...]'
```

### Secure Example

```python
# FastAPI — enforce pagination caps and rate limiting
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

MAX_PAGE_SIZE = 100

@app.get("/api/users")
@limiter.limit("30/minute")
async def list_users(
    request: Request,
    page: int = Query(ge=1, default=1),
    page_size: int = Query(ge=1, le=MAX_PAGE_SIZE, default=20),
):
    offset = (page - 1) * page_size
    users = db.query(User).offset(offset).limit(page_size).all()
    total = db.query(User).count()
    return {
        "data": [UserResponse.model_validate(u) for u in users],
        "pagination": {"page": page, "page_size": page_size, "total": total},
    }
```

```javascript
// Express — rate limiting middleware
const rateLimit = require("express-rate-limit");

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, try again later" },
});

app.use("/api/", apiLimiter);

// Strict pagination
app.get("/api/users", authenticate, async (req, res) => {
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const pageSize = Math.min(100, Math.max(1, parseInt(req.query.page_size) || 20));
  const skip = (page - 1) * pageSize;
  const [users, total] = await Promise.all([
    User.find().skip(skip).limit(pageSize),
    User.countDocuments(),
  ]);
  res.json({ data: users, pagination: { page, pageSize, total } });
});
```

```python
# GraphQL — depth and complexity limiting (Strawberry + graphql-core)
from graphql import validate
from graphql.validation import ASTValidationRule

MAX_DEPTH = 5
MAX_ALIASES = 10

schema = strawberry.Schema(
    query=Query,
    extensions=[
        QueryDepthLimiter(max_depth=MAX_DEPTH),
        MaxAliasesLimiter(max_aliases=MAX_ALIASES),
    ],
)
```

### Prevention Strategies

- Enforce rate limiting per user/IP/API key — use sliding window or token bucket algorithms
- Cap pagination: enforce maximum `page_size` (e.g., 100), require cursor-based pagination for large datasets
- Limit file upload size at the reverse proxy and application layer
- GraphQL: limit query depth (5–7), complexity scoring, disable batching or cap batch size
- Set execution timeouts for API requests (30s max for typical endpoints)
- Implement spending alerts and caps on pay-per-use downstream services
- Use streaming/chunked responses for large payloads

---

## API5:2023 — Broken Function Level Authorization (BFLA)

Attackers access administrative or privileged functions by directly calling API endpoints. APIs
tend to expose more endpoints than web apps, making it critical to enforce function-level
authorization. Relying on client-side UI hiding is insufficient.

### API-Specific Risks

- Regular users accessing admin endpoints (`/api/admin/users`, `DELETE /api/users/{id}`)
- Horizontal escalation: accessing same-level functions of another role
- HTTP method tampering: `GET` allowed but `PUT`/`DELETE` not checked
- Predictable admin URL patterns (`/api/v1/admin/*`, `/api/internal/*`)
- Missing role checks on sensitive operations (delete, export, bulk operations)

### Vulnerable Example

```python
# FastAPI — no role check on admin endpoint
@app.delete("/api/admin/users/{user_id}")
async def delete_user(user_id: uuid.UUID, current_user: User = Depends(get_current_user)):
    # VULNERABLE: any authenticated user can delete users
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404)
    db.delete(user)
    db.commit()
    return {"status": "deleted"}
```

```bash
# Attack: regular user calls admin endpoint
curl -X DELETE https://api.example.com/api/admin/users/some-uuid \
  -H "Authorization: Bearer <regular_user_token>"
```

### Secure Example

```python
# FastAPI — centralized RBAC decorator
from functools import wraps

def require_role(*roles: str):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, current_user: User = Depends(get_current_user), **kwargs):
            if current_user.role not in roles:
                raise HTTPException(status_code=403, detail="Insufficient permissions")
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator

@app.delete("/api/admin/users/{user_id}")
@require_role("admin", "superadmin")
async def delete_user(user_id: uuid.UUID, current_user: User = Depends(get_current_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404)
    db.delete(user)
    db.commit()
    return {"status": "deleted"}
```

```javascript
// Express — role-based middleware
function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: "Insufficient permissions" });
    }
    next();
  };
}

// Apply to admin routes
app.delete("/api/admin/users/:userId", authenticate, requireRole("admin"), async (req, res) => {
  await User.findByIdAndDelete(req.params.userId);
  res.json({ status: "deleted" });
});

// Apply to entire admin router
const adminRouter = express.Router();
adminRouter.use(authenticate, requireRole("admin"));
adminRouter.delete("/users/:userId", deleteUserHandler);
app.use("/api/admin", adminRouter);
```

### Prevention Strategies

- Deny by default: require explicit authorization for every endpoint
- Enforce RBAC or ABAC server-side — never rely on client-side UI hiding
- Centralize authorization logic in middleware or policy engine
- Group admin endpoints under a common prefix with shared auth middleware
- Test authorization with multiple roles: admin, regular user, unauthenticated
- Audit: log all access to privileged functions
- Review: ensure every HTTP method on every route has explicit authorization

---

## API6:2023 — Unrestricted Access to Sensitive Business Flows

Attackers automate access to business-critical flows (purchasing, account creation, referral
programs) to cause harm at scale. This is not a traditional technical vulnerability — it is
business logic abuse through API automation.

### API-Specific Risks

- Ticket/inventory scalping via automated purchasing
- Credential stuffing and account takeover at scale
- Referral/coupon/bonus abuse through automated account creation
- Comment/review spam via API automation
- Mass data scraping exceeding intended use
- Automated bidding or price manipulation

### Vulnerable Example

```python
# FastAPI — purchase endpoint with no anti-automation
@app.post("/api/purchases")
async def purchase_item(
    item_id: uuid.UUID,
    quantity: int,
    current_user: User = Depends(get_current_user),
):
    # VULNERABLE: no per-user rate limit, no CAPTCHA, no device fingerprint
    item = db.query(Item).filter(Item.id == item_id).first()
    if item.stock < quantity:
        raise HTTPException(status_code=400, detail="Out of stock")
    item.stock -= quantity
    order = Order(user_id=current_user.id, item_id=item_id, quantity=quantity)
    db.add(order)
    db.commit()
    return {"order_id": order.id}
```

### Secure Example

```python
# FastAPI — purchase with anti-automation protections
from slowapi import Limiter

limiter = Limiter(key_func=lambda req: req.state.user.id)

@app.post("/api/purchases")
@limiter.limit("5/minute")  # per-user rate limit on purchases
async def purchase_item(
    request: Request,
    purchase: PurchaseRequest,
    current_user: User = Depends(get_current_user),
):
    # Verify CAPTCHA for high-value or suspicious transactions
    if purchase.quantity > 2 or await is_suspicious(current_user):
        await verify_captcha(purchase.captcha_token)

    # Check per-user purchase limits
    recent_purchases = await count_recent_purchases(current_user.id, hours=24)
    if recent_purchases + purchase.quantity > MAX_DAILY_PURCHASE:
        raise HTTPException(status_code=429, detail="Daily purchase limit reached")

    # Device fingerprint validation
    await validate_device_fingerprint(request, current_user)

    item = db.query(Item).with_for_update().filter(Item.id == purchase.item_id).first()
    if item.stock < purchase.quantity:
        raise HTTPException(status_code=400, detail="Out of stock")

    item.stock -= purchase.quantity
    order = Order(user_id=current_user.id, item_id=purchase.item_id, quantity=purchase.quantity)
    db.add(order)
    db.commit()
    return {"order_id": order.id}
```

### Prevention Strategies

- Identify business-critical flows and apply targeted protections
- Rate limit per user per business action (not just per IP)
- Implement CAPTCHA or proof-of-work challenges for sensitive operations
- Use device fingerprinting and behavioral analysis to detect bots
- Set per-user and per-time-window limits on business actions (purchases, signups, referrals)
- Monitor for anomalous patterns: burst activity, headless browser signatures, unusual timing
- Require step-up authentication (MFA) for high-value transactions

---

## API7:2023 — Server Side Request Forgery (SSRF)

APIs that fetch user-supplied URLs without validation allow attackers to make the server send
requests to unintended destinations. Common in webhook handlers, URL preview features, and
file-import-by-URL functionality. Particularly dangerous in cloud environments.

### API-Specific Risks

- Accessing cloud metadata services (`http://169.254.169.254/latest/meta-data/`)
- Scanning internal networks and services via API as proxy
- Reading internal files via `file://` protocol
- Webhook registration pointing to internal services
- URL preview/unfurl features fetching arbitrary URLs
- Bypassing firewalls by making the server initiate the connection

### Vulnerable Example

```python
# FastAPI — webhook URL fetched without validation
import httpx

@app.post("/api/webhooks")
async def register_webhook(url: str, current_user: User = Depends(get_current_user)):
    # VULNERABLE: no URL validation, can access internal services
    response = await httpx.get(url)  # attacker sends url=http://169.254.169.254/latest/meta-data/
    return {"status": "registered", "test_response": response.status_code}
```

```bash
# Attack: access cloud metadata
curl -X POST https://api.example.com/api/webhooks \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"url": "http://169.254.169.254/latest/meta-data/iam/security-credentials/"}'

# Attack: scan internal network
curl -X POST https://api.example.com/api/webhooks \
  -d '{"url": "http://192.168.1.1:8080/admin"}'
```

### Secure Example

```python
# FastAPI — URL validation with allowlist and IP blocking
import ipaddress
from urllib.parse import urlparse
import socket

ALLOWED_SCHEMES = {"https"}
BLOCKED_IP_RANGES = [
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("169.254.0.0/16"),  # link-local / cloud metadata
    ipaddress.ip_network("::1/128"),
]

def validate_url(url: str) -> str:
    parsed = urlparse(url)

    if parsed.scheme not in ALLOWED_SCHEMES:
        raise ValueError(f"Scheme '{parsed.scheme}' not allowed. Use HTTPS.")

    if not parsed.hostname:
        raise ValueError("Invalid URL: no hostname")

    # Resolve hostname to IP and check against blocked ranges
    try:
        resolved_ips = socket.getaddrinfo(parsed.hostname, None)
    except socket.gaierror:
        raise ValueError("Cannot resolve hostname")

    for family, _, _, _, addr in resolved_ips:
        ip = ipaddress.ip_address(addr[0])
        for blocked in BLOCKED_IP_RANGES:
            if ip in blocked:
                raise ValueError(f"URL resolves to blocked IP range")

    return url

@app.post("/api/webhooks")
async def register_webhook(
    webhook: WebhookRequest,
    current_user: User = Depends(get_current_user),
):
    validated_url = validate_url(webhook.url)
    async with httpx.AsyncClient(
        follow_redirects=False,  # prevent redirect-based SSRF bypass
        timeout=5.0,
    ) as client:
        response = await client.get(validated_url)
    return {"status": "registered", "test_response": response.status_code}
```

```javascript
// Express — SSRF protection
const { URL } = require("url");
const dns = require("dns").promises;
const ipRangeCheck = require("ip-range-check");

const BLOCKED_RANGES = [
  "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16",
  "127.0.0.0/8", "169.254.0.0/16", "::1/128",
];

async function validateUrl(urlString) {
  const parsed = new URL(urlString);
  if (parsed.protocol !== "https:") throw new Error("Only HTTPS allowed");

  const { address } = await dns.lookup(parsed.hostname);
  if (ipRangeCheck(address, BLOCKED_RANGES)) {
    throw new Error("URL resolves to blocked IP range");
  }
  return urlString;
}
```

### Prevention Strategies

- Validate and sanitize all user-supplied URLs
- Allowlist URL schemes (`https` only) — block `file://`, `gopher://`, `ftp://`
- Resolve hostnames and verify the resolved IP is not in private/reserved ranges
- Disable HTTP redirects or re-validate the destination after each redirect
- Use a dedicated egress proxy for outbound requests with allowlisted destinations
- Set strict timeouts on outbound requests
- Block access to cloud metadata IPs (`169.254.169.254`) at the network level
- Run webhook/URL-fetching services in isolated network segments

---

## API8:2023 — Security Misconfiguration

Broad category covering misconfigurations at any stack layer: security headers, CORS, error
handling, TLS, debug endpoints, default credentials. APIs are particularly susceptible due to
the many configuration surfaces across API gateways, frameworks, and cloud services.

### API-Specific Risks

- CORS misconfiguration: `Access-Control-Allow-Origin: *` with credentials
- Verbose error messages exposing stack traces, SQL queries, internal paths
- Debug/profiling endpoints left enabled in production
- Default credentials on API gateways, admin panels, databases
- Unnecessary HTTP methods enabled (`TRACE`, `OPTIONS` leaking info)
- Missing security headers (`Strict-Transport-Security`, `X-Content-Type-Options`)
- TLS misconfiguration: outdated protocols, weak cipher suites, missing HSTS
- Permissive Content-Type handling leading to deserialization attacks

### Vulnerable Example

```python
# Flask — verbose errors + wide CORS
from flask_cors import CORS

app = Flask(__name__)
app.config["DEBUG"] = True  # VULNERABLE: debug mode in production
CORS(app, origins="*", supports_credentials=True)  # VULNERABLE: wildcard with credentials

@app.errorhandler(500)
def handle_error(e):
    return jsonify({
        "error": str(e),
        "traceback": traceback.format_exc(),  # VULNERABLE: stack trace exposed
        "sql_query": str(e.statement) if hasattr(e, "statement") else None,
    }), 500
```

```javascript
// Express — no security headers, verbose errors
app.use((err, req, res, next) => {
  // VULNERABLE: full stack trace in production
  res.status(500).json({
    message: err.message,
    stack: err.stack,
    query: err.sql,
  });
});
```

### Secure Example

```python
# Flask — hardened CORS + minimal errors + security headers
from flask_cors import CORS
from flask_talisman import Talisman

app = Flask(__name__)
app.config["DEBUG"] = False

# Strict CORS — explicit origin allowlist
CORS(app, origins=["https://app.example.com"], supports_credentials=True)

# Security headers via Talisman
Talisman(
    app,
    force_https=True,
    strict_transport_security=True,
    strict_transport_security_max_age=31536000,
    content_security_policy={"default-src": "'self'"},
)

@app.errorhandler(500)
def handle_error(e):
    app.logger.error(f"Internal error: {e}", exc_info=True)  # log internally
    return jsonify({"error": "Internal server error"}), 500  # minimal response
```

```javascript
// Express — security headers via helmet, minimal errors
const helmet = require("helmet");

app.use(helmet());
app.use(helmet.hsts({ maxAge: 31536000, includeSubDomains: true, preload: true }));

// CORS — explicit allowlist
const cors = require("cors");
app.use(cors({
  origin: ["https://app.example.com"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));

// Production error handler — no stack traces
app.use((err, req, res, next) => {
  console.error("Internal error:", err);
  res.status(500).json({ error: "Internal server error" });
});
```

```bash
# Verify security headers
curl -I https://api.example.com/api/health
# Expected headers:
# Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# Content-Security-Policy: default-src 'self'
# Cache-Control: no-store
```

### Prevention Strategies

- Disable debug/verbose modes in production — use environment-based configuration
- Configure CORS with explicit origin allowlists — never `*` with credentials
- Return minimal error messages to clients — log full details server-side
- Set security headers: HSTS, X-Content-Type-Options, X-Frame-Options, CSP
- Disable unnecessary HTTP methods (TRACE, CONNECT)
- Remove or protect debug/health/metrics endpoints in production
- Automate security configuration checks in CI/CD (e.g., check-headers, tfsec)
- Rotate default credentials and API gateway keys before deployment
- Enforce TLS 1.2+ with strong cipher suites

---

## API9:2023 — Improper Inventory Management

Organizations lose track of which APIs exist, which versions are running, and what data flows
to third parties. Shadow APIs, deprecated-but-still-running endpoints, and missing documentation
create blind spots that attackers exploit.

### API-Specific Risks

- Shadow APIs: undocumented endpoints deployed by teams without security review
- Zombie APIs: deprecated versions still accessible (`/api/v1/` alongside `/api/v3/`)
- Beta/staging APIs with weaker security controls exposed to the internet
- Missing or outdated API documentation (no OpenAPI spec, stale docs)
- Third-party API integrations without data flow inventory
- Internal APIs accidentally exposed via misconfigured API gateways

### Vulnerable Example

```bash
# Deprecated v1 still running — weaker auth, no rate limiting
curl https://api.example.com/api/v1/users  # no auth required (legacy)
curl https://api.example.com/api/v2/users -H "Authorization: Bearer <token>"  # current

# Staging API accessible publicly
curl https://staging-api.example.com/api/users  # no auth, debug enabled

# Undocumented endpoint found via directory enumeration
curl https://api.example.com/api/internal/debug/dump-config
```

### Secure Example

```python
# FastAPI — versioned API with deprecation headers and OpenAPI docs
from fastapi import FastAPI
from datetime import datetime

app = FastAPI(
    title="Example API",
    version="3.0.0",
    docs_url="/api/v3/docs",
    openapi_url="/api/v3/openapi.json",
)

# Redirect deprecated version with sunset header
@app.api_route("/api/v1/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def deprecated_v1(path: str):
    return JSONResponse(
        status_code=410,
        content={"error": "API v1 has been retired. Use /api/v3/"},
        headers={
            "Sunset": "Sat, 01 Jan 2024 00:00:00 GMT",
            "Deprecation": "true",
            "Link": '</api/v3/>; rel="successor-version"',
        },
    )

# Active version with full security
v3_router = APIRouter(prefix="/api/v3", dependencies=[Depends(authenticate)])
```

```yaml
# CI/CD — validate OpenAPI spec exists and is current
# .github/workflows/api-docs.yml
- name: Validate OpenAPI spec
  run: |
    npx @stoplight/spectral-cli lint openapi.yaml
    # Fail if spec is missing routes that exist in code
    python scripts/check_api_coverage.py --spec openapi.yaml --app app:app
```

```bash
# Set deprecation headers on soon-to-retire endpoints
# Response headers for deprecated endpoint:
Deprecation: true
Sunset: Sat, 01 Jul 2025 00:00:00 GMT
Link: </api/v3/users>; rel="successor-version"
```

### Prevention Strategies

- Maintain a centralized API inventory — track all environments (prod, staging, beta)
- Generate OpenAPI/Swagger specs from code and validate in CI/CD
- Enforce API versioning strategy: URI versioning (`/v3/`), header versioning, or content negotiation
- Set `Sunset` and `Deprecation` headers on deprecated endpoints
- Return `410 Gone` for fully retired API versions — do not silently keep them running
- Restrict staging/beta APIs to internal networks or VPN
- Regularly audit for shadow APIs: scan networks, review API gateway configs, search code repos
- Document all third-party API integrations and data flows
- Require security review for new API endpoints before deployment

---

## API10:2023 — Unsafe Consumption of APIs

APIs that consume data from third-party services without proper validation are vulnerable to
attacks originating from those services. Developers often trust third-party API responses more
than user input, but compromised or malicious upstream APIs can inject payloads.

### API-Specific Risks

- Trusting third-party API response data without validation or sanitization
- Following redirects from external APIs to internal/malicious destinations
- Disabling TLS verification for third-party API calls
- No timeout or resource limits on third-party API consumption
- Storing third-party data without sanitization (XSS, SQL injection via upstream)
- Using third-party SDKs with known vulnerabilities

### Vulnerable Example

```python
# FastAPI — trusting third-party response without validation
import httpx

@app.get("/api/enriched-profile/{user_id}")
async def get_enriched_profile(user_id: uuid.UUID):
    user = db.query(User).filter(User.id == user_id).first()
    # VULNERABLE: no TLS verification, no timeout, no response validation
    response = httpx.get(
        f"https://third-party-api.com/enrich?email={user.email}",
        verify=False,  # VULNERABLE: TLS verification disabled
        follow_redirects=True,  # VULNERABLE: follows redirects blindly
    )
    enrichment = response.json()
    # VULNERABLE: storing unvalidated third-party data directly
    user.company = enrichment.get("company")
    user.title = enrichment.get("title")
    user.bio = enrichment.get("bio")  # could contain XSS payload
    db.commit()
    return user
```

```javascript
// Express — consuming third-party API without validation
app.get("/api/weather/:city", async (req, res) => {
  // VULNERABLE: no input validation, no response validation, no timeout
  const response = await fetch(
    `http://weather-api.com/data?city=${req.params.city}`, // HTTP, not HTTPS
    { redirect: "follow" } // follows redirects blindly
  );
  const data = await response.json();
  // VULNERABLE: passing unvalidated third-party data to client
  res.json({ weather: data });
});
```

### Secure Example

```python
# FastAPI — safe third-party API consumption
import httpx
from pydantic import BaseModel, field_validator
import bleach

class EnrichmentResponse(BaseModel):
    company: str | None = None
    title: str | None = None
    bio: str | None = None

    @field_validator("bio", mode="before")
    @classmethod
    def sanitize_bio(cls, v: str | None) -> str | None:
        if v is None:
            return None
        return bleach.clean(v, tags=[], strip=True)  # strip all HTML

    @field_validator("company", "title", mode="before")
    @classmethod
    def truncate_fields(cls, v: str | None) -> str | None:
        if v is None:
            return None
        return v[:200]  # prevent oversized data storage

@app.get("/api/enriched-profile/{user_id}")
async def get_enriched_profile(
    user_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
):
    user = db.query(User).filter(
        User.id == user_id, User.id == current_user.id
    ).first()
    if not user:
        raise HTTPException(status_code=404)

    async with httpx.AsyncClient(
        verify=True,             # enforce TLS verification
        follow_redirects=False,  # do not follow redirects
        timeout=5.0,             # strict timeout
    ) as client:
        try:
            response = await client.get(
                "https://third-party-api.com/enrich",
                params={"email": user.email},
            )
            response.raise_for_status()
        except httpx.HTTPError:
            raise HTTPException(status_code=502, detail="Upstream service error")

    # Validate response through schema
    enrichment = EnrichmentResponse.model_validate(response.json())
    user.company = enrichment.company
    user.title = enrichment.title
    user.bio = enrichment.bio
    db.commit()
    return UserResponse.model_validate(user)
```

```javascript
// Express — safe third-party consumption
const { z } = require("zod");
const sanitizeHtml = require("sanitize-html");

const WeatherResponseSchema = z.object({
  temperature: z.number(),
  description: z.string().max(200),
  humidity: z.number().min(0).max(100),
});

app.get("/api/weather/:city", authenticate, async (req, res) => {
  const city = req.params.city.replace(/[^a-zA-Z\s-]/g, ""); // sanitize input

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);

  try {
    const response = await fetch(
      `https://weather-api.com/data?city=${encodeURIComponent(city)}`,
      {
        signal: controller.signal,
        redirect: "error", // reject redirects
      }
    );
    clearTimeout(timeout);

    if (!response.ok) throw new Error("Upstream error");

    const raw = await response.json();
    const validated = WeatherResponseSchema.parse(raw); // validate response
    validated.description = sanitizeHtml(validated.description, {
      allowedTags: [], allowedAttributes: {},
    });
    res.json({ weather: validated });
  } catch (err) {
    clearTimeout(timeout);
    res.status(502).json({ error: "Weather service unavailable" });
  }
});
```

### Prevention Strategies

- Validate and sanitize all third-party API response data through strict schemas
- Enforce TLS verification on all outbound requests — never set `verify=False`
- Do not follow redirects from third-party APIs — or re-validate the redirect target
- Set strict timeouts (connect and read) on all outbound HTTP requests
- Sanitize third-party data before storing (strip HTML, truncate, validate types)
- Use circuit breaker patterns for third-party API dependencies
- Pin and audit third-party SDK/library versions for known vulnerabilities
- Log and monitor third-party API interactions for anomalies
- Treat third-party data with the same suspicion as user input

---

## Quick Reference Matrix

| # | Category | Core Issue | Top Fix |
|---|----------|-----------|---------|
| API1 | BOLA | Missing object ownership checks | Enforce ownership at data layer |
| API2 | Broken Auth | Weak token/auth mechanisms | OAuth2 + short-lived tokens |
| API3 | Property Auth | Over-exposed/writable properties | Explicit input/output schemas |
| API4 | Resource Consumption | No rate/size limits | Rate limit + pagination caps |
| API5 | BFLA | Missing function-level auth | RBAC middleware, deny by default |
| API6 | Business Flow Abuse | Automated business logic exploitation | Per-user business action limits |
| API7 | SSRF | Unvalidated URL fetching | URL allowlist + IP range blocking |
| API8 | Misconfiguration | Insecure defaults | Hardened config + security headers |
| API9 | Inventory Mgmt | Unknown/deprecated APIs | API inventory + sunset retired versions |
| API10 | Unsafe Consumption | Trusting third-party data | Validate all upstream responses |
