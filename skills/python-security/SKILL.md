---
name: python-security
description: >-
  Guideline for designing, implementing, and verifying secure Python applications
  following OWASP Top 10 best practices. Use when the user wants to: (1) review
  Python code for security vulnerabilities, (2) design a secure Python application
  architecture, (3) implement security features (authentication, authorization,
  cryptography, input validation), (4) audit Python dependencies for known
  vulnerabilities, (5) create security checklists or verification plans, (6) fix
  security bugs or harden existing Python code, (7) set up security testing and
  static analysis (bandit, safety, semgrep), or (8) handle any Python security
  concern including injection prevention, secure deserialization, SSRF protection,
  secrets management, and secure deployment.
---

# Python Security Development Guide

Provide a structured approach to building secure Python applications, covering the OWASP Top 10, secure coding patterns, and verification checklists. Apply these guidelines throughout the secure development lifecycle — from threat modeling through deployment.

## Secure Development Lifecycle

### Phase 1: Threat Modeling and Secure Design

Before writing code, identify and mitigate threats at the design level:

- **Identify trust boundaries** — Map where untrusted data enters the system (HTTP requests, file uploads, database reads, environment variables, third-party APIs)
- **Map data flows** — Trace sensitive data (credentials, PII, tokens) through the system and verify protection at each stage
- **Enumerate entry points** — List all routes, endpoints, CLI arguments, message queue consumers, and cron jobs
- **Map attack surfaces to OWASP Top 10** — Cross-reference each entry point against the OWASP categories in the quick reference table below

Design with security controls built-in:

- Centralized authentication and authorization middleware — never scatter auth checks across handlers
- Input validation at every trust boundary — validate early, reject invalid data before processing
- Least-privilege database access — use read-only connections where writes are not needed
- Defense in depth — layer multiple controls (input validation + parameterized queries + WAF)
- Fail securely — deny by default, require explicit grants

### Phase 2: Secure Implementation

#### Critical Prohibitions

Never use these patterns. Violations are high-severity findings in any review.

| Never | Instead |
|-------|---------|
| `eval()` / `exec()` with untrusted input | `ast.literal_eval()` or a dedicated parser |
| `pickle.load()` with untrusted data | `json.loads()` or validated schema (e.g., Pydantic) |
| `yaml.load()` | `yaml.safe_load()` |
| `shell=True` + user input in subprocess | `subprocess.run([cmd, arg1, arg2])` with list args |
| `os.system()` | `subprocess.run()` |
| String formatting / f-strings in SQL | Parameterized queries (`cursor.execute(sql, params)`) |
| `random` module for security purposes | `secrets` module |
| MD5 / SHA1 for password hashing | `bcrypt` or `argon2-cffi` |
| `assert` for security checks | `if not condition: raise SecurityError(...)` |
| Bare `except:` or `except Exception:` | `except SpecificException:` with proper handling |
| Hardcoded secrets in source code | Environment variables or secret manager (Vault, AWS SM) |
| `DEBUG=True` in production | Environment-specific configuration |

#### Secure Implementation References

- For OWASP Top 10 details with vulnerable → secure code examples: See [references/owasp-top-10.md](references/owasp-top-10.md)
- For secure coding patterns organized by domain (input validation, auth, crypto, serialization, subprocess, file I/O, web frameworks): See [references/secure-coding.md](references/secure-coding.md)

### Phase 3: Security Verification

Apply a layered verification approach:

1. **Static Analysis** — Detect common vulnerability patterns automatically
   - `bandit` — Python-specific security linter (AST-based)
   - `semgrep` — Pattern-based analysis with OWASP and Python rulesets
   - `pylint` — General linting with some security-relevant checks
2. **Dependency Audit** — Identify known vulnerabilities in third-party packages
   - `pip-audit` — Check installed packages against the OSV database
   - `safety` — Check against the Safety vulnerability database
3. **Secrets Detection** — Find leaked credentials and API keys
   - `detect-secrets` — Baseline-aware secrets scanner
4. **Code Review** — Apply the security review workflow and checklists
5. **Security Testing** — Write negative tests that verify rejection of malicious inputs; fuzz-test parsers and validators

Quick tool commands:

```bash
# Bandit — static analysis
bandit -r src/ -f json -o bandit-report.json

# pip-audit — dependency vulnerabilities
pip-audit

# Safety — alternative dependency check
safety check

# detect-secrets — secrets scanning
detect-secrets scan > .secrets.baseline

# Semgrep — advanced pattern matching
semgrep --config=p/python --config=p/owasp-top-ten src/
```

For complete verification checklists (code review, architecture review, dependency audit, deployment, testing, incident response): See [references/security-checklist.md](references/security-checklist.md)

### Phase 4: Dependency and Deployment Security

#### Dependency Management

- Pin all dependencies with exact versions in `requirements.txt`
- Use hash verification: `pip install --require-hashes -r requirements.txt`
- Run `pip-audit` in CI/CD pipeline on every build
- Monitor for typosquatting — verify package names carefully before installing
- Review new dependencies before adding — check maintainership, download counts, known issues

#### Deployment Hardening

- **Container security** — Scan images with `trivy`; use minimal base images (distroless, alpine); run as non-root user
- **HTTPS/TLS** — Enforce TLS 1.2+ for all connections; redirect HTTP to HTTPS; set `Strict-Transport-Security` header
- **Security headers** — Configure `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`
- **Secrets at runtime** — Inject secrets via environment variables or mounted volumes; never bake into images
- **Least privilege** — Run processes as non-root; use read-only filesystems where possible; limit network access
- **Logging** — Use structured logging (JSON); never log passwords, tokens, PII, or full stack traces to users; log authentication events and access denials for audit

## OWASP Top 10:2025 Quick Reference

Map each OWASP 2025 category to Python-specific risks and primary mitigations:

| # | Category | Python-Specific Risks | Primary Mitigation |
|---|----------|----------------------|-------------------|
| A01 | Broken Access Control | Missing `@login_required` / auth decorators, IDOR via sequential IDs, path traversal, SSRF via `requests.get(user_url)` | Centralized auth middleware, object-level permissions, `pathlib.resolve()`, URL allowlisting |
| A02 | Security Misconfiguration | `DEBUG=True` in prod, `CORS(origins="*")`, Swagger/docs exposed, default `SECRET_KEY`, XXE via xml.etree | Environment-specific config, explicit CORS origins, disable docs in prod, `defusedxml` |
| A03 | Software Supply Chain Failures | Unpinned deps, typosquatting, no SBOM, unvetted transitive deps, CI/CD secrets exposure | `pip-audit` in CI, pinned versions with hashes, SBOM generation, CI/CD hardening |
| A04 | Cryptographic Failures | `random` module for tokens, MD5/SHA1 password hashing, hardcoded API keys, no encryption at rest | `secrets` module, `bcrypt`/`argon2`, env vars / secret manager, `cryptography` library |
| A05 | Injection | SQL via f-strings/`.format()`, `shell=True`, Jinja2 `|safe` / SSTI, `eval()`/`exec()` | Parameterized queries, `subprocess.run([list])`, Jinja2 autoescaping, `ast.literal_eval()` |
| A06 | Insecure Design | No rate limiting, missing input validation layer, no abuse case modeling | Threat modeling, validation at boundaries (Pydantic), rate limiting middleware |
| A07 | Authentication Failures | Weak session config, JWT `algorithm="none"` or HS256 with public key, no brute-force protection | Secure session settings, explicit `algorithms=["RS256"]`, account lockout / rate limiting |
| A08 | Software or Data Integrity Failures | `pickle.loads()` / `yaml.load()` deserialization, unsigned updates, CI/CD pipeline injection | `json.loads()` / `yaml.safe_load()`, signed artifacts, pinned CI actions with SHA |
| A09 | Security Logging and Alerting Failures | Logging passwords/tokens, no auth event logging, missing alerting, no playbooks | Structured logging with field filtering, audit trail, alerting thresholds, honeytokens |
| A10 | Mishandling of Exceptional Conditions | Bare `except: pass`, failing open, transaction rollback failures, sensitive info in errors | Specific exception types, context managers, centralized error handlers, fail-closed patterns |

For detailed vulnerable → secure code examples for each category: See [references/owasp-top-10.md](references/owasp-top-10.md)

## Security Review Workflow

Follow this procedure when reviewing Python code for security:

1. **Scan for critical prohibitions** — Check for any pattern in the "Critical Prohibitions" table above. Each match is an immediate high-severity finding.
2. **Check input validation** — Verify every entry point (route handler, CLI argument, file parser, queue consumer) validates and sanitizes input before processing.
3. **Verify authentication and authorization** — Confirm every endpoint requires authentication (unless explicitly public) and checks authorization for the specific resource being accessed.
4. **Review data handling** — Trace how secrets, PII, and sensitive data flow through the system. Verify encryption at rest and in transit, proper key management, and secure deletion.
5. **Check error handling** — Ensure errors do not leak stack traces, internal paths, database details, or configuration to users. Verify fail-secure behavior.
6. **Audit dependencies** — Run `pip-audit` and `safety check`. Flag any unpinned dependencies or packages with known CVEs.
7. **Verify logging** — Confirm no sensitive data (passwords, tokens, PII) appears in logs. Verify authentication events, authorization failures, and security-relevant actions are logged.
8. **Run static analysis** — Execute `bandit -r src/` and review findings. Run `semgrep` with Python and OWASP rulesets for deeper analysis.
9. **Report findings** — For each finding, document: severity (Critical/High/Medium/Low), location (file:line), vulnerable code snippet, explanation of the risk, and recommended fix with code example.

## Security Hardening Quick Commands

```bash
# === Static Analysis ===
pip install bandit && bandit -r src/ -f json -o bandit-report.json
pip install semgrep && semgrep --config=p/python --config=p/owasp-top-ten src/

# === Dependency Audit ===
pip install pip-audit && pip-audit
pip install safety && safety check

# === Secrets Detection ===
pip install detect-secrets && detect-secrets scan > .secrets.baseline

# === Pin Dependencies with Hashes ===
pip install pip-tools && pip-compile --generate-hashes requirements.in

# === Container Scanning ===
# trivy image <image-name>
```

## Reference Files

Consult these files for detailed guidance beyond this overview:

- **[references/owasp-top-10.md](references/owasp-top-10.md)** — Detailed OWASP Top 10 coverage with Python-specific vulnerable → secure code examples for each category, including Django, Flask, and FastAPI patterns
- **[references/secure-coding.md](references/secure-coding.md)** — Secure coding patterns organized by domain: input validation, authentication, cryptography, serialization, subprocess execution, file operations, and web framework configuration (Django, Flask, FastAPI)
- **[references/security-checklist.md](references/security-checklist.md)** — Actionable verification checklists for code review, architecture review, dependency audit, deployment hardening, security testing, and incident response
