---
name: api-security
description: >-
  Guideline for designing, implementing, and verifying secure APIs following
  OWASP API Security Top 10 (2023) best practices. Use when the user wants to:
  (1) review API code or design for security vulnerabilities, (2) design a
  secure REST, GraphQL, or gRPC API architecture, (3) implement API
  authentication and authorization (OAuth2, JWT, API keys, mTLS), (4) configure
  rate limiting, input validation, or CORS, (5) audit API endpoints for BOLA,
  BFLA, or mass assignment vulnerabilities, (6) create API security checklists
  or verification plans, (7) fix API security bugs or harden existing APIs,
  (8) set up API security testing (OWASP ZAP, Schemathesis, Burp Suite), or
  (9) handle any API security concern including SSRF prevention, resource
  consumption limits, business flow protection, API inventory management, and
  secure third-party API consumption.
---

# API Security Development Guide

Structured approach to building secure APIs, covering OWASP API Security Top 10 (2023), secure design patterns, and verification checklists. Apply these guidelines throughout the API development lifecycle — from threat modeling to deployment monitoring.

## Secure API Development Lifecycle

### Phase 1: API Threat Modeling and Design

- Identify API attack surfaces: public endpoints, authenticated endpoints, admin endpoints, webhooks, third-party integrations
- Map data flows: what sensitive data crosses each API boundary
- Define authorization model: which users/roles access which resources and properties
- Design security controls:
  - Centralized authentication (OAuth2/OIDC at API gateway)
  - Object-level authorization at data access layer
  - Schema-based input validation at every endpoint
  - Rate limiting per endpoint sensitivity
  - API versioning with deprecation strategy

### Phase 2: Secure Implementation

#### Critical API Security Rules

| Never | Instead |
|-------|---------|
| Return full objects (to_dict/to_json) | Explicit response schemas with cherry-picked fields |
| Accept arbitrary fields for update | Allowlisted update schemas (prevent mass assignment) |
| Use sequential/guessable IDs in URLs | UUIDs/GUIDs for resource identifiers |
| Trust object ID alone for access | Check object ownership against authenticated user |
| Rely on client-side role checks | Server-side RBAC/ABAC middleware |
| Accept unlimited query params/body | Schema validation with size/type/range limits |
| Skip rate limiting on any endpoint | Rate limit ALL endpoints, stricter on auth/business flows |
| Return stack traces in errors | RFC 7807 Problem Details with generic messages |
| Trust third-party API responses | Validate and sanitize all external API data |
| Put API keys in URLs | Use Authorization header or secure key vault |
| Use wildcard CORS with credentials | Explicit origin allowlist |
| Allow unlimited GraphQL depth/complexity | Query depth + complexity + batch limits |

Reference detailed guides:

- For OWASP API Top 10 with code examples: See [references/owasp-api-top-10.md](references/owasp-api-top-10.md)
- For secure API design patterns: See [references/secure-api-design.md](references/secure-api-design.md)

### Phase 3: API Security Verification

1. **Schema Validation** — Lint OpenAPI spec for security issues (Spectral)
2. **Static Analysis** — Run SAST on API code (Semgrep, bandit)
3. **Contract Testing** — Verify API behavior matches spec (Schemathesis, Dredd)
4. **Dynamic Testing** — Run DAST against running API (OWASP ZAP, Burp Suite)
5. **Authorization Testing** — Test every endpoint with wrong user/role/anonymous
6. **Rate Limit Testing** — Verify all endpoints enforce limits
7. **Code Review** — Apply API security checklists

Reference: See [references/api-security-checklist.md](references/api-security-checklist.md)

### Phase 4: Deployment and Monitoring

- API gateway: auth offloading, rate limiting, request logging
- TLS 1.2+ enforcement, HSTS, security headers
- Structured logging (no tokens/PII in logs)
- Anomaly detection and alerting on security events
- API inventory management and version deprecation
- Incident response plan for API breaches

## OWASP API Security Top 10 (2023) Quick Reference

| # | Risk | Key Concern | Primary Prevention |
|---|------|------------|-------------------|
| API1 | Broken Object Level Authorization | Accessing other users' resources by manipulating IDs | Object ownership check at data layer, use GUIDs |
| API2 | Broken Authentication | Weak auth, credential stuffing, JWT flaws | OAuth2/OIDC, short-lived tokens, rate limit auth |
| API3 | Broken Object Property Level Authorization | Excessive data exposure + mass assignment | Explicit response/request schemas, field allowlists |
| API4 | Unrestricted Resource Consumption | No rate/size/cost limits, GraphQL batching | Rate limiting, pagination caps, spending alerts |
| API5 | Broken Function Level Authorization | Regular users accessing admin functions | RBAC middleware, deny by default, test all roles |
| API6 | Unrestricted Access to Sensitive Business Flows | Automating business-critical operations (scalping, spam) | CAPTCHA, device fingerprinting, behavior analysis |
| API7 | Server Side Request Forgery | API fetches user-supplied URLs | URL allowlisting, block private IPs, disable redirects |
| API8 | Security Misconfiguration | Missing headers, CORS *, verbose errors, debug endpoints | Hardened defaults, security headers, minimal errors |
| API9 | Improper Inventory Management | Shadow APIs, deprecated versions, no documentation | API inventory, OpenAPI in CI/CD, retirement plans |
| API10 | Unsafe Consumption of APIs | Trusting third-party API data without validation | Validate all external data, enforce TLS, set timeouts |

For detailed attack scenarios and code examples: See [references/owasp-api-top-10.md](references/owasp-api-top-10.md)

## API Security Review Workflow

Step-by-step procedure for reviewing API security:

1. **Map the API surface** — List all endpoints, methods, auth requirements, and data flows. Check for undocumented/shadow endpoints.
2. **Check authentication** — Verify every non-public endpoint requires valid authentication. Test with missing/expired/malformed tokens.
3. **Check object-level authorization (BOLA)** — For every endpoint accepting resource IDs, verify users can only access their own resources.
4. **Check function-level authorization (BFLA)** — Verify admin endpoints reject non-admin users. Test horizontal and vertical privilege escalation.
5. **Check property-level authorization** — Verify responses only include authorized fields. Test mass assignment by sending extra fields in updates.
6. **Validate input handling** — Check schema validation on all inputs. Test with oversized payloads, unexpected types, injection payloads.
7. **Check rate limiting** — Verify limits on all endpoints, especially auth, business-critical, and resource-intensive operations.
8. **Check error handling** — Verify no sensitive info in error responses. Test with invalid inputs, missing resources, server errors.
9. **Review third-party integrations** — Verify external API responses are validated. Check for SSRF in URL-accepting endpoints.
10. **Check API inventory** — Verify no deprecated/shadow endpoints are live. Check documentation matches reality.
11. **Report findings** — Severity (Critical/High/Medium/Low), endpoint, vulnerable request, explanation, fix with code example.

## API Security Testing Quick Commands

```bash
# === OpenAPI Spec Linting ===
npm install -g @stoplight/spectral-cli && spectral lint openapi.yaml

# === Property-based API Testing ===
pip install schemathesis && schemathesis run --checks all http://localhost:8000/openapi.json

# === Dynamic Security Scanning ===
docker run -t ghcr.io/zaproxy/zaproxy:stable zap-api-scan.py -t http://target:8000/openapi.json -f openapi

# === API Fuzzing ===
# nuclei -u http://target:8000 -t api/

# === Static Analysis (Python API) ===
pip install bandit && bandit -r src/ -f json
pip install semgrep && semgrep --config=p/python --config=p/owasp-top-ten src/
```

## Reference Files

- **[references/owasp-api-top-10.md](references/owasp-api-top-10.md)** — Detailed OWASP API Security Top 10 (2023) with attack scenarios, vulnerable → secure code examples for REST and GraphQL APIs
- **[references/secure-api-design.md](references/secure-api-design.md)** — Secure API design patterns: authentication (OAuth2, JWT, API keys, mTLS), authorization (RBAC/ABAC), input validation, rate limiting, CORS, error handling, API gateway, monitoring
- **[references/api-security-checklist.md](references/api-security-checklist.md)** — Actionable checklists for API design review, auth, input validation, transport security, rate limiting, inventory, deployment, logging, and testing
