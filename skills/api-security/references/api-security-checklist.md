# API Security Verification Checklists

> Comprehensive, actionable checklists for securing APIs throughout the development lifecycle.
> Use these checklists during design reviews, code reviews, pre-deployment gates, and periodic audits.
>
> Every item uses imperative form and is independently verifiable.

---

## Table of Contents

- [1. API Design Review Checklist](#1-api-design-review-checklist)
- [2. Authentication and Authorization Checklist](#2-authentication-and-authorization-checklist)
- [3. Input Validation Checklist](#3-input-validation-checklist)
- [4. Transport and Data Security Checklist](#4-transport-and-data-security-checklist)
- [5. Rate Limiting and Resource Protection Checklist](#5-rate-limiting-and-resource-protection-checklist)
- [6. API Inventory and Documentation Checklist](#6-api-inventory-and-documentation-checklist)
- [7. Deployment and Infrastructure Checklist](#7-deployment-and-infrastructure-checklist)
- [8. Logging and Monitoring Checklist](#8-logging-and-monitoring-checklist)
- [9. Testing Security Checklist](#9-testing-security-checklist)
- [10. Security Tools Reference](#10-security-tools-reference)

---

## 1. API Design Review Checklist

Verify these items during API design and specification review, before implementation begins.

### Authentication and Authorization by Design

- [ ] Require authentication on every endpoint (unless explicitly documented as public)
- [ ] Document and justify every public (unauthenticated) endpoint
- [ ] Enforce object-level authorization (BOLA) checks on every endpoint accepting resource IDs
- [ ] Enforce function-level authorization (BFLA) — separate and protect admin endpoints
- [ ] Enforce property-level authorization — explicitly define returned fields in response schemas (prohibit blanket `to_dict()`/`to_json()`)
- [ ] Protect against mass assignment — accept only allowlisted fields on update endpoints
- [ ] Use UUIDs or non-sequential identifiers for resource IDs to reduce enumeration risk

### Request and Response Design

- [ ] Define input validation schema for every endpoint (OpenAPI/JSON Schema)
- [ ] Configure rate limiting per endpoint based on sensitivity
- [ ] Enforce pagination with a defined maximum page size
- [ ] Define file upload limits (size, type, count) for every upload endpoint
- [ ] Standardize error response format (use RFC 7807 Problem Details)
- [ ] Ensure error responses never expose stack traces, internal paths, or library versions
- [ ] Define explicit `Content-Type` for all responses (e.g., `application/json; charset=utf-8`)

### API Lifecycle and Architecture

- [ ] Document API versioning strategy
- [ ] Identify sensitive business flows and protect them against automation abuse
- [ ] Limit GraphQL query depth and complexity; disable introspection in production
- [ ] Configure CORS with explicit origins (never use wildcards with credentials)
- [ ] Configure security headers (HSTS, X-Content-Type-Options, X-Frame-Options, etc.)
- [ ] Define and enforce request/response schemas for all inter-service communication
- [ ] Establish a security review gate in the API design approval process

---

## 2. Authentication and Authorization Checklist

Verify identity and access controls at every layer of the API.

### Authentication Mechanisms

- [ ] Use OAuth 2.0 / OpenID Connect for user authentication
- [ ] Enforce JWT algorithm explicitly (RS256/ES256 — reject `"none"` and HS256 with public keys)
- [ ] Set JWT expiry to a reasonable duration (access tokens: 15–60 minutes)
- [ ] Implement refresh token rotation (invalidate old refresh tokens on use)
- [ ] Bind refresh tokens to the client (device fingerprint or client ID)
- [ ] Hash API keys in storage (never store plaintext)
- [ ] Reject API keys passed in URL query parameters
- [ ] Use mTLS or signed tokens for service-to-service authentication
- [ ] Validate the `aud` (audience) and `iss` (issuer) claims in every JWT

### Authentication Security

- [ ] Return generic errors on authentication failure — do not reveal whether a user exists
- [ ] Use timing-safe comparison for credential validation
- [ ] Implement account lockout or progressive delays after repeated failed attempts
- [ ] Invalidate all sessions and tokens on logout or password change
- [ ] Require step-up authentication for sensitive operations (e.g., MFA re-prompt)
- [ ] Set absolute session timeout in addition to idle timeout
- [ ] Reject tokens issued before the last password change (check `iat` claim)

### Authorization Controls

- [ ] Enforce RBAC/ABAC policies at the middleware level (not in individual handlers)
- [ ] Test authorization with multiple roles: admin, regular user, anonymous, service account

---

## 3. Input Validation Checklist

Validate and sanitize all input at the API boundary to prevent injection and abuse.

### Header and Body Validation

- [ ] Validate the `Content-Type` header — reject unexpected content types
- [ ] Limit request body size at the server/gateway level
- [ ] Validate all path parameters (type, format, range)
- [ ] Validate all query parameters — use allowlists where possible
- [ ] Apply JSON schema validation on all request bodies

### Injection Prevention

- [ ] Prevent SQL/NoSQL injection — never use string interpolation for queries
- [ ] Prevent command injection — never pass unsanitized input to shell commands
- [ ] Prevent XXE — disable XML external entity processing or use `defusedxml`
- [ ] Prevent LDAP injection — escape special characters in LDAP queries
- [ ] Prevent template injection — never pass user input directly to template engines

### File and URL Handling

- [ ] Restrict file uploads: enforce type whitelist, size limit, sanitize filenames, store outside webroot
- [ ] Validate URL parameters against SSRF — block private/internal IPs, validate URL schemes
- [ ] Enforce GraphQL-specific limits: query depth, complexity, and batch query count

---

## 4. Transport and Data Security Checklist

Protect data in transit and at rest across all API communications.

### Transport Security

- [ ] Enforce TLS 1.2 or higher on all endpoints
- [ ] Disable weak cipher suites (RC4, DES, 3DES, export ciphers)
- [ ] Set HSTS header with `max-age` ≥ 31536000 (one year)
- [ ] Never include sensitive data in URL query parameters (tokens, passwords, PII)
- [ ] Pin certificates or use Certificate Transparency monitoring for critical services

### Data Protection

- [ ] Encrypt sensitive data at rest
- [ ] Classify API data fields by sensitivity level (public, internal, confidential, restricted)
- [ ] Minimize PII in API responses (apply data minimization principle)
- [ ] Verify webhook signatures using HMAC or shared secret validation
- [ ] Implement field-level encryption for highly sensitive data (e.g., SSN, payment card numbers)

### Outbound API Call Security

- [ ] Validate third-party API responses before processing
- [ ] Disable automatic HTTP redirect following for upstream API calls
- [ ] Set explicit timeouts on all outbound API calls
- [ ] Enable certificate validation on all outbound HTTPS calls

---

## 5. Rate Limiting and Resource Protection Checklist

Prevent abuse, denial-of-service, and resource exhaustion across all API surfaces.

### Rate Limiting Configuration

- [ ] Configure global rate limiting (requests per minute per client)
- [ ] Apply stricter limits on authentication endpoints (login, password reset, OTP verification)
- [ ] Apply stricter limits on sensitive business flows (purchase, transfer, invitation)
- [ ] Return rate limit headers to clients (`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`)
- [ ] Return `429 Too Many Requests` with a `Retry-After` header when limits are exceeded

### Resource Constraints

- [ ] Enforce response pagination with a maximum page size
- [ ] Apply query complexity limits for GraphQL APIs
- [ ] Enforce upload size limits at the server/gateway level
- [ ] Set execution timeouts on long-running operations
- [ ] Configure spending limits and alerts on third-party API integrations

---

## 6. API Inventory and Documentation Checklist

Maintain a complete, accurate inventory of all APIs and their security posture.

### Documentation and Specification

- [ ] Document all APIs in an OpenAPI/Swagger specification
- [ ] Generate API documentation from code to ensure it stays in sync
- [ ] Assign sunset dates and add deprecation headers to deprecated APIs
- [ ] Document the API version retirement plan
- [ ] Include security requirements (scopes, roles, auth methods) in API specification
- [ ] Document data classification for every endpoint's request and response fields

### API Inventory Management

- [ ] Audit for and remove undocumented shadow/zombie endpoints in production
- [ ] Apply identical security controls to beta/staging APIs as production APIs
- [ ] Verify internal APIs are not exposed to the public network
- [ ] Maintain a registry of all API consumers and their access scopes
- [ ] Review and rotate API keys/credentials on a defined schedule

### Dependency Tracking

- [ ] Inventory all third-party API integrations with data flow documentation
- [ ] Include API dependencies and client libraries in the SBOM

---

## 7. Deployment and Infrastructure Checklist

Harden the runtime environment and infrastructure supporting the API.

### Gateway and Network Security

- [ ] Configure the API gateway for auth offloading, rate limiting, and request logging
- [ ] Activate WAF rules for common API attacks (injection, SSRF, path traversal)
- [ ] Disable debug and diagnostic endpoints in production
- [ ] Change all default credentials before deployment
- [ ] Disable unnecessary HTTP methods (TRACE, OPTIONS unless required by CORS)
- [ ] Remove server version banners from HTTP response headers (Server, X-Powered-By)

### Container and Runtime Security

- [ ] Scan container images for known vulnerabilities before deployment
- [ ] Run the API process with minimal privileges (non-root user)
- [ ] Enforce network segmentation between API tiers (frontend, backend, database)
- [ ] Use read-only filesystems where possible in container deployments
- [ ] Define resource limits (CPU, memory) for API containers to prevent resource abuse

### Secrets Management

- [ ] Inject secrets via environment variables or a secrets vault (never embed in code or config files)
- [ ] Verify health check endpoints do not expose sensitive information (version, config, env)
- [ ] Rotate secrets and credentials on a defined schedule
- [ ] Audit access to secrets vault and log secret retrieval events

---

## 8. Logging and Monitoring Checklist

Establish visibility into API activity for detection, response, and forensics.

### Request Logging

- [ ] Log all API requests with method, path, status code, latency, and user ID
- [ ] Log all authentication events (success, failure, lockout)
- [ ] Log all authorization failures with request context
- [ ] Exclude sensitive data from logs (tokens, passwords, PII, full request bodies)
- [ ] Track correlation IDs across services for distributed tracing
- [ ] Log API key usage per consumer for audit and anomaly detection

### Alerting and Response

- [ ] Configure alerting on anomalies (error rate spikes, auth failure bursts, unusual traffic patterns)
- [ ] Alert on sudden changes in API usage patterns per consumer
- [ ] Protect log integrity (use append-only storage, ship to external log aggregation)
- [ ] Define log retention policy that meets compliance requirements
- [ ] Document an incident response plan specific to API breaches
- [ ] Include API-specific tests in penetration testing scope
- [ ] Conduct periodic tabletop exercises for API security incidents

---

## 9. Testing Security Checklist

Verify security controls through automated and manual testing at every stage.

### Authorization Testing

- [ ] Test every endpoint with an incorrect user/role — verify `403 Forbidden` response
- [ ] Test BOLA: attempt to access resources by manipulating IDs with a different user
- [ ] Test BFLA: attempt to access admin endpoints as a regular user
- [ ] Test mass assignment: send extra/unexpected fields and verify they are rejected or ignored
- [ ] Test horizontal privilege escalation: access peer user resources across tenant boundaries

### Abuse and Limit Testing

- [ ] Test rate limits: exceed configured limits and verify `429` response
- [ ] Test injection payloads: SQL, NoSQL, and command injection vectors
- [ ] Test SSRF: submit internal IP addresses and cloud metadata URLs (e.g., `169.254.169.254`)
- [ ] Test large payload handling: submit oversized request bodies and verify rejection
- [ ] Test pagination boundary conditions: request page size 0, negative, and extremely large values

### Authentication and Error Handling Testing

- [ ] Test authentication bypass: submit missing, expired, and malformed tokens
- [ ] Test token reuse after logout or password change — verify rejection
- [ ] Test error responses: verify no sensitive information is leaked in error bodies or headers
- [ ] Verify consistent error format across all endpoints (RFC 7807 compliance)
- [ ] Test CORS: verify preflight responses reject unauthorized origins

### Automated Security Testing

- [ ] Integrate SAST and DAST tools in the CI/CD pipeline
- [ ] Run API fuzzing with dedicated tools (Burp Suite, OWASP ZAP, Schemathesis)
- [ ] Validate API contract compliance against the OpenAPI specification in CI
- [ ] Run dependency vulnerability scans (Dependabot, Snyk, Trivy) on every build
- [ ] Maintain a baseline of known security test results and track regressions

---

## 10. Security Tools Reference

Recommended tools for API security testing, enforcement, and monitoring.

| Tool | Category | Description |
| --- | --- | --- |
| **Schemathesis** | API Testing | Run property-based API testing derived from OpenAPI specifications |
| **OWASP ZAP** | DAST | Perform dynamic API security scanning with active and passive rules |
| **Burp Suite** | Penetration Testing | Conduct API penetration testing with interception and scanning |
| **Spectral** | Spec Linting | Lint OpenAPI specifications for security and design issues |
| **dredd** | Contract Testing | Validate API implementation against its documentation contract |
| **nuclei** | Vulnerability Scanning | Scan APIs using community-maintained vulnerability templates |
| **rate-limit-redis** | Rate Limiting | Implement Redis-backed distributed rate limiting |
| **helmet** (Node.js) | Security Headers | Apply security headers middleware in Express/Koa applications |
| **slowapi** (Python) | Rate Limiting | Add rate limiting to FastAPI and Starlette applications |
| **express-rate-limit** (Node.js) | Rate Limiting | Add rate limiting middleware to Express applications |

### Tool Selection Guidelines

- Use **Schemathesis** or **dredd** for automated contract and property-based testing in CI/CD
- Use **OWASP ZAP** for automated DAST scans; use **Burp Suite** for manual penetration testing
- Use **Spectral** as a pre-commit or CI lint gate for OpenAPI specification quality
- Use **nuclei** for broad vulnerability scanning across multiple API endpoints
- Choose rate limiting middleware based on the application framework and deployment architecture

### Additional Tools by Category

**Static Analysis:**

- Use **semgrep** with API-security rulesets for language-specific SAST
- Use **bandit** (Python) or **eslint-plugin-security** (Node.js) for framework-specific checks

**Runtime Protection:**

- Use **ModSecurity** or cloud-native WAF for runtime API attack mitigation
- Use **Falco** for runtime container security monitoring

**API Discovery:**

- Use **kiterunner** for discovering hidden API endpoints during penetration testing
- Use **Akto** or **Salt Security** for continuous API discovery and posture management

---

## Quick Reference: OWASP API Security Top 10 (2023) Mapping

| OWASP Risk | Checklist Sections |
| --- | --- |
| API1 — Broken Object Level Authorization (BOLA) | §1 Design Review, §2 Authorization, §9 Testing |
| API2 — Broken Authentication | §2 Authentication, §9 Auth Testing |
| API3 — Broken Object Property Level Authorization | §1 Design Review (property-level auth, mass assignment) |
| API4 — Unrestricted Resource Consumption | §5 Rate Limiting, §3 Input Validation |
| API5 — Broken Function Level Authorization (BFLA) | §1 Design Review, §2 Authorization, §9 Testing |
| API6 — Unrestricted Access to Sensitive Business Flows | §1 Design Review, §5 Rate Limiting |
| API7 — Server Side Request Forgery (SSRF) | §3 Input Validation, §9 Testing |
| API8 — Security Misconfiguration | §7 Deployment, §1 Design (CORS, headers) |
| API9 — Improper Inventory Management | §6 API Inventory |
| API10 — Unsafe Consumption of APIs | §4 Outbound API Calls |

---

## Usage Notes

- Apply checklists incrementally — prioritize items based on threat model and risk assessment
- Treat each checkbox as a gate: mark complete only when the control is verified and documented
- Review these checklists at every major milestone: design review, code review, pre-deployment, and periodic audit
- Update checklists as new threats emerge and standards evolve (reference OWASP API Security Top 10)
