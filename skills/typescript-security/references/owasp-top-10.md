# OWASP Top 10:2025 — TypeScript / JavaScript Security Reference

Reference for AI agents performing TypeScript/JavaScript security reviews, threat modeling, and secure code generation. Covers both server-side (Node.js, Deno, Bun) and client-side (browser) contexts.

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

### TypeScript/JavaScript-Specific Risks

- Missing authorization middleware on routes/endpoints
- Insecure Direct Object References (IDOR): accessing objects by user-supplied ID without ownership check
- Path traversal via unsanitized user input in file operations (`path.join` with `../`)
- Relying solely on client-side or frontend checks (e.g., hiding UI elements instead of enforcing server-side)
- Overly permissive CORS configuration (`origin: '*'` with `credentials: true`)
- Server-Side Request Forgery (SSRF): fetching user-supplied URLs without validation via `fetch()` or `axios`
- JWT manipulation: tampering with tokens, algorithm confusion, missing audience/issuer validation

### Vulnerable Code

```typescript
// IDOR — no ownership verification (Express)
app.get("/api/orders/:orderId", authenticate, async (req, res) => {
  const order = await db.query("SELECT * FROM orders WHERE id = $1", [req.params.orderId]);
  // Any authenticated user can access any order
  res.json(order.rows[0]);
});

// Path traversal
app.get("/files", (req, res) => {
  const filename = req.query.name as string;
  res.sendFile(path.join("/uploads", filename)); // ../../etc/passwd
});

// SSRF — user controls the URL entirely
app.get("/fetch", async (req, res) => {
  const url = req.query.url as string;
  const response = await fetch(url); // Can reach http://169.254.169.254/metadata
  const data = await response.text();
  res.send(data);
});

// Client-side-only access control
// The server has NO auth check — relies on React router guard
app.get("/api/admin/users", async (req, res) => {
  const users = await db.query("SELECT * FROM users");
  res.json(users.rows);
});
```

### Secure Code

```typescript
// Object-level permission check
app.get("/api/orders/:orderId", authenticate, async (req, res) => {
  const order = await db.query(
    "SELECT * FROM orders WHERE id = $1 AND user_id = $2",
    [req.params.orderId, req.user.id]
  );
  if (order.rows.length === 0) {
    return res.status(404).json({ error: "Order not found" });
  }
  res.json(order.rows[0]);
});

// Safe file access with path confinement
app.get("/files", (req, res) => {
  const filename = req.query.name as string;
  const uploadsDir = path.resolve("/uploads");
  const safePath = path.resolve(uploadsDir, filename);
  if (!safePath.startsWith(uploadsDir + path.sep)) {
    return res.status(400).json({ error: "Invalid file path" });
  }
  res.sendFile(safePath);
});

// SSRF protection — validate URL and resolved IP
import { URL } from "node:url";
import dns from "node:dns/promises";
import net from "node:net";

const ALLOWED_SCHEMES = new Set(["https:"]);
const BLOCKED_CIDRS = [
  "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16",
  "127.0.0.0/8", "169.254.0.0/16", "::1/128",
];

function isPrivateIP(ip: string): boolean {
  return net.isIP(ip) !== 0 && BLOCKED_CIDRS.some((cidr) => {
    // Use a CIDR matching library like `ip-cidr` or `netmask`
    // Simplified check shown here
    return ip.startsWith("10.") || ip.startsWith("172.") ||
           ip.startsWith("192.168.") || ip.startsWith("127.") ||
           ip.startsWith("169.254.") || ip === "::1";
  });
}

async function validateUrl(url: string): Promise<boolean> {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  if (!ALLOWED_SCHEMES.has(parsed.protocol)) return false;
  if (!parsed.hostname) return false;
  try {
    const { address } = await dns.lookup(parsed.hostname);
    return !isPrivateIP(address);
  } catch {
    return false;
  }
}

app.get("/fetch", async (req, res) => {
  const url = req.query.url as string;
  if (!(await validateUrl(url))) {
    return res.status(400).json({ error: "URL not allowed" });
  }
  const response = await fetch(url, { redirect: "error" });
  const data = await response.text();
  res.send(data);
});

// Server-side authorization check
app.get("/api/admin/users", authenticate, authorize("admin"), async (req, res) => {
  const users = await db.query("SELECT id, email, role FROM users");
  res.json(users.rows);
});
```

### Mitigation Strategies

- Deny by default; require explicit authorization for every endpoint
- Enforce object-level permission checks (not just role checks)
- Use `path.resolve()` and verify paths start with the expected directory prefix
- Return 404 (not 403) for unauthorized resources to prevent enumeration
- Log and alert on access control failures
- SSRF: validate URLs, block private/internal IPs and cloud metadata endpoints
- SSRF: resolve DNS and validate IP before requests; disable redirects or re-validate
- Never rely on client-side-only access controls — always enforce on the server

---

## A02: Security Misconfiguration

Insecure default configurations, incomplete setup, open cloud storage, misconfigured HTTP headers, verbose error messages, or XXE vulnerabilities. Moved up from #5 in 2021.

### TypeScript/JavaScript-Specific Risks

- `NODE_ENV !== "production"` or left undefined — enables debug features
- Swagger/OpenAPI docs, GraphQL Playground exposed in production
- Express default error handler leaking stack traces
- `express.static()` serving `.env`, `package.json`, or source maps
- Permissive CORS (`origin: "*"` with `credentials: true`)
- Missing security headers (CSP, HSTS, X-Content-Type-Options)
- Default admin credentials in starter templates
- GraphQL introspection enabled in production

### Vulnerable Configuration

```typescript
// Express — INSECURE
const app = express();
// No helmet, no CORS restriction, stack traces exposed
app.use(cors()); // allows all origins
app.use(express.static(".")); // serves everything including .env

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  res.status(500).json({ error: err.message, stack: err.stack }); // stack trace leak
});

// GraphQL — INSECURE: introspection enabled in production
const server = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: true, // should be false in production
});
```

### Secure Configuration

```typescript
import helmet from "helmet";
import cors from "cors";

const app = express();

// Security headers via helmet
app.use(helmet());
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],
    imgSrc: ["'self'", "data:"],
    connectSrc: ["'self'"],
    fontSrc: ["'self'"],
    objectSrc: ["'none'"],
    frameAncestors: ["'none'"],
  },
}));

// Restrictive CORS
app.use(cors({
  origin: ["https://example.com"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE"],
  allowedHeaders: ["Authorization", "Content-Type"],
}));

// Static files from a dedicated public directory only
app.use(express.static("public", { dotfiles: "deny" }));

// Centralized error handler — hide internals in production
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err); // log full error server-side
  res.status(500).json({
    error: process.env.NODE_ENV === "production"
      ? "Internal server error"
      : err.message,
  });
});

// GraphQL — disable introspection in production
const server = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: process.env.NODE_ENV !== "production",
});

// Fastify — secure configuration
import Fastify from "fastify";
import fastifyHelmet from "@fastify/helmet";
import fastifyCors from "@fastify/cors";

const fastify = Fastify({ logger: true });
await fastify.register(fastifyHelmet);
await fastify.register(fastifyCors, {
  origin: ["https://example.com"],
  credentials: true,
});
```

### Mitigation Strategies

- Use `helmet` (Express) or `@fastify/helmet` (Fastify) for security headers
- Set `NODE_ENV=production` in production and conditionally disable debug features
- Serve static files from a dedicated directory; deny dotfiles
- Configure strict CORS with explicit origins — never use `*` with credentials
- Disable GraphQL introspection, Swagger UI, and debug endpoints in production
- Implement centralized error handling that hides internals from users
- Deploy source maps only to error tracking services (Sentry), not to public-facing servers
- Run `npm audit` and review configuration regularly

---

## A03: Software Supply Chain Failures

Covers the entire software supply chain: known vulnerabilities, unpinned dependencies, typosquatting, transitive dependency risks, CI/CD pipeline security, SBOM management, vendor compromise, and malicious packages. The npm ecosystem is particularly vulnerable due to its large size and reliance on postinstall scripts.

### TypeScript/JavaScript-Specific Risks

- Outdated packages with known CVEs in `package.json`
- No lockfile committed or lockfile not used in CI (`npm install` instead of `npm ci`)
- Typosquatting attacks on npm (extremely prevalent — e.g., `lodash` vs `1odash`)
- Malicious postinstall scripts executing arbitrary code on `npm install`
- Transitive dependency vulnerabilities not visible in direct deps
- No Software Bill of Materials (SBOM) for deployed applications
- CI/CD secrets exposed in logs or untrusted workflows
- Self-propagating npm worms (e.g., the 2025 Shai-Hulud attack)
- Using CDN-hosted scripts without Subresource Integrity (SRI)

### Vulnerability Scanning

```bash
# npm audit — built-in package manager auditing
npm audit
npm audit --audit-level=high
npm audit fix

# Snyk — comprehensive scanning
npx snyk test
npx snyk monitor  # continuous monitoring

# Socket.dev — supply chain attack detection
npx socket npm info <package-name>

# Generate CycloneDX SBOM
npx @cyclonedx/cyclonedx-npm --output-file sbom.json
```

### Dependency Pinning

```jsonc
// package.json — pin exact versions
{
  "dependencies": {
    "express": "4.21.2",       // exact version, not "^4.21.2"
    "helmet": "8.0.0"
  }
}
```

```bash
# Always use lockfile in CI/CD
npm ci  # installs from lockfile, fails if lockfile is out of sync

# Ignore scripts for untrusted packages
npm install --ignore-scripts

# Verify package provenance
npm audit signatures
```

### Subresource Integrity (SRI) for Client-Side

```html
<!-- Always use integrity attribute for CDN scripts -->
<script
  src="https://cdn.example.com/lib.min.js"
  integrity="sha384-abc123..."
  crossorigin="anonymous"
></script>
```

### Mitigation Strategies

- Commit lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`)
- Use `npm ci` (not `npm install`) in CI/CD for deterministic builds
- Run `npm audit` or `snyk test` in CI/CD to block vulnerable dependencies
- Enable Dependabot, Renovate, or Socket for automated dependency updates and monitoring
- Use `--ignore-scripts` when installing packages that do not need postinstall hooks
- Verify package names carefully — check download stats, maintainer, and repository on npm
- Use SRI for all CDN-hosted scripts and stylesheets
- Generate and maintain SBOM (CycloneDX or SPDX format)
- Pin CI/CD actions by commit SHA, not mutable tags
- Use `npm audit signatures` to verify package provenance

---

## A04: Cryptographic Failures

Failure to properly protect data in transit and at rest, including use of weak algorithms or poor key management.

### TypeScript/JavaScript-Specific Risks

- Using `Math.random()` for security-sensitive values (predictable PRNG)
- Weak password hashing with `crypto.createHash("md5")` or `crypto.createHash("sha1")`
- Hardcoded secrets, API keys, or encryption keys in source code or client bundles
- Storing sensitive data in `localStorage` or `sessionStorage` (accessible to XSS)
- Disabled TLS verification (`rejectUnauthorized: false`)
- Client-side encryption with hardcoded keys (visible in source/bundle)
- Using deprecated Node.js crypto APIs (e.g., `createCipher` instead of `createCipheriv`)

### Vulnerable Code

```typescript
// Weak random token generation
const token = Math.random().toString(36).substring(2);

// Weak password hashing
import crypto from "node:crypto";
const hash = crypto.createHash("md5").update(password).digest("hex");

// Hardcoded secret
const JWT_SECRET = "super-secret-key-12345";

// Disabled TLS verification
const agent = new https.Agent({ rejectUnauthorized: false });
const response = await fetch(url, { agent });

// Sensitive data in localStorage
localStorage.setItem("authToken", jwt);
localStorage.setItem("creditCard", cardNumber);

// Deprecated crypto API
const cipher = crypto.createCipher("aes-256-cbc", password); // no IV!
```

### Secure Code

```typescript
import crypto from "node:crypto";

// Cryptographically secure random token
const token = crypto.randomUUID();
// or for raw bytes:
const tokenBytes = crypto.randomBytes(32).toString("hex");
// Browser:
const browserToken = globalThis.crypto.randomUUID();

// Strong password hashing with bcrypt
import bcrypt from "bcrypt";
const SALT_ROUNDS = 12;
const hash = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(candidatePassword, hash);

// Alternative: argon2
import argon2 from "argon2";
const hash2 = await argon2.hash(password);
const isValid2 = await argon2.verify(hash2, candidatePassword);

// Secret from environment
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error("JWT_SECRET environment variable required");

// Proper TLS — do not disable verification
const response = await fetch(url); // default TLS verification

// Sensitive data in HttpOnly cookies (not localStorage)
res.cookie("session", sessionId, {
  httpOnly: true,
  secure: true,
  sameSite: "strict",
  maxAge: 3600000,
});

// Modern crypto API with IV
const algorithm = "aes-256-gcm";
const key = crypto.scryptSync(password, salt, 32);
const iv = crypto.randomBytes(16);
const cipher = crypto.createCipheriv(algorithm, key, iv);
```

### Mitigation Strategies

- Use `crypto.randomUUID()`, `crypto.randomBytes()`, or `crypto.getRandomValues()` — never `Math.random()`
- Hash passwords with `bcrypt` (cost factor ≥ 12) or `argon2`
- Store secrets in environment variables or a secret manager — never in source code or client bundles
- Use HttpOnly, Secure, SameSite cookies — never store tokens in `localStorage`
- Never disable TLS verification (`rejectUnauthorized: false`)
- Use `crypto.createCipheriv()` with `aes-256-gcm` — never `createCipher()`
- Use `crypto.timingSafeEqual()` for constant-time comparison of secrets

---

## A05: Injection

Injection occurs when untrusted data is sent to an interpreter and executed as commands. In the TypeScript/JavaScript ecosystem, this includes SQL injection, NoSQL injection, XSS, command injection, and server-side template injection.

### TypeScript/JavaScript-Specific Risks

- SQL injection via template literals or string concatenation
- NoSQL injection via MongoDB operators (`$gt`, `$ne`, `$regex`) in query objects
- Cross-Site Scripting (XSS) via `innerHTML`, `outerHTML`, `document.write()`, `dangerouslySetInnerHTML`
- DOM-based XSS via `location.hash`, `location.search`, `document.referrer`
- Command injection via `child_process.exec()` with user input
- Server-side template injection (SSTI) in EJS, Pug, Handlebars, Nunjucks
- `eval()` / `Function()` constructor with user-controlled input
- ReDoS (Regular Expression Denial of Service) via crafted input
- Header injection via unsanitized user input in HTTP headers
- GraphQL injection via unvalidated query parameters

### Vulnerable Code

```typescript
// SQL injection via template literal
app.get("/users", async (req, res) => {
  const name = req.query.name;
  const result = await db.query(`SELECT * FROM users WHERE name = '${name}'`);
  res.json(result.rows);
});

// NoSQL injection (MongoDB)
app.post("/login", async (req, res) => {
  const user = await User.findOne({
    username: req.body.username,
    password: req.body.password, // attacker sends { "$ne": "" }
  });
  if (user) res.json({ token: generateToken(user) });
});

// XSS via innerHTML
const userComment = getUserInput();
document.getElementById("comments")!.innerHTML = userComment;

// React — XSS via dangerouslySetInnerHTML
function Comment({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: html }} />;
}

// Command injection
app.get("/ping", (req, res) => {
  const host = req.query.host;
  exec(`ping -c 4 ${host}`, (err, stdout) => { // host="; cat /etc/passwd"
    res.send(stdout);
  });
});

// eval with user input
app.get("/calc", (req, res) => {
  const expr = req.query.expression;
  const result = eval(expr); // arbitrary code execution
  res.json({ result });
});

// ReDoS
const EMAIL_REGEX = /^([a-zA-Z0-9_\-\.]+)*@([a-zA-Z0-9_\-\.]+)*\.([a-zA-Z]{2,5})$/;
EMAIL_REGEX.test(userInput); // catastrophic backtracking on crafted input

// Server-side template injection (EJS)
app.get("/greet", (req, res) => {
  const template = `<h1>Hello ${req.query.name}</h1>`; // SSTI if name contains template syntax
  res.render("inline", { body: template });
});
```

### Secure Code

```typescript
// Parameterized SQL query
app.get("/users", async (req, res) => {
  const name = req.query.name;
  const result = await db.query("SELECT * FROM users WHERE name = $1", [name]);
  res.json(result.rows);
});

// ORM with parameterized queries (Prisma)
const users = await prisma.user.findMany({
  where: { name: req.query.name as string },
});

// NoSQL injection prevention — validate input types
import { z } from "zod";

const loginSchema = z.object({
  username: z.string().min(1).max(64),
  password: z.string().min(1).max(128),
});

app.post("/login", async (req, res) => {
  const { username, password } = loginSchema.parse(req.body);
  const user = await User.findOne({ username });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: "Invalid credentials" });
  }
  res.json({ token: generateToken(user) });
});

// XSS prevention — use textContent
const userComment = getUserInput();
document.getElementById("comments")!.textContent = userComment;

// XSS prevention — DOMPurify for trusted HTML
import DOMPurify from "dompurify";
const clean = DOMPurify.sanitize(userComment);
document.getElementById("comments")!.innerHTML = clean;

// React — sanitize before dangerouslySetInnerHTML
import DOMPurify from "dompurify";
function Comment({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }} />;
}

// Safe command execution with execFile (no shell)
import { execFile } from "node:child_process";

app.get("/ping", (req, res) => {
  const host = req.query.host as string;
  if (!/^[a-zA-Z0-9.\-]+$/.test(host)) {
    return res.status(400).json({ error: "Invalid host" });
  }
  execFile("ping", ["-c", "4", host], (err, stdout) => {
    res.send(stdout);
  });
});

// Safe expression evaluation — use a parser library, never eval
import { evaluate } from "mathjs";
app.get("/calc", (req, res) => {
  const expr = req.query.expression as string;
  try {
    const result = evaluate(expr); // mathjs sandboxed evaluation
    res.json({ result });
  } catch {
    res.status(400).json({ error: "Invalid expression" });
  }
});

// Safe regex — use re2 or validate input length
import RE2 from "re2";
const emailRegex = new RE2(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/);

function validateEmail(input: string): boolean {
  if (input.length > 254) return false;
  return emailRegex.test(input);
}
```

### Mitigation Strategies

- Use parameterized queries or ORM methods — never concatenate user input into SQL
- Validate all inputs with schema libraries (Zod, class-validator, joi)
- Use `textContent` instead of `innerHTML`; sanitize HTML with DOMPurify when required
- Use `child_process.execFile()` or `spawn()` with array arguments — never `exec()` with user input
- Never use `eval()`, `Function()`, or `vm.runInNewContext()` with untrusted data
- Use `re2` for regex on untrusted input or enforce strict length limits
- Validate and sanitize data for NoSQL queries — reject objects where strings are expected
- Configure CSP headers to prevent inline scripts and restrict script sources

---

## A06: Insecure Design

A broad category representing missing or ineffective security controls at the design level. Differs from implementation bugs — an insecure design cannot be fixed by a perfect implementation.

### TypeScript/JavaScript-Specific Risks

- No rate limiting on authentication endpoints
- Client-side enforcement of server-side security (hiding admin routes in React router)
- Missing input validation layer at API boundaries
- No abuse case modeling (bots, scalpers, credential stuffing)
- Business logic flaws allowing unlimited resource creation or data export
- WebSocket connections without authentication or rate limiting
- Missing CSRF protection on state-changing endpoints

### Vulnerable Design

```typescript
// No rate limiting — brute-force friendly
app.post("/login", async (req, res) => {
  const { username, password } = req.body;
  const user = await User.findOne({ where: { username } });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: "Invalid credentials" });
  }
  res.json({ token: generateToken(user) });
});

// Client-side-only route protection
// React router guard — no server-side enforcement
<Route path="/admin" element={isAdmin ? <AdminPanel /> : <Navigate to="/" />} />
```

### Secure Design

```typescript
// Rate limiting on authentication endpoints
import rateLimit from "express-rate-limit";

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: { error: "Too many login attempts, please try again later" },
  standardHeaders: true,
  legacyHeaders: false,
});

app.post("/login", loginLimiter, async (req, res) => {
  const { username, password } = loginSchema.parse(req.body);
  const user = await User.findOne({ where: { username } });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: "Invalid credentials" });
  }
  res.json({ token: generateToken(user) });
});

// Server-side authorization — defense in depth
// Even with client route guards, always enforce on the server
app.get("/api/admin/*", authenticate, authorize("admin"), adminRouter);
```

### Mitigation Strategies

- Implement rate limiting on all authentication, password reset, and high-value endpoints
- Always enforce authorization on the server — client-side guards are for UX only
- Use threat modeling for critical business flows (authentication, payment, data export)
- Add CSRF protection via tokens or SameSite cookies
- Validate and limit resource creation (file uploads, API keys, account creation)
- Add abuse detection for bots and automated attacks
- Authenticate and rate-limit WebSocket connections

---

## A07: Authentication Failures

When attackers can trick a system into recognizing an invalid or incorrect user as legitimate.

### TypeScript/JavaScript-Specific Risks

- JWT `algorithm: "none"` — accepting unsigned tokens
- JWT HS256 with a public key (algorithm confusion attack)
- Weak session secrets or default signing keys
- Storing JWTs in `localStorage` (vulnerable to XSS)
- No brute-force protection on login endpoints
- Session IDs not regenerated after login
- Missing token expiration or overly long-lived tokens
- Password reset tokens that don't expire

### Vulnerable Code

```typescript
// JWT — INSECURE: not specifying algorithms allows "none"
import jwt from "jsonwebtoken";

const payload = jwt.verify(token, publicKey); // accepts algorithm: "none"

// JWT in localStorage
localStorage.setItem("token", jwt);
// Sent via Authorization header — accessible to XSS
fetch("/api/data", { headers: { Authorization: `Bearer ${localStorage.getItem("token")}` } });

// No session regeneration after login (express-session)
app.post("/login", async (req, res) => {
  const user = await validateCredentials(req.body);
  if (user) {
    req.session.userId = user.id; // session fixation: ID not regenerated
    res.json({ success: true });
  }
});

// Weak session secret
app.use(session({ secret: "keyboard cat" }));
```

### Secure Code

```typescript
import jwt from "jsonwebtoken";

// JWT — SECURE: explicit algorithm restriction
const payload = jwt.verify(token, publicKey, {
  algorithms: ["RS256"],        // explicit allowlist
  audience: "https://api.example.com",
  issuer: "https://auth.example.com",
  clockTolerance: 30,          // 30 seconds tolerance
});

// JWT — sign with explicit algorithm
const token = jwt.sign(
  { sub: user.id, role: user.role },
  privateKey,
  { algorithm: "RS256", expiresIn: "15m" }
);

// Store tokens in HttpOnly cookies (not localStorage)
res.cookie("token", token, {
  httpOnly: true,
  secure: true,
  sameSite: "strict",
  maxAge: 15 * 60 * 1000, // 15 minutes
  path: "/",
});

// Session regeneration after login (express-session)
app.post("/login", async (req, res) => {
  const user = await validateCredentials(req.body);
  if (user) {
    req.session.regenerate((err) => {
      if (err) return res.status(500).json({ error: "Session error" });
      req.session.userId = user.id;
      req.session.save((err) => {
        if (err) return res.status(500).json({ error: "Session error" });
        res.json({ success: true });
      });
    });
  }
});

// Strong session secret
app.use(session({
  secret: process.env.SESSION_SECRET!, // from env or secret manager
  name: "__Host-sid",
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: true,
    sameSite: "strict",
    maxAge: 3600000,
  },
}));
```

### Mitigation Strategies

- Always specify `algorithms` in `jwt.verify()` — never rely on defaults
- Validate `aud`, `iss`, and `exp` claims in JWTs
- Store tokens in HttpOnly, Secure, SameSite cookies — not `localStorage`
- Regenerate session IDs after login to prevent session fixation
- Use strong, random session secrets from environment variables
- Implement rate limiting on login, registration, and password reset endpoints
- Enforce multi-factor authentication where possible
- Set appropriate token expiration (short-lived access tokens, refresh token rotation)

---

## A08: Software or Data Integrity Failures

Failures related to code and infrastructure that does not protect against invalid or untrusted code or data being treated as trusted.

### TypeScript/JavaScript-Specific Risks

- Prototype pollution via `Object.assign()`, spread operators, or deep merge with untrusted objects
- Unsafe deserialization (`node-serialize`, `serialize-javascript` with untrusted data)
- CDN scripts without Subresource Integrity (SRI)
- CI/CD pipelines pulling from untrusted sources without verification
- `JSON.parse()` on untrusted input without subsequent schema validation
- Mass assignment: blindly passing request body to ORM create/update methods

### Vulnerable Code

```typescript
// Prototype pollution via deep merge
function deepMerge(target: any, source: any): any {
  for (const key of Object.keys(source)) {
    if (typeof source[key] === "object" && source[key] !== null) {
      target[key] = deepMerge(target[key] || {}, source[key]);
    } else {
      target[key] = source[key]; // __proto__.isAdmin = true
    }
  }
  return target;
}

app.put("/settings", (req, res) => {
  const settings = deepMerge(defaultSettings, req.body);
  // Attacker sends: { "__proto__": { "isAdmin": true } }
  res.json(settings);
});

// Unsafe deserialization
import serialize from "node-serialize";
const obj = serialize.unserialize(req.body.data); // RCE via IIFE in serialized string

// Mass assignment
app.put("/users/:id", async (req, res) => {
  await User.update(req.body, { where: { id: req.params.id } }); // updates ANY field including role
  res.json({ success: true });
});

// CDN without SRI
// <script src="https://cdn.example.com/lib.js"></script>
```

### Secure Code

```typescript
// Prototype pollution prevention — validate keys
function safeMerge(target: Record<string, unknown>, source: Record<string, unknown>): Record<string, unknown> {
  const result = Object.create(null); // no prototype
  Object.assign(result, target);
  for (const key of Object.keys(source)) {
    if (key === "__proto__" || key === "constructor" || key === "prototype") {
      continue; // skip dangerous keys
    }
    result[key] = source[key];
  }
  return result;
}

// Schema validation prevents prototype pollution
import { z } from "zod";
const settingsSchema = z.object({
  theme: z.enum(["light", "dark"]),
  language: z.string().max(5),
  notifications: z.boolean(),
});

app.put("/settings", (req, res) => {
  const settings = settingsSchema.parse(req.body); // rejects unexpected fields
  res.json(settings);
});

// Safe deserialization — always use JSON.parse + schema validation
app.post("/data", (req, res) => {
  const data = dataSchema.parse(req.body); // JSON parsed by express, validated by Zod
  res.json(data);
});

// Allowlisted fields for update (prevent mass assignment)
const updateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  // role is NOT included — cannot be set by user
});

app.put("/users/:id", authenticate, async (req, res) => {
  const data = updateUserSchema.parse(req.body);
  await User.update(data, { where: { id: req.params.id, userId: req.user.id } });
  res.json({ success: true });
});
```

```html
<!-- CDN with SRI -->
<script
  src="https://cdn.example.com/lib.min.js"
  integrity="sha384-abc123..."
  crossorigin="anonymous"
></script>
```

### Mitigation Strategies

- Guard against prototype pollution: validate/strip `__proto__`, `constructor`, `prototype` keys, or use `Object.create(null)`
- Use schema validation (Zod, class-validator) on all user input — rejects unexpected fields
- Never use `node-serialize` or similar unsafe deserialization on untrusted data
- Use SRI for all CDN-hosted scripts and stylesheets
- Allowlist fields for database create/update operations (prevent mass assignment)
- Pin CI/CD actions by commit SHA; verify artifact integrity

---

## A09: Security Logging and Alerting Failures

Without logging and monitoring, attacks and breaches cannot be detected. Without alerting, response is delayed.

### TypeScript/JavaScript-Specific Risks

- Using `console.log` in production without structured logging
- Logging passwords, tokens, API keys, credit card numbers, or PII
- No logging of authentication events (login, logout, failed attempts)
- Missing alerting on suspicious activity (brute-force, unusual access patterns)
- Log injection via unsanitized user input in log messages
- No audit trail for sensitive operations (permission changes, data export)

### Vulnerable Code

```typescript
// Logging sensitive data
app.post("/login", async (req, res) => {
  console.log(`Login attempt: ${req.body.username} / ${req.body.password}`); // password logged!
  // ...
});

// No structured logging
console.log("User " + userId + " accessed record " + recordId);

// Log injection
const username = req.body.username; // attacker sends "admin\n[ERROR] Unauthorized access by root"
console.log(`Login attempt by ${username}`); // log forging
```

### Secure Code

```typescript
import pino from "pino";

const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  redact: {
    paths: ["password", "token", "authorization", "cookie", "creditCard", "ssn"],
    censor: "[REDACTED]",
  },
  serializers: {
    req: pino.stdSerializers.req,
    err: pino.stdSerializers.err,
  },
});

// Structured logging with field filtering
app.post("/login", async (req, res) => {
  const { username } = loginSchema.parse(req.body);
  logger.info({ event: "login_attempt", username }, "Login attempt");

  const user = await validateCredentials(req.body);
  if (!user) {
    logger.warn(
      { event: "login_failure", username, ip: req.ip },
      "Failed login attempt"
    );
    return res.status(401).json({ error: "Invalid credentials" });
  }

  logger.info({ event: "login_success", userId: user.id }, "Successful login");
  res.json({ token: generateToken(user) });
});

// Log injection prevention — sanitize user input in logs
function sanitizeForLog(input: string): string {
  return input.replace(/[\n\r\t]/g, "");
}

// Audit trail for sensitive operations
app.put("/users/:id/role", authenticate, authorize("admin"), async (req, res) => {
  const { role } = roleUpdateSchema.parse(req.body);
  await User.update({ role }, { where: { id: req.params.id } });

  logger.info({
    event: "role_change",
    targetUser: req.params.id,
    newRole: role,
    changedBy: req.user.id,
    ip: req.ip,
  }, "User role updated");

  res.json({ success: true });
});
```

### Mitigation Strategies

- Use structured logging (pino, winston) — not `console.log` in production
- Redact sensitive fields (passwords, tokens, PII) from all log output
- Log authentication events (login, logout, failed attempts) with user context
- Sanitize user input before including in log messages to prevent log injection
- Set up alerting for brute-force attempts, unusual access patterns, and access control failures
- Maintain audit trails for permission changes, data access, and administrative actions
- Use centralized log management (ELK, Datadog, Grafana Loki) with alerting

---

## A10: Mishandling of Exceptional Conditions

Programs fail to prevent, detect, and respond to unusual and unpredictable situations, leading to crashes, unexpected behavior, and vulnerabilities. New category for 2025.

### TypeScript/JavaScript-Specific Risks

- Unhandled promise rejections crashing the process (`node` terminates by default since v15)
- Empty `catch {}` blocks swallowing errors silently
- Failing open on authentication/authorization errors
- Sensitive information (stack traces, paths, config) in error responses
- Missing `finally` blocks for resource cleanup
- Uncaught exceptions in async middleware (Express does not catch async errors by default)
- Missing `default` case in `switch` statements
- Type coercion errors (`undefined` treated as falsy bypassing checks)

### Vulnerable Code

```typescript
// Empty catch — swallowed error, application may be in broken state
try {
  await processPayment(order);
} catch (e) {
  // silently ignored — payment may have partially completed
}

// Failing open — auth error grants access
async function checkPermission(userId: string, resource: string): Promise<boolean> {
  try {
    const result = await db.query("SELECT allowed FROM acl WHERE user_id = $1 AND resource = $2", [userId, resource]);
    return result.rows[0]?.allowed === true;
  } catch (err) {
    return true; // Database error? Grant access anyway — WRONG
  }
}

// Sensitive data in error response
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  res.status(500).json({
    error: err.message,
    stack: err.stack,        // internal paths, line numbers
    query: (err as any).sql, // SQL query leaked
  });
});

// Unhandled async error in Express
app.get("/data", async (req, res) => {
  const data = await fetchData(); // if this rejects, Express 4 doesn't catch it
  res.json(data);
});

// Missing default in switch
function getDiscount(tier: string): number {
  switch (tier) {
    case "gold": return 0.2;
    case "silver": return 0.1;
    // missing default — undefined discount if tier is unexpected
  }
}
```

### Secure Code

```typescript
// Proper error handling with logging and rollback
try {
  await processPayment(order);
} catch (err) {
  logger.error({ err, orderId: order.id }, "Payment processing failed");
  await rollbackOrder(order.id);
  throw err; // re-throw to central error handler
}

// Failing closed — deny access on error
async function checkPermission(userId: string, resource: string): Promise<boolean> {
  try {
    const result = await db.query("SELECT allowed FROM acl WHERE user_id = $1 AND resource = $2", [userId, resource]);
    return result.rows[0]?.allowed === true;
  } catch (err) {
    logger.error({ err, userId, resource }, "Permission check failed");
    return false; // Fail closed — deny access on error
  }
}

// Safe error response — hide internals
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error({ err, url: req.url, method: req.method }, "Unhandled error");

  const statusCode = "statusCode" in err ? (err as any).statusCode : 500;
  res.status(statusCode).json({
    error: statusCode === 500 ? "Internal server error" : err.message,
  });
});

// Async error wrapper for Express 4
function asyncHandler(fn: (req: Request, res: Response, next: NextFunction) => Promise<void>) {
  return (req: Request, res: Response, next: NextFunction) => {
    fn(req, res, next).catch(next);
  };
}

app.get("/data", asyncHandler(async (req, res) => {
  const data = await fetchData();
  res.json(data);
}));

// Express 5+ handles async errors automatically
// Fastify handles async errors automatically

// Global unhandled rejection handler
process.on("unhandledRejection", (reason, promise) => {
  logger.fatal({ reason }, "Unhandled promise rejection — shutting down");
  process.exit(1);
});

process.on("uncaughtException", (err) => {
  logger.fatal({ err }, "Uncaught exception — shutting down");
  process.exit(1);
});

// Exhaustive switch with default
function getDiscount(tier: string): number {
  switch (tier) {
    case "gold": return 0.2;
    case "silver": return 0.1;
    case "bronze": return 0.05;
    default: return 0; // explicit default
  }
}

// TypeScript exhaustive check
type Tier = "gold" | "silver" | "bronze";
function getDiscountExhaustive(tier: Tier): number {
  switch (tier) {
    case "gold": return 0.2;
    case "silver": return 0.1;
    case "bronze": return 0.05;
    default: {
      const _exhaustive: never = tier;
      throw new Error(`Unknown tier: ${_exhaustive}`);
    }
  }
}
```

### Mitigation Strategies

- Always handle promise rejections — use `catch()` or async error wrappers
- Fail closed (deny) on authorization/authentication errors — never grant access on failure
- Use centralized error handlers that log the full error but return generic messages to users
- Register `process.on("unhandledRejection")` and `process.on("uncaughtException")` handlers
- Use `finally` blocks for resource cleanup (connections, file handles)
- Add `default` cases to all `switch` statements; use TypeScript exhaustive checks with `never`
- Use Express 5+ or Fastify (which handle async errors automatically) or async wrappers for Express 4
- Implement rate limiting and resource quotas to prevent error-based DoS
- Roll back transactions on failure — never leave partial operations in place
