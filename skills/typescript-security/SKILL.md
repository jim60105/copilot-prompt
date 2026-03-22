---
name: typescript-security
description: >-
  Guideline for designing, implementing, and verifying secure TypeScript and
  JavaScript applications following OWASP Top 10 best practices. Use when the
  user wants to: (1) review TypeScript or JavaScript code for security
  vulnerabilities, (2) design a secure Node.js, Deno, or browser application
  architecture, (3) implement security features (authentication, authorization,
  cryptography, input validation), (4) audit npm/yarn/pnpm dependencies for
  known vulnerabilities, (5) create security checklists or verification plans,
  (6) fix security bugs or harden existing TypeScript or JavaScript code, (7) set
  up security testing and static analysis (ESLint security plugins, Semgrep,
  Snyk), or (8) handle any TypeScript/JavaScript security concern including
  injection prevention, prototype pollution, XSS protection, SSRF prevention,
  secrets management, and secure deployment.
---

# TypeScript / JavaScript Security Development Guide

Provide a structured approach to building secure TypeScript and JavaScript applications, covering the OWASP Top 10, secure coding patterns, and verification checklists. Apply these guidelines throughout the secure development lifecycle — from threat modeling through deployment. This guide covers both server-side (Node.js, Deno, Bun) and client-side (browser) contexts.

## Secure Development Lifecycle

### Phase 1: Threat Modeling and Secure Design

Before writing code, identify and mitigate threats at the design level:

- **Identify trust boundaries** — Map where untrusted data enters the system (HTTP requests, WebSocket messages, file uploads, database reads, environment variables, third-party APIs, `postMessage`, URL parameters, localStorage)
- **Map data flows** — Trace sensitive data (credentials, PII, tokens) through the system and verify protection at each stage
- **Enumerate entry points** — List all routes, endpoints, CLI arguments, message queue consumers, WebSocket handlers, and scheduled tasks
- **Map attack surfaces to OWASP Top 10** — Cross-reference each entry point against the OWASP categories in the quick reference table below

Design with security controls built-in:

- Centralized authentication and authorization middleware — never scatter auth checks across handlers
- Input validation at every trust boundary — validate early, reject invalid data before processing
- Least-privilege database access — use read-only connections where writes are not needed
- Defense in depth — layer multiple controls (input validation + parameterized queries + WAF)
- Fail securely — deny by default, require explicit grants
- Server-side enforcement — never rely solely on client-side validation or access controls

### Phase 2: Secure Implementation

#### Critical Prohibitions

Never use these patterns. Violations are high-severity findings in any review.

| Never | Instead |
|-------|---------|
| `eval()` / `Function()` constructor with untrusted input | `JSON.parse()` or a dedicated parser |
| `child_process.exec()` with user input | `child_process.execFile()` or `spawn()` with array args |
| String concatenation / template literals in SQL | Parameterized queries (`db.query(sql, params)`) |
| `innerHTML` / `outerHTML` / `document.write()` with untrusted data | `textContent`, framework templating, or DOMPurify |
| `dangerouslySetInnerHTML` with unsanitized data | DOMPurify + explicit sanitization |
| `Math.random()` for security purposes | `crypto.randomUUID()` / `crypto.getRandomValues()` |
| MD5 / SHA1 for password hashing | `bcrypt`, `argon2`, or `scrypt` via `crypto.scrypt()` |
| `==` for security comparisons | `===` strict equality |
| `Object.assign()` / spread with untrusted input on prototypes | Validated schema (Zod, class-validator) + `Object.create(null)` |
| `require()` / `import()` with user-controlled paths | Static imports with allowlisted modules |
| Hardcoded secrets in source code | Environment variables or secret manager (Vault, AWS SM) |
| `NODE_ENV !== 'production'` left in production | Environment-specific configuration |
| `JSON.parse()` without schema validation on untrusted data | Zod, io-ts, or class-validator after parsing |
| `new RegExp(userInput)` | Escape user input or use a safe regex library |
| `vm.runInNewContext()` / `vm.runInThisContext()` with untrusted code | Isolated worker threads or dedicated sandbox |
| Disabling TLS verification (`rejectUnauthorized: false`) | Proper certificate management |

#### Secure Implementation References

- For OWASP Top 10 details with vulnerable → secure code examples: See [references/owasp-top-10.md](references/owasp-top-10.md)
- For secure coding patterns organized by domain (input validation, auth, crypto, DOM security, subprocess, file I/O, web frameworks): See [references/secure-coding.md](references/secure-coding.md)

### Phase 3: Security Verification

Apply a layered verification approach:

1. **Static Analysis** — Detect common vulnerability patterns automatically
   - `eslint-plugin-security` — Node.js security linter rules
   - `eslint-plugin-no-unsanitized` — Detect unsafe DOM manipulation
   - `semgrep` — Pattern-based analysis with OWASP and TypeScript/JavaScript rulesets
   - `typescript-eslint` — Type-aware linting for TypeScript
2. **Dependency Audit** — Identify known vulnerabilities in third-party packages
   - `npm audit` / `yarn audit` / `pnpm audit` — Built-in package manager auditing
   - `snyk` — Comprehensive vulnerability database and remediation advice
   - `socket.dev` — Supply chain attack detection (typosquatting, install scripts)
3. **Secrets Detection** — Find leaked credentials and API keys
   - `detect-secrets` — Baseline-aware secrets scanner
   - `gitleaks` — Git-aware secrets scanning
4. **Code Review** — Apply the security review workflow and checklists
5. **Security Testing** — Write negative tests that verify rejection of malicious inputs; fuzz-test parsers and validators

Quick tool commands:

```bash
# ESLint security plugins
npm install --save-dev eslint-plugin-security eslint-plugin-no-unsanitized
npx eslint --ext .ts,.js,.tsx,.jsx src/

# npm audit — dependency vulnerabilities
npm audit
npm audit --audit-level=high

# Snyk — comprehensive dependency and code scanning
npx snyk test
npx snyk code test

# detect-secrets — secrets scanning
detect-secrets scan > .secrets.baseline

# Semgrep — advanced pattern matching
semgrep --config=p/javascript --config=p/typescript --config=p/owasp-top-ten src/

# Socket.dev — supply chain security
npx socket npm info <package-name>
```

For complete verification checklists (code review, architecture review, dependency audit, deployment, testing, incident response): See [references/security-checklist.md](references/security-checklist.md)

### Phase 4: Dependency and Deployment Security

#### Dependency Management

- Use lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`) and commit them
- Run `npm audit` / `snyk test` in CI/CD pipeline on every build
- Enable `--ignore-scripts` for packages where postinstall scripts are not needed
- Monitor for typosquatting — verify package names carefully before installing
- Review new dependencies before adding — check maintainership, download counts, known issues
- Use `socket.dev` or similar tools to detect supply chain attacks (install scripts, obfuscated code)
- Prefer packages with provenance attestations (`npm provenance`)

#### Deployment Hardening

- **Container security** — Scan images with `trivy`; use minimal base images (distroless, alpine); run as non-root user
- **HTTPS/TLS** — Enforce TLS 1.2+ for all connections; redirect HTTP to HTTPS; set `Strict-Transport-Security` header
- **Security headers** — Configure `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Permissions-Policy`
- **Secrets at runtime** — Inject secrets via environment variables or mounted volumes; never bake into images or bundles
- **Least privilege** — Run processes as non-root; use read-only filesystems where possible; limit network access
- **Source maps** — Never deploy source maps to production in public-facing applications
- **Client-side** — Enable Subresource Integrity (SRI) for CDN scripts; configure strict CSP; avoid inline scripts
- **Logging** — Use structured logging (JSON); never log passwords, tokens, PII, or full stack traces to users; log authentication events and access denials for audit

## OWASP Top 10:2025 Quick Reference

Map each OWASP 2025 category to TypeScript/JavaScript-specific risks and primary mitigations:

| # | Category | TypeScript/JavaScript-Specific Risks | Primary Mitigation |
|---|----------|--------------------------------------|-------------------|
| A01 | Broken Access Control | Missing auth middleware, IDOR via sequential IDs, path traversal, SSRF via `fetch(userUrl)`, CORS `origin: *`, client-side-only auth checks | Centralized auth middleware, object-level permissions, `path.resolve()` + containment check, URL allowlisting, explicit CORS origins |
| A02 | Security Misconfiguration | `NODE_ENV=development` in prod, Swagger/docs exposed, verbose error stacks, permissive CORS, default `express.static()` serving `.env` | Environment-specific config, disable docs in prod, centralized error handler, explicit CORS, `.env` outside webroot |
| A03 | Software Supply Chain Failures | Unpinned deps, typosquatting on npm, malicious postinstall scripts, no lockfile, unvetted transitive deps, CI/CD secrets exposure | `npm audit` / `snyk` in CI, lockfiles committed, `--ignore-scripts`, `socket.dev`, npm provenance |
| A04 | Cryptographic Failures | `Math.random()` for tokens, weak hashing, hardcoded API keys, disabled TLS verification, secrets in client bundles | `crypto.randomUUID()` / `crypto.getRandomValues()`, `bcrypt`/`argon2`, env vars / secret manager, proper TLS config |
| A05 | Injection | SQL via template literals, XSS via `innerHTML`/`dangerouslySetInnerHTML`, `child_process.exec()`, NoSQL injection (`$gt`/`$ne` operators), SSTI, `eval()` | Parameterized queries, DOM sanitization (DOMPurify), `execFile()`/`spawn()` with array args, input validation, `textContent` |
| A06 | Insecure Design | No rate limiting, missing input validation layer, no abuse case modeling, client-side enforcement of server-side security | Threat modeling, validation at boundaries (Zod/class-validator), rate limiting middleware, server-side enforcement |
| A07 | Authentication Failures | Weak session config, JWT `algorithm: "none"` or HS256 with public key, no brute-force protection, tokens in localStorage | Secure session settings, explicit `algorithms: ["RS256"]`, account lockout / rate limiting, HttpOnly cookies |
| A08 | Software or Data Integrity Failures | Prototype pollution, `node-serialize` deserialization, unsigned updates, CDN scripts without SRI, CI/CD pipeline injection | Schema validation (Zod), `JSON.parse()` + validation, SRI for CDN scripts, pinned CI actions with SHA |
| A09 | Security Logging and Alerting Failures | Logging passwords/tokens, `console.log` in production, no auth event logging, missing alerting, no structured logging | Structured logging (pino/winston) with field filtering, audit trail, alerting thresholds, honeytokens |
| A10 | Mishandling of Exceptional Conditions | Unhandled promise rejections, empty `catch {}`, failing open, sensitive info in error responses, uncaught exceptions crashing process | Specific error types, `finally` blocks, centralized error handler, `process.on('unhandledRejection')`, fail-closed patterns |

For detailed vulnerable → secure code examples for each category: See [references/owasp-top-10.md](references/owasp-top-10.md)

## Security Review Workflow

Follow this procedure when reviewing TypeScript or JavaScript code for security:

1. **Scan for critical prohibitions** — Check for any pattern in the "Critical Prohibitions" table above. Each match is an immediate high-severity finding.
2. **Check input validation** — Verify every entry point (route handler, CLI argument, file parser, WebSocket handler, queue consumer) validates and sanitizes input before processing.
3. **Verify authentication and authorization** — Confirm every endpoint requires authentication (unless explicitly public) and checks authorization for the specific resource being accessed.
4. **Review data handling** — Trace how secrets, PII, and sensitive data flow through the system. Verify encryption at rest and in transit, proper key management, and secure deletion. Ensure no secrets are bundled into client-side code.
5. **Check error handling** — Ensure errors do not leak stack traces, internal paths, database details, or configuration to users. Verify fail-secure behavior. Check for unhandled promise rejections.
6. **Audit dependencies** — Run `npm audit` and `snyk test`. Flag any unpatched dependencies or packages with known CVEs. Check for suspicious postinstall scripts.
7. **Verify logging** — Confirm no sensitive data (passwords, tokens, PII) appears in logs. Verify authentication events, authorization failures, and security-relevant actions are logged.
8. **Run static analysis** — Execute ESLint with security plugins and review findings. Run `semgrep` with JavaScript/TypeScript and OWASP rulesets for deeper analysis.
9. **Check DOM security (client-side)** — Verify no unsafe DOM manipulation (`innerHTML`, `document.write`). Check CSP configuration, SRI on external scripts, and proper sanitization of user content.
10. **Report findings** — For each finding, document: severity (Critical/High/Medium/Low), location (file:line), vulnerable code snippet, explanation of the risk, and recommended fix with code example.

## Security Hardening Quick Commands

```bash
# === Static Analysis ===
npm install --save-dev eslint-plugin-security eslint-plugin-no-unsanitized
npx eslint --ext .ts,.js,.tsx,.jsx src/
semgrep --config=p/javascript --config=p/typescript --config=p/owasp-top-ten src/

# === Dependency Audit ===
npm audit --audit-level=high
npx snyk test

# === Secrets Detection ===
detect-secrets scan > .secrets.baseline
gitleaks detect --source .

# === Lock Dependencies ===
npm ci  # install from lockfile (CI/CD)

# === Container Scanning ===
# trivy image <image-name>
```

## Reference Files

Consult these files for detailed guidance beyond this overview:

- **[references/owasp-top-10.md](references/owasp-top-10.md)** — Detailed OWASP Top 10 coverage with TypeScript/JavaScript-specific vulnerable → secure code examples for each category, including Express, Fastify, NestJS, Next.js, and React patterns
- **[references/secure-coding.md](references/secure-coding.md)** — Secure coding patterns organized by domain: input validation, authentication, cryptography, DOM security, subprocess execution, file operations, and web framework configuration (Express, Fastify, NestJS, Next.js, React)
- **[references/security-checklist.md](references/security-checklist.md)** — Actionable verification checklists for code review, architecture review, dependency audit, deployment hardening, security testing, and incident response
