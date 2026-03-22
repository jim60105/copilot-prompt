# TypeScript / JavaScript Security Checklist

> Actionable verification checklists for secure TypeScript/JavaScript development. Covers both server-side (Node.js, Deno, Bun) and client-side (browser) contexts.

---

## 1. Code-Level Security Review

### Input Validation
- [ ] All external inputs validated with schema validation (Zod, class-validator, AJV)
- [ ] Allowlist validation used instead of denylist
- [ ] Request body size limits enforced (`express.json({ limit })`, Fastify `bodyLimit`)
- [ ] File uploads validated (MIME type via magic bytes, size limits, extension allowlist)
- [ ] Regular expressions reviewed for ReDoS — use RE2 for untrusted patterns
- [ ] Strict equality (`===`) used everywhere — no loose equality (`==`)
- [ ] `parseInt()` called with explicit radix: `parseInt(val, 10)`
- [ ] Query parameters and path params validated before use

### Injection Prevention
- [ ] Parameterized queries for all SQL (Prisma, Drizzle, Knex, TypeORM `createQueryBuilder` with parameters)
- [ ] No string concatenation or template literals in SQL queries
- [ ] MongoDB queries use typed filters — no raw `$where`, no unsanitized `$gt`/`$ne` in query objects
- [ ] No `eval()`, `Function()`, `vm.runInNewContext()` with untrusted input
- [ ] `child_process.execFile()` / `spawn()` used instead of `exec()` — no shell interpretation
- [ ] Template engines configured with auto-escaping enabled
- [ ] GraphQL queries use parameterized variables, depth limiting, and query complexity analysis

### DOM / XSS Prevention
- [ ] No `innerHTML`, `outerHTML`, `document.write()`, `insertAdjacentHTML()` with unsanitized content
- [ ] DOMPurify used when HTML rendering of user content is required
- [ ] `textContent` used instead of `innerHTML` for plain text
- [ ] React: no `dangerouslySetInnerHTML` without DOMPurify sanitization
- [ ] URL values validated with allowlisted schemes (`https:`, `http:`, `mailto:`) — block `javascript:`
- [ ] `postMessage` listeners verify `event.origin` against allowlist
- [ ] CSP headers configured — no `unsafe-inline` or `unsafe-eval` in `script-src`

### Sensitive Data
- [ ] No secrets hardcoded in source (API keys, passwords, tokens, connection strings)
- [ ] No secrets in client-side bundles (no `NEXT_PUBLIC_` for secret values)
- [ ] Secrets loaded from environment variables or secret managers, validated at startup
- [ ] No sensitive data in error messages, logs, or stack traces returned to clients
- [ ] Tokens stored in HttpOnly cookies, not `localStorage` or `sessionStorage`
- [ ] `.env` files listed in `.gitignore`

---

## 2. Architecture-Level Security

### Authentication
- [ ] JWT validation specifies explicit `algorithms` (e.g., `["RS256"]`) — never `algorithms: undefined`
- [ ] JWT `audience` and `issuer` validated
- [ ] Passwords hashed with bcrypt (cost ≥ 12) or argon2id
- [ ] Session IDs regenerated on login (`req.session.regenerate()`)
- [ ] Session destroyed on logout
- [ ] Account lockout or progressive delays after failed login attempts
- [ ] Multi-factor authentication supported for privileged accounts

### Authorization
- [ ] Authorization checks centralized in middleware, not scattered across route handlers
- [ ] Resource ownership validated (users can only access their own resources)
- [ ] Role-based or attribute-based access control implemented consistently
- [ ] Default-deny: endpoints require authentication unless explicitly public
- [ ] IDOR prevention: validate requesting user owns the accessed resource

### API Security
- [ ] Rate limiting applied to all endpoints (stricter on auth endpoints)
- [ ] CORS configured with specific origins — no wildcard `*` with credentials
- [ ] API versioning implemented
- [ ] Response pagination enforced — no unbounded result sets
- [ ] Unnecessary HTTP methods disabled per route
- [ ] Request timeout configured to prevent slowloris

### Cryptography
- [ ] `crypto.randomUUID()` or `crypto.randomBytes()` used — never `Math.random()` for security
- [ ] AES-256-GCM or ChaCha20-Poly1305 for symmetric encryption
- [ ] `crypto.timingSafeEqual()` for constant-time comparison of secrets/tokens
- [ ] TLS 1.2+ enforced for all external connections
- [ ] No deprecated crypto: `createCipher()`, MD5, SHA1 for security purposes
- [ ] Keys derived with scrypt or PBKDF2 when password-based encryption is needed

---

## 3. Dependency and Supply Chain Security

### Package Management
- [ ] `npm audit` / `yarn audit` / `pnpm audit` run in CI — builds fail on critical/high vulnerabilities
- [ ] Lock files (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`) committed and integrity-checked
- [ ] Exact versions or lock files used — no floating ranges (`^`, `~`) for security-critical dependencies
- [ ] `npm ci` used in CI/CD instead of `npm install` (respects lock file exactly)
- [ ] Dependencies reviewed before adoption (check maintainer activity, download count, known issues)
- [ ] `socket.dev` or similar tool used for supply chain attack detection

### Dependency Hygiene
- [ ] Unused dependencies removed
- [ ] `devDependencies` not installed in production (`npm ci --omit=dev`)
- [ ] `preinstall`/`postinstall` scripts audited — use `--ignore-scripts` when possible
- [ ] No dependencies with known prototype pollution or RCE vulnerabilities
- [ ] Renovate or Dependabot configured for automated dependency updates in PRs
- [ ] `node_modules` never committed to version control

### Container / Build Security (if applicable)
- [ ] Multi-stage Docker builds — no dev dependencies or source maps in final image
- [ ] Non-root user in container (`USER node`)
- [ ] `.dockerignore` excludes `.env`, `.git`, `node_modules`, build artifacts
- [ ] Base image pinned to digest, scanned with trivy or similar
- [ ] No secrets in Dockerfile or build args — use runtime secret injection

---

## 4. Configuration Security

### Server Configuration
- [ ] `helmet` (Express) or equivalent security headers middleware applied
- [ ] `X-Powered-By` header disabled
- [ ] `trust proxy` configured correctly when behind reverse proxy
- [ ] HTTPS enforced — HTTP redirects to HTTPS, HSTS header set
- [ ] Source maps not served in production (`productionBrowserSourceMaps: false`)
- [ ] Debug/development endpoints disabled in production (`NODE_ENV=production`)

### Cookie Configuration
- [ ] `HttpOnly: true` on session and auth cookies
- [ ] `Secure: true` on all cookies (HTTPS only)
- [ ] `SameSite: "strict"` or `"lax"` — never `"none"` unless required
- [ ] Appropriate `maxAge` / `expires` set — no indefinite sessions
- [ ] Cookie `path` scoped to necessary routes
- [ ] `__Host-` prefix used for strict cookie security (when applicable)

### Security Headers
- [ ] `Content-Security-Policy` — restrictive directives, no `unsafe-*`
- [ ] `X-Content-Type-Options: nosniff`
- [ ] `X-Frame-Options: DENY` or `SAMEORIGIN`
- [ ] `Referrer-Policy: strict-origin-when-cross-origin` or `no-referrer`
- [ ] `Permissions-Policy` restricting camera, microphone, geolocation, etc.
- [ ] `Strict-Transport-Security` with `max-age` ≥ 31536000 and `includeSubDomains`
- [ ] `Cross-Origin-Opener-Policy: same-origin`

---

## 5. Deployment Security

### Environment
- [ ] `NODE_ENV=production` set in production deployments
- [ ] Debug logging disabled or set to appropriate level in production
- [ ] Error details (stack traces, query details) never returned to clients in production
- [ ] Application runs as non-root user
- [ ] File system permissions restrict write access to necessary directories only

### Secrets
- [ ] Secrets injected at runtime via environment variables or secret manager
- [ ] No secrets in Docker images, CI logs, or version control
- [ ] Secret rotation process documented and tested
- [ ] `detect-secrets` or `gitleaks` in pre-commit hooks to catch accidental commits

### CI/CD Pipeline
- [ ] `npm audit --audit-level=high` gate in CI pipeline
- [ ] ESLint security plugins run in CI (`eslint-plugin-security`, `@microsoft/eslint-plugin-sdl`)
- [ ] Semgrep or similar SAST tool integrated in CI
- [ ] Container image scanning (trivy, Snyk Container) before deployment
- [ ] SBOM (Software Bill of Materials) generated for production builds
- [ ] Artifact attestations (GitHub Attestations, Sigstore) for production artifacts

---

## 6. Testing and Verification

### Security Testing
- [ ] Input validation tested with malicious payloads (injection strings, boundary values)
- [ ] Authentication bypass attempts tested (missing tokens, expired tokens, tampered tokens)
- [ ] Authorization tested (accessing other users' resources, privilege escalation)
- [ ] Rate limiting verified to work under load
- [ ] CORS policy tested — cross-origin requests from unauthorized origins rejected
- [ ] File upload tested with invalid types, oversized files, path traversal filenames

### Automated Security Checks
- [ ] `eslint-plugin-security` — detects `eval()`, `exec()`, non-literal regex, etc.
- [ ] `eslint-plugin-no-unsanitized` — detects unsafe DOM manipulation
- [ ] `@typescript-eslint/no-explicit-any` — minimizes untyped escape hatches
- [ ] Semgrep rules for TypeScript/JavaScript security patterns
- [ ] `npm audit` / Snyk in CI with severity thresholds
- [ ] Pre-commit hooks: `detect-secrets`, `gitleaks`, lint checks

---

## 7. Security Tools Reference

| Tool | Purpose | Integration |
|------|---------|-------------|
| `eslint-plugin-security` | Static analysis — Node.js security rules | ESLint config |
| `eslint-plugin-no-unsanitized` | Detect unsafe DOM APIs | ESLint config |
| `@microsoft/eslint-plugin-sdl` | Microsoft SDL security rules | ESLint config |
| `semgrep` | SAST — multi-language security patterns | CI pipeline |
| `npm audit` / `yarn audit` | Dependency vulnerability scanning | CI pipeline |
| `snyk` | Dependency + container + code scanning | CI pipeline / CLI |
| `socket.dev` | Supply chain attack detection | npm registry proxy / CI |
| `trivy` | Container image + dependency scanning | CI pipeline |
| `detect-secrets` | Pre-commit secret detection | Git hooks |
| `gitleaks` | Git history secret scanning | Git hooks / CI |
| `helmet` | Security headers middleware | Express/Fastify |
| `DOMPurify` | HTML sanitization | Client-side / SSR |
| `zod` | Runtime schema validation | Application code |
| `re2` | Safe regex (linear time) | Application code |
| `rate-limiter-flexible` | Advanced rate limiting | Application code |

---

## 8. Incident Response

### Preparation
- [ ] Security logging captures auth events, access denials, input validation failures
- [ ] Structured logging (pino, winston) with correlation IDs — no sensitive data in logs
- [ ] Log aggregation and alerting configured (anomalous patterns, repeated failures)
- [ ] Dependency vulnerability alerts enabled (GitHub Dependabot, Snyk, socket.dev)

### Response Steps
1. **Identify** — Confirm the vulnerability and assess scope
2. **Contain** — Disable affected endpoints, revoke compromised tokens/sessions
3. **Eradicate** — Patch the vulnerability, update dependencies
4. **Recover** — Redeploy, verify fix, rotate secrets if needed
5. **Learn** — Post-incident review, update checklists, add regression tests
