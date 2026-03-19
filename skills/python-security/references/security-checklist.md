# Python Security Verification Checklist

> **Purpose**: Actionable security checklists for Python applications.
> Use during code review, pre-deployment audits, and ongoing security assessments.

---

## Table of Contents

- [1. Code-Level Security Checklist](#1-code-level-security-checklist)
  - [1.1 Dangerous Functions and Patterns](#11-dangerous-functions-and-patterns)
  - [1.2 Input Handling](#12-input-handling)
  - [1.3 Cryptography and Secrets](#13-cryptography-and-secrets)
  - [1.4 Error Handling and Logging](#14-error-handling-and-logging)
  - [1.5 File and Resource Operations](#15-file-and-resource-operations)
  - [1.6 Serialization and Parsing](#16-serialization-and-parsing)
- [2. Application Architecture Security Checklist](#2-application-architecture-security-checklist)
  - [2.1 Authentication and Authorization](#21-authentication-and-authorization)
  - [2.2 HTTP and API Security](#22-http-and-api-security)
  - [2.3 Data and Storage Security](#23-data-and-storage-security)
  - [2.4 Application Design](#24-application-design)
- [3. Dependency Security Checklist](#3-dependency-security-checklist)
- [4. Configuration and Secrets Checklist](#4-configuration-and-secrets-checklist)
- [5. Deployment Security Checklist](#5-deployment-security-checklist)
- [6. Testing Security Checklist](#6-testing-security-checklist)
- [7. Security Tools Reference](#7-security-tools-reference)
- [8. Incident Response Checklist](#8-incident-response-checklist)

---

## 1. Code-Level Security Checklist

### 1.1 Dangerous Functions and Patterns

*OWASP: A05:2025 Injection*

- [ ] Verify no use of `eval()`, `exec()`, or `compile()` with untrusted input
- [ ] Verify no use of `__import__()` with user-controlled module names
- [ ] Verify no `os.system()` calls — use `subprocess.run()` with list arguments instead
- [ ] Verify no `shell=True` in `subprocess` calls when command includes user input
- [ ] Verify no `os.popen()` usage — replace with `subprocess.run()`
- [ ] Verify no string formatting (`f""`, `.format()`, `%`) in SQL queries — use parameterized queries exclusively
- [ ] Verify no use of `string.Template` for constructing SQL, shell commands, or HTML
- [ ] Verify no `getattr()`/`setattr()` with user-controlled attribute names
- [ ] Verify no `globals()` or `locals()` manipulation based on user input
- [ ] Verify `assert` statements are not used for security checks (stripped by `-O` flag)
- [ ] Verify no use of `input()` in Python 2 (equivalent to `eval(input())`)
- [ ] Verify no `marshal.loads()` with untrusted data
- [ ] Verify no use of `ctypes` with user-controlled arguments

### 1.2 Input Handling

*OWASP: A05:2025 Injection*

- [ ] Validate all input at every entry point (CLI args, env vars, API params, file reads)
- [ ] Enforce maximum input length on all string inputs
- [ ] Validate and sanitize file names received from users
- [ ] Normalize Unicode input before validation to prevent bypass via homoglyphs
- [ ] Validate numeric inputs for range, type, and overflow
- [ ] Reject unexpected fields in structured input (use strict schema validation)
- [ ] Validate email addresses with a proper library (not just regex)
- [ ] Validate URL inputs — restrict allowed schemes to `https://` where possible
- [ ] Decode and validate all percent-encoded input before processing
- [ ] Apply type hints and runtime validation (e.g., pydantic) on all public API boundaries

### 1.3 Cryptography and Secrets

*OWASP: A04:2025 Cryptographic Failures*

- [ ] Verify no use of `random` module for security purposes — use `secrets` module
- [ ] Verify no MD5 or SHA1 for password hashing — use `bcrypt`, `argon2`, or `scrypt`
- [ ] Verify no hardcoded secrets, passwords, API keys, or tokens in source code
- [ ] Verify cryptographic keys are of sufficient length (RSA ≥ 2048, AES ≥ 256)
- [ ] Verify no use of deprecated ciphers (DES, RC4, Blowfish)
- [ ] Verify `hmac.compare_digest()` is used for constant-time comparison of secrets
- [ ] Verify TLS certificate verification is not disabled (`verify=False` in `requests`)
- [ ] Verify tokens and session IDs are generated with `secrets.token_urlsafe()` or equivalent
- [ ] Verify password hashing uses per-user salts (automatic with bcrypt/argon2)
- [ ] Verify sensitive data is zeroed from memory after use where feasible

### 1.4 Error Handling and Logging

*OWASP: A09:2025 Security Logging and Alerting Failures, A10:2025 Mishandling of Exceptional Conditions*

- [ ] Verify no bare `except:` clauses — catch specific exceptions
- [ ] Verify no sensitive data (passwords, tokens, PII) in error messages
- [ ] Verify no sensitive data written to log files
- [ ] Verify stack traces are not exposed to end users in production
- [ ] Verify exceptions do not reveal internal paths, database schemas, or infrastructure details
- [ ] Verify logging uses structured format (JSON) with consistent fields
- [ ] Verify log levels are appropriate (no DEBUG in production)
- [ ] Verify user-supplied data in logs is sanitized to prevent log injection
- [ ] Verify `finally` blocks are used for resource cleanup
- [ ] Verify no silent exception swallowing (`except: pass`)
- [ ] Verify fail-closed error handling — operations fail to a secure state (e.g., transaction rollback on error)
- [ ] Verify resource cleanup on exceptions uses context managers (`with` statements) rather than manual cleanup
- [ ] Verify centralized error handling is implemented to ensure consistent, safe error responses
- [ ] Verify rate limiting on error-prone endpoints to prevent cascading failures from exceptional conditions

### 1.5 File and Resource Operations

*OWASP: A01:2025 Broken Access Control*

- [ ] Verify path traversal checks on all file operations with user-supplied paths
- [ ] Use `pathlib.Path.resolve()` and validate against an allowed base directory
- [ ] Verify file permissions are set restrictively on created files (`0o600` or `0o644`)
- [ ] Verify temporary files use `tempfile.mkstemp()` or `tempfile.TemporaryDirectory()`
- [ ] Verify file descriptors and connections are closed properly (use context managers)
- [ ] Verify no symlink-following on user-supplied paths without validation
- [ ] Verify file size is checked before reading to prevent memory exhaustion
- [ ] Verify uploaded files are stored outside the webroot
- [ ] Verify file type validation checks magic bytes, not just file extension
- [ ] Verify no world-writable files or directories are created

### 1.6 Serialization and Parsing

*OWASP: A08:2025 Software or Data Integrity Failures*

- [ ] Verify no `pickle.loads()` / `pickle.load()` with untrusted data
- [ ] Verify no `yaml.load()` — use `yaml.safe_load()` exclusively
- [ ] Verify XML parsing uses `defusedxml` (not `xml.etree.ElementTree` with untrusted data)
- [ ] Verify no `shelve` module used with untrusted data (uses pickle internally)
- [ ] Verify JSON parsing enforces size limits on untrusted input
- [ ] Verify `jsonpickle` is not used with untrusted input
- [ ] Verify no `dill` or `cloudpickle` deserialization of untrusted data
- [ ] Verify protobuf/msgpack schemas are strictly defined
- [ ] Verify CSV parsing handles injection payloads (formulas starting with `=`, `+`, `-`, `@`)

---

## 2. Application Architecture Security Checklist

### 2.1 Authentication and Authorization

*OWASP: A01:2025 Broken Access Control, A07:2025 Authentication Failures*

- [ ] Enforce authentication at middleware/decorator level, not inline in views
- [ ] Implement authorization checks at object level, not just endpoint level
- [ ] Configure rate limiting on authentication endpoints (login, password reset, OTP)
- [ ] Enforce account lockout or exponential backoff after repeated failed login attempts
- [ ] Implement multi-factor authentication for sensitive operations
- [ ] Set secure session configuration: `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`
- [ ] Enforce session expiry and idle timeout
- [ ] Invalidate sessions server-side on logout
- [ ] Regenerate session ID on privilege elevation (login, role change)
- [ ] Verify JWT tokens have expiration (`exp`), issuer (`iss`), and audience (`aud`) claims
- [ ] Verify JWT signature algorithm is explicitly specified (prevent `alg: none` attacks)
- [ ] Verify password reset tokens are single-use and time-limited

### 2.2 HTTP and API Security

*OWASP: A02:2025 Security Misconfiguration, A01:2025 Broken Access Control (SSRF)*

- [ ] Restrict CORS to specific origins — no wildcard (`*`) in production
- [ ] Enable CSRF protection on all state-changing endpoints
- [ ] Configure Content Security Policy (CSP) headers
- [ ] Set `X-Content-Type-Options: nosniff` header
- [ ] Set `X-Frame-Options: DENY` or `SAMEORIGIN` header
- [ ] Set `Referrer-Policy: strict-origin-when-cross-origin` or stricter
- [ ] Set `Permissions-Policy` header to disable unused browser features
- [ ] Enforce HTTPS-only with HSTS header (`Strict-Transport-Security`)
- [ ] Implement request size limits at the web server / framework level
- [ ] Validate `Content-Type` header matches expected format on all endpoints
- [ ] Implement API versioning strategy to manage breaking security changes
- [ ] Return consistent, safe error response format (no stack traces, no internal details)
- [ ] Implement request ID tracing for security event correlation

### 2.3 Data and Storage Security

*OWASP: A05:2025 Injection, A04:2025 Cryptographic Failures*

- [ ] Use parameterized queries or ORM exclusively — no raw SQL string concatenation
- [ ] Configure database connections with least-privilege accounts
- [ ] Encrypt sensitive data at rest (PII, financial data, health records)
- [ ] Encrypt database connections (TLS for PostgreSQL, MySQL, etc.)
- [ ] Implement data retention and deletion policies
- [ ] Validate and sanitize data before storing and before rendering
- [ ] Restrict file uploads by type, size, and store outside the webroot
- [ ] Configure Redis/Memcached with authentication and network restrictions
- [ ] Implement audit logging for data access and modifications
- [ ] Verify database migrations do not drop security-relevant columns/constraints

### 2.4 Application Design

*OWASP: A06:2025 Insecure Design, A10:2025 Mishandling of Exceptional Conditions*

- [ ] Implement centralized error handling with safe error responses
- [ ] Use structured logging without sensitive data
- [ ] Separate configuration by environment (dev, staging, production)
- [ ] Implement health check endpoints that do not expose sensitive information
- [ ] Design for fail-secure: deny access by default on errors
- [ ] Implement circuit breakers for external service calls
- [ ] Enforce timeouts on all external HTTP requests and database queries
- [ ] Use async task queues (Celery) for long-running operations — validate task payloads
- [ ] Implement graceful shutdown to avoid data corruption
- [ ] Apply the principle of least privilege across all service boundaries

---

## 3. Dependency Security Checklist

*OWASP: A03:2025 Software Supply Chain Failures*

- [ ] Pin all dependencies to exact versions in `requirements.txt` or `pyproject.toml`
- [ ] Run `pip-audit` with no known vulnerabilities reported
- [ ] Run `safety check` and resolve all findings
- [ ] Remove unused dependencies from requirements files
- [ ] Verify all dependencies are sourced from official PyPI (no unverified custom indexes)
- [ ] Use `--require-hashes` in `requirements.txt` for integrity verification
- [ ] Use a virtual environment — no global pip installs in production
- [ ] Configure Dependabot or Renovate for automated dependency update PRs
- [ ] Verify license compliance for all dependencies (direct and transitive)
- [ ] Review transitive dependencies for known vulnerabilities
- [ ] Verify no dependency uses `setup.py` with arbitrary code execution during install
- [ ] Verify no typosquatting risk — double-check package names
- [ ] Lock file (`poetry.lock`, `Pipfile.lock`) committed and up to date
- [ ] Review dependency changelogs before major version upgrades
- [ ] Verify no dependency has been abandoned (check last release date, maintainer activity)
- [ ] Test the application after every dependency update before deploying

---

## 4. Configuration and Secrets Checklist

*OWASP: A02:2025 Security Misconfiguration, A04:2025 Cryptographic Failures*

- [ ] Verify no secrets exist in source code or version control history
- [ ] Add `.env` files to `.gitignore`
- [ ] Separate environment-specific configurations (dev, staging, production)
- [ ] Load `SECRET_KEY` and all secret values from environment variables or a secrets vault
- [ ] Disable `DEBUG` mode and development features in production
- [ ] Verify database credentials are not hardcoded
- [ ] Rotate API keys, tokens, and credentials on a regular schedule
- [ ] Configure pre-commit hooks: `detect-secrets`, `gitleaks`, or equivalent
- [ ] Verify `settings.py` (Django) or equivalent config does not contain secrets
- [ ] Validate that all required configuration is present at startup (fail fast)
- [ ] Set restrictive file permissions on configuration files (`0o600`)
- [ ] Use a secrets manager (HashiCorp Vault, AWS Secrets Manager, etc.) for production secrets
- [ ] Verify `.env.example` exists with placeholder values (not real secrets)
- [ ] Audit git history for accidentally committed secrets (`git log -p --all -S 'password'`)
- [ ] Verify CI/CD secrets are scoped to the minimum required repositories and environments
- [ ] Use short-lived credentials and tokens where possible

---

## 5. Deployment Security Checklist

*OWASP: A02:2025 Security Misconfiguration*

- [ ] Run production processes as a non-root user with minimal privileges
- [ ] Enforce HTTPS/TLS on all endpoints — redirect HTTP to HTTPS
- [ ] Configure security headers: HSTS, `X-Content-Type-Options`, `X-Frame-Options`, CSP
- [ ] Scan container images for vulnerabilities (Trivy, Snyk, Grype)
- [ ] Verify health check endpoints do not expose sensitive information
- [ ] Configure logging to an external, tamper-resistant log store
- [ ] Verify error pages do not leak stack traces, internal paths, or version numbers
- [ ] Serve static files separately from the application (CDN or reverse proxy)
- [ ] Configure network-level access controls (firewall rules, security groups)
- [ ] Set up monitoring and alerting for security events (failed logins, privilege escalation)
- [ ] Use a minimal base container image (e.g., `python:3.x-slim` or distroless)
- [ ] Remove development tools and debug packages from production images
- [ ] Verify no `.pyc` files or `__pycache__` directories are served publicly
- [ ] Configure `gunicorn`/`uvicorn` with appropriate worker count and timeouts
- [ ] Enable access logging on the reverse proxy (nginx, Caddy, etc.)
- [ ] Implement automated rollback on failed deployment
- [ ] Verify DNS records do not expose internal hostnames
- [ ] Disable unnecessary network ports and services
- [ ] Implement infrastructure-as-code and review security of IaC templates
- [ ] Verify backup encryption and test restore procedures

---

## 6. Testing Security Checklist

- [ ] Write unit tests for all authentication paths (login, logout, token refresh)
- [ ] Write unit tests for all authorization paths (role-based, object-level)
- [ ] Write negative tests for access control — verify unauthorized access returns 403
- [ ] Test input validation with malicious payloads (overlong strings, null bytes, Unicode)
- [ ] Test all query endpoints against SQL injection payloads
- [ ] Test all output rendering against XSS payloads
- [ ] Test CSRF token validation — verify requests without tokens are rejected
- [ ] Test rate limiting under load — verify limits are enforced
- [ ] Test session management: fixation, expiry, invalidation, concurrent sessions
- [ ] Run `bandit` static analysis with no high-severity issues (`bandit -r src/ -ll`)
- [ ] Run `safety` or `pip-audit` in CI pipeline — fail the build on findings
- [ ] Test file upload validation with oversized files, wrong MIME types, and path traversal names
- [ ] Test API endpoints with unexpected HTTP methods (PUT, DELETE on read-only endpoints)
- [ ] Test for SSRF by supplying internal URLs as input
- [ ] Test for open redirect vulnerabilities on redirect endpoints
- [ ] Test password policy enforcement (minimum length, complexity)
- [ ] Test account lockout behavior after failed login attempts
- [ ] Test for information disclosure in error responses (404, 500, validation errors)
- [ ] Include security test fixtures in `conftest.py` for authenticated/unauthenticated clients
- [ ] Run `semgrep` with Python security rules in CI pipeline
- [ ] Test for HTTP parameter pollution on all endpoints
- [ ] Verify test coverage on security-critical code paths is ≥ 90%

---

## 7. Security Tools Reference

| Tool | Purpose | Usage |
|------|---------|-------|
| **bandit** | Static analysis for common Python security issues | `bandit -r src/ -ll -ii` |
| **safety** | Check installed dependencies for known vulnerabilities | `safety check --full-report` |
| **pip-audit** | Audit pip dependencies against vulnerability databases | `pip-audit --strict` |
| **detect-secrets** | Pre-commit hook to prevent secrets from being committed | `detect-secrets scan --all-files` |
| **semgrep** | Advanced static analysis with custom and community rules | `semgrep --config=p/python` |
| **pylint** | Linting with security-related plugins | `pylint --load-plugins=pylint_security src/` |
| **mypy** | Type checking to catch type-confusion vulnerabilities | `mypy --strict src/` |
| **trivy** | Container image and filesystem vulnerability scanning | `trivy image myapp:latest` |
| **grype** | Container image vulnerability scanner | `grype myapp:latest` |
| **gitleaks** | Detect secrets in git history | `gitleaks detect --source .` |
| **OWASP ZAP** | Dynamic application security testing (DAST) | `zap-cli quick-scan https://app` |
| **tox** | Run security checks across multiple Python versions | `tox -e security` |
| **coverage** | Measure test coverage on security-critical paths | `coverage run -m pytest tests/security/` |
| **pre-commit** | Framework for managing pre-commit hooks | `pre-commit run --all-files` |
| **ossf-scorecard** | Evaluate open-source project security posture | `scorecard --repo=github.com/org/repo` |

### Recommended Pre-commit Configuration

```yaml
# .pre-commit-config.yaml (security-related hooks)
repos:
  - repo: https://github.com/PyCQA/bandit
    rev: 1.8.3
    hooks:
      - id: bandit
        args: ["-r", "src/", "-ll"]
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.22.1
    hooks:
      - id: gitleaks
```

### Recommended CI Security Stage

```yaml
# GitHub Actions example
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with:
        python-version: "3.12"
    - run: pip install bandit safety pip-audit semgrep
    - run: bandit -r src/ -ll -ii
    - run: pip-audit --strict
    - run: semgrep --config=p/python --error
```

---

## 8. Incident Response Checklist

### Immediate Response (0–1 hour)

- [ ] Assess severity using CVSS or internal severity matrix
- [ ] Determine scope: which systems, data, and users are affected
- [ ] Assign an incident owner and notify the security team
- [ ] Contain the vulnerability — disable affected endpoints, revoke compromised tokens
- [ ] Preserve evidence — snapshot logs, affected systems, and artifacts before changes

### Short-Term Remediation (1–24 hours)

- [ ] Rotate all potentially compromised credentials (API keys, database passwords, tokens)
- [ ] Patch the vulnerability in a dedicated branch
- [ ] Review code changes with a security-focused reviewer
- [ ] Deploy the fix to production through the standard pipeline (no hotfix shortcuts)
- [ ] Verify the fix resolves the vulnerability without introducing regressions
- [ ] Review logs for signs of exploitation (unusual access patterns, data exfiltration)

### Communication and Compliance (24–72 hours)

- [ ] Notify affected users if personal data was exposed (per GDPR, CCPA, or applicable regulation)
- [ ] File required breach notifications with regulatory bodies if applicable
- [ ] Update internal security advisories and status pages
- [ ] Communicate timeline and remediation steps to stakeholders

### Post-Incident (1–2 weeks)

- [ ] Conduct a blameless post-mortem with all involved parties
- [ ] Document root cause, timeline, impact, and remediation
- [ ] Identify process gaps that allowed the vulnerability
- [ ] Update security checklists, tests, and automation to prevent recurrence
- [ ] Add regression tests for the specific vulnerability
- [ ] Review related code for similar patterns
- [ ] Schedule follow-up review to verify all actions are completed

---

## Quick Reference: Common Vulnerability Patterns

| Pattern | Vulnerable Code | Secure Alternative |
|---------|----------------|-------------------|
| Code injection | `eval(user_input)` | Parse and validate explicitly |
| SQL injection | `f"SELECT * FROM t WHERE id={uid}"` | `cursor.execute("SELECT * FROM t WHERE id=%s", (uid,))` |
| Deserialization | `pickle.loads(data)` | `json.loads(data)` with schema validation |
| YAML bomb | `yaml.load(data)` | `yaml.safe_load(data)` |
| Command injection | `os.system(f"ls {path}")` | `subprocess.run(["ls", path])` |
| Path traversal | `open(f"uploads/{filename}")` | `Path(base / filename).resolve()` + verify prefix |
| Weak randomness | `random.randint(0, 999999)` | `secrets.randbelow(1000000)` |
| Weak hashing | `hashlib.md5(password)` | `bcrypt.hashpw(password, bcrypt.gensalt())` |
| SSRF | `requests.get(user_url)` | Validate URL against allowlist |
| Timing attack | `token == user_token` | `hmac.compare_digest(token, user_token)` |
