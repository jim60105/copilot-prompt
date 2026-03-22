# TypeScript / JavaScript Secure Coding Reference

> Reference for AI agents implementing secure TypeScript/JavaScript code. Use imperative patterns; prefer allowlisting, least privilege, and defense in depth. Covers both server-side (Node.js, Deno, Bun) and client-side (browser) contexts.

## Table of Contents

- [1. Input Validation and Sanitization](#1-input-validation-and-sanitization)
- [2. Authentication and Authorization Patterns](#2-authentication-and-authorization-patterns)
- [3. Cryptography Best Practices](#3-cryptography-best-practices)
- [4. Secure Data Handling](#4-secure-data-handling)
- [5. DOM Security and XSS Prevention](#5-dom-security-and-xss-prevention)
- [6. File and Path Operations](#6-file-and-path-operations)
- [7. Subprocess and System Interaction](#7-subprocess-and-system-interaction)
- [8. Serialization and Prototype Pollution](#8-serialization-and-prototype-pollution)
- [9. Web Framework Security](#9-web-framework-security)
- [10. Error Handling and Information Disclosure](#10-error-handling-and-information-disclosure)

---

## 1. Input Validation and Sanitization

Validate all inputs at the boundary using allowlists and strict schema validation. Reject anything not explicitly permitted.

### Schema Validation with Zod

```typescript
// ❌ Anti-pattern: manual validation
function processUser(body: any) {
  const name = body.name; // no validation
  const age = Number(body.age); // NaN if invalid
}

// ✅ Correct: schema validation with Zod
import { z } from "zod";

const userSchema = z.object({
  name: z.string().min(1).max(100).regex(/^[a-zA-Z0-9_\- ]+$/),
  age: z.number().int().min(0).max(150),
  email: z.string().email().max(254),
});

function processUser(body: unknown) {
  const user = userSchema.parse(body); // throws ZodError on invalid input
  // user is now fully typed and validated
}
```

### Schema Validation with class-validator (NestJS)

```typescript
import { IsString, IsEmail, IsInt, Min, Max, MinLength, MaxLength, Matches } from "class-validator";

class CreateUserDto {
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  @Matches(/^[a-zA-Z0-9_\- ]+$/)
  name!: string;

  @IsInt()
  @Min(0)
  @Max(150)
  age!: number;

  @IsEmail()
  @MaxLength(254)
  email!: string;
}
```

### Allowlisting vs Denylisting

```typescript
// ❌ Anti-pattern: denylisting dangerous characters
function sanitize(value: string): string {
  return value.replace(/[<>&'"]/g, "");
}

// ✅ Correct: allowlist permitted characters
function validateUsername(value: string): string {
  if (!/^[a-zA-Z0-9_\-]{3,32}$/.test(value)) {
    throw new Error("Invalid username");
  }
  return value;
}
```

### Type Coercion Safety

```typescript
// ❌ Anti-pattern: loose equality allows type coercion bypass
if (req.query.admin == true) { grant(); }   // "true" == true → type coercion
if (req.query.id != null) { process(); }    // may pass undefined checks unexpectedly

// ✅ Correct: strict equality, explicit type checks
if (req.query.admin === "true" && user.role === "admin") { grant(); }
if (typeof req.query.id === "string" && req.query.id.length > 0) { process(); }
```

### ReDoS Prevention

```typescript
// ❌ Anti-pattern: catastrophic backtracking
const pattern = /^([a-zA-Z0-9_\-\.]+)*@([a-zA-Z0-9_\-\.]+)*\.([a-zA-Z]{2,})$/;
pattern.test(userInput); // exponential time on crafted input

// ✅ Correct: use RE2 (linear-time guarantees) or enforce length limits
import RE2 from "re2";
const safePattern = new RE2(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/);

function safeMatch(pattern: RE2, value: string, maxLen = 1000): boolean {
  if (value.length > maxLen) throw new Error("Input too long");
  return pattern.test(value);
}
```

### File Upload Validation

```typescript
// ❌ Anti-pattern: trust file extension and user-supplied name
app.post("/upload", (req, res) => {
  const file = req.file!;
  fs.writeFileSync(`/uploads/${file.originalname}`, file.buffer); // path traversal + type bypass
});

// ✅ Correct: validate type, size, and sanitize name
import { randomUUID } from "node:crypto";
import { fileTypeFromBuffer } from "file-type";

const ALLOWED_TYPES = new Set(["image/png", "image/jpeg", "application/pdf"]);
const MAX_SIZE = 10 * 1024 * 1024; // 10 MB

async function saveUpload(buffer: Buffer, originalName: string, uploadDir: string): Promise<string> {
  if (buffer.length > MAX_SIZE) throw new Error("File too large");

  const type = await fileTypeFromBuffer(buffer);
  if (!type || !ALLOWED_TYPES.has(type.mime)) {
    throw new Error(`Disallowed file type: ${type?.mime ?? "unknown"}`);
  }

  const ext = path.extname(originalName).toLowerCase();
  if (![".png", ".jpg", ".jpeg", ".pdf"].includes(ext)) {
    throw new Error("Invalid extension");
  }

  const safeName = `${randomUUID()}${ext}`;
  const dest = path.join(uploadDir, safeName);
  await fs.promises.writeFile(dest, buffer);
  return safeName;
}
```

---

## 2. Authentication and Authorization Patterns

### JWT Validation

```typescript
// ❌ Anti-pattern: no algorithm restriction, no audience/issuer validation
const payload = jwt.verify(token, secret);

// ✅ Correct: explicit algorithm, audience, issuer
import jwt from "jsonwebtoken";

const payload = jwt.verify(token, publicKey, {
  algorithms: ["RS256"],
  audience: "https://api.example.com",
  issuer: "https://auth.example.com",
  clockTolerance: 30,
});
```

### Password Hashing

```typescript
// ❌ Anti-pattern: weak hashing
import crypto from "node:crypto";
const hash = crypto.createHash("sha256").update(password).digest("hex");

// ✅ Correct: bcrypt with appropriate cost factor
import bcrypt from "bcrypt";
const SALT_ROUNDS = 12;
const hash = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(candidatePassword, hash);

// ✅ Alternative: argon2
import argon2 from "argon2";
const hash2 = await argon2.hash(password, {
  type: argon2.argon2id,
  memoryCost: 65536,
  timeCost: 3,
  parallelism: 4,
});
const isValid2 = await argon2.verify(hash2, candidatePassword);
```

### Centralized Authorization Middleware

```typescript
// ❌ Anti-pattern: scattered auth checks
app.get("/admin/users", async (req, res) => {
  if (req.user?.role !== "admin") return res.status(403).end();
  // ... handler logic
});

// ✅ Correct: centralized middleware
function authorize(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) return res.status(401).json({ error: "Unauthorized" });
    if (roles.length > 0 && !roles.includes(req.user.role)) {
      return res.status(403).json({ error: "Forbidden" });
    }
    next();
  };
}

app.get("/admin/users", authenticate, authorize("admin"), adminUsersHandler);
app.put("/profile", authenticate, authorize(), profileUpdateHandler);
```

### Session Management

```typescript
import session from "express-session";
import RedisStore from "connect-redis";
import { createClient } from "redis";

const redisClient = createClient();
await redisClient.connect();

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET!,
  name: "__Host-sid",
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: true,
    sameSite: "strict",
    maxAge: 3600000, // 1 hour
    path: "/",
  },
}));

// Regenerate session ID on login
app.post("/login", async (req, res) => {
  const user = await validateCredentials(req.body);
  if (!user) return res.status(401).json({ error: "Invalid credentials" });

  req.session.regenerate((err) => {
    if (err) return res.status(500).json({ error: "Session error" });
    req.session.userId = user.id;
    req.session.save((err) => {
      if (err) return res.status(500).json({ error: "Session error" });
      res.json({ success: true });
    });
  });
});

// Destroy session on logout
app.post("/logout", (req, res) => {
  req.session.destroy((err) => {
    if (err) return res.status(500).json({ error: "Logout failed" });
    res.clearCookie("__Host-sid");
    res.json({ success: true });
  });
});
```

---

## 3. Cryptography Best Practices

### Secure Random Values

```typescript
import crypto from "node:crypto";

// ❌ Anti-pattern: predictable values
const token = Math.random().toString(36).substring(2);
const id = Date.now().toString();

// ✅ Correct: cryptographic random
const token = crypto.randomUUID();
const tokenHex = crypto.randomBytes(32).toString("hex");
const tokenUrlSafe = crypto.randomBytes(32).toString("base64url");

// Browser context
const browserToken = globalThis.crypto.randomUUID();
const randomArray = new Uint8Array(32);
globalThis.crypto.getRandomValues(randomArray);
```

### Symmetric Encryption

```typescript
import crypto from "node:crypto";

// ❌ Anti-pattern: deprecated createCipher (no IV, insecure)
const cipher = crypto.createCipher("aes-256-cbc", password);

// ✅ Correct: AES-256-GCM with random IV
function encrypt(plaintext: string, key: Buffer): { iv: string; data: string; tag: string } {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  return {
    iv: iv.toString("hex"),
    data: encrypted.toString("hex"),
    tag: tag.toString("hex"),
  };
}

function decrypt(encrypted: { iv: string; data: string; tag: string }, key: Buffer): string {
  const decipher = crypto.createDecipheriv(
    "aes-256-gcm",
    key,
    Buffer.from(encrypted.iv, "hex")
  );
  decipher.setAuthTag(Buffer.from(encrypted.tag, "hex"));
  return decipher.update(encrypted.data, "hex", "utf8") + decipher.final("utf8");
}
```

### Constant-Time Comparison

```typescript
import crypto from "node:crypto";

// ❌ Anti-pattern: timing attack vulnerable
if (providedToken === expectedToken) { /* ... */ }

// ✅ Correct: constant-time comparison
function safeCompare(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b));
}
```

### Key Derivation

```typescript
import crypto from "node:crypto";

// Derive encryption key from password + salt
const salt = crypto.randomBytes(16);
const key = crypto.scryptSync(password, salt, 32); // 32 bytes = 256 bits
// async version:
crypto.scrypt(password, salt, 32, (err, key) => { /* ... */ });
```

---

## 4. Secure Data Handling

### Secrets Management

```typescript
// ❌ Anti-pattern: hardcoded secrets
const API_KEY = "sk_live_abc123";
const DB_PASSWORD = "supersecret";

// ✅ Correct: environment variables with validation
const requiredEnv = (name: string): string => {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
};

const config = {
  apiKey: requiredEnv("API_KEY"),
  dbUrl: requiredEnv("DATABASE_URL"),
  jwtSecret: requiredEnv("JWT_SECRET"),
} as const;

// Never log or expose config values
```

### Cookie Security

```typescript
// ❌ Anti-pattern: insecure cookies
res.cookie("session", token);
res.cookie("prefs", data, { httpOnly: false });

// ✅ Correct: secure cookie settings
res.cookie("session", token, {
  httpOnly: true,     // not accessible via JavaScript
  secure: true,       // HTTPS only
  sameSite: "strict", // CSRF protection
  maxAge: 3600000,    // 1 hour
  path: "/",
  domain: ".example.com",
});
```

### Sensitive Data in Client Bundles

```typescript
// ❌ Anti-pattern: secrets in client-side code
// .env or hardcoded — these end up in the browser bundle
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY; // in Next.js client component

// ✅ Correct: only public keys in client bundles
// Use NEXT_PUBLIC_ prefix (Next.js) for intentionally public values only
const STRIPE_PUBLIC_KEY = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
// Keep secret keys server-side only (API routes, server components, getServerSideProps)
```

---

## 5. DOM Security and XSS Prevention

### Safe DOM Manipulation

```typescript
// ❌ Anti-pattern: innerHTML with untrusted content
element.innerHTML = userInput; // XSS
document.write(userInput);     // XSS
element.outerHTML = userInput;  // XSS
element.insertAdjacentHTML("beforeend", userInput); // XSS

// ✅ Correct: use textContent for plain text
element.textContent = userInput; // safe — rendered as text, not HTML

// ✅ Correct: use DOMPurify when HTML rendering is required
import DOMPurify from "dompurify";
element.innerHTML = DOMPurify.sanitize(userInput);

// ✅ Correct: use DOM API for structured content
const link = document.createElement("a");
link.textContent = userInput;
link.href = sanitizeUrl(userInput); // validate URL scheme
container.appendChild(link);
```

### React XSS Prevention

```tsx
// ❌ Anti-pattern: dangerouslySetInnerHTML without sanitization
function Comment({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: html }} />;
}

// ✅ Correct: sanitize with DOMPurify
import DOMPurify from "dompurify";
function Comment({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }} />;
}

// ✅ Best: avoid dangerouslySetInnerHTML entirely — use markdown-to-JSX or similar
import ReactMarkdown from "react-markdown";
function Comment({ markdown }: { markdown: string }) {
  return <ReactMarkdown>{markdown}</ReactMarkdown>;
}
```

### URL Sanitization

```typescript
// ❌ Anti-pattern: arbitrary URLs including javascript:
<a href={userUrl}>Click</a>

// ✅ Correct: validate URL scheme
function sanitizeUrl(url: string): string {
  try {
    const parsed = new URL(url);
    if (!["https:", "http:", "mailto:"].includes(parsed.protocol)) {
      return "#";
    }
    return parsed.href;
  } catch {
    return "#";
  }
}
```

### Content Security Policy

```typescript
// Express with helmet
import helmet from "helmet";

app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],                     // no 'unsafe-inline', no 'unsafe-eval'
    styleSrc: ["'self'", "'unsafe-inline'"],    // inline styles if needed
    imgSrc: ["'self'", "data:", "https:"],
    connectSrc: ["'self'", "https://api.example.com"],
    fontSrc: ["'self'"],
    objectSrc: ["'none'"],
    frameSrc: ["'none'"],
    frameAncestors: ["'none'"],
    baseUri: ["'self'"],
    formAction: ["'self'"],
    upgradeInsecureRequests: [],
  },
}));
```

### postMessage Security

```typescript
// ❌ Anti-pattern: no origin check
window.addEventListener("message", (event) => {
  processData(event.data); // accepts messages from any origin
});

// ✅ Correct: verify origin
window.addEventListener("message", (event) => {
  if (event.origin !== "https://trusted.example.com") return;
  const data = messageSchema.parse(event.data); // validate structure too
  processData(data);
});

// ✅ Correct: specify target origin when sending
targetWindow.postMessage(data, "https://trusted.example.com");
// NEVER use "*" for targetOrigin with sensitive data
```

---

## 6. File and Path Operations

### Path Traversal Prevention

```typescript
import path from "node:path";
import fs from "node:fs/promises";

// ❌ Anti-pattern: user input directly in path
app.get("/download", async (req, res) => {
  const filePath = path.join("/uploads", req.query.file as string);
  res.sendFile(filePath); // ../../../etc/passwd
});

// ✅ Correct: resolve and verify containment
app.get("/download", async (req, res) => {
  const filename = req.query.file as string;
  const baseDir = path.resolve("/uploads");
  const resolved = path.resolve(baseDir, filename);

  if (!resolved.startsWith(baseDir + path.sep)) {
    return res.status(400).json({ error: "Invalid file path" });
  }

  try {
    await fs.access(resolved);
    res.sendFile(resolved);
  } catch {
    res.status(404).json({ error: "File not found" });
  }
});
```

### Temp File Security

```typescript
import os from "node:os";
import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";

// ✅ Correct: unique temp directory with cleanup
async function withTempDir<T>(fn: (dir: string) => Promise<T>): Promise<T> {
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "app-"));
  try {
    return await fn(tmpDir);
  } finally {
    await fs.rm(tmpDir, { recursive: true, force: true });
  }
}
```

---

## 7. Subprocess and System Interaction

### Safe Command Execution

```typescript
import { execFile, spawn } from "node:child_process";

// ❌ Anti-pattern: shell injection via exec
import { exec } from "node:child_process";
exec(`ping -c 4 ${userInput}`); // command injection
exec(`convert ${inputFile} ${outputFile}`, { shell: true }); // shell injection

// ✅ Correct: execFile with array arguments (no shell)
execFile("ping", ["-c", "4", validatedHost], (err, stdout, stderr) => {
  if (err) { /* handle error */ }
});

// ✅ Correct: spawn with array arguments
const child = spawn("convert", [inputFile, outputFile]); // no shell
child.on("error", (err) => { /* handle error */ });

// ✅ Correct: if shell is absolutely necessary, validate input strictly
const HOSTNAME_REGEX = /^[a-zA-Z0-9.\-]+$/;
if (!HOSTNAME_REGEX.test(host)) {
  throw new Error("Invalid hostname");
}
execFile("ping", ["-c", "4", host]);
```

### Environment Variable Injection Prevention

```typescript
// ❌ Anti-pattern: passing user input as env vars to subprocess
execFile("cmd", args, { env: { ...process.env, USER_INPUT: req.body.input } });

// ✅ Correct: validate and sanitize environment variables
const sanitizedInput = allowedValues.includes(req.body.input)
  ? req.body.input
  : "default";
execFile("cmd", args, { env: { ...process.env, CONFIG_MODE: sanitizedInput } });
```

---

## 8. Serialization and Prototype Pollution

### Prototype Pollution Prevention

```typescript
// ❌ Anti-pattern: recursive merge without key filtering
function merge(target: any, source: any): any {
  for (const key in source) {
    if (typeof source[key] === "object") {
      target[key] = merge(target[key] || {}, source[key]);
    } else {
      target[key] = source[key];
    }
  }
  return target;
}
// Attacker sends: { "__proto__": { "isAdmin": true } }

// ✅ Correct: use Zod to validate shape, or filter dangerous keys
const FORBIDDEN_KEYS = new Set(["__proto__", "constructor", "prototype"]);

function safeMerge(target: Record<string, unknown>, source: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = Object.create(null);
  for (const key of Object.keys(target)) {
    result[key] = target[key];
  }
  for (const key of Object.keys(source)) {
    if (FORBIDDEN_KEYS.has(key)) continue;
    result[key] = source[key];
  }
  return result;
}

// ✅ Best: use schema validation — Zod rejects unknown fields
import { z } from "zod";
const settingsSchema = z.object({
  theme: z.enum(["light", "dark"]),
  language: z.string().max(5),
}).strict(); // rejects any extra fields including __proto__
```

### Safe JSON Handling

```typescript
// ❌ Anti-pattern: JSON.parse without validation
const data = JSON.parse(untrustedString);
doSomething(data.criticalField); // could be any type

// ✅ Correct: parse then validate with schema
const raw = JSON.parse(untrustedString); // syntactic parsing
const data = mySchema.parse(raw);         // semantic validation
```

### Avoiding Unsafe Deserialization

```typescript
// ❌ NEVER: node-serialize, serialize-javascript with untrusted data
import serialize from "node-serialize";
const obj = serialize.unserialize(userInput); // RCE

// ✅ Correct: use JSON.parse + schema validation
const obj = JSON.parse(userInput); // safe: no code execution
const validated = schema.parse(obj); // type-safe and validated
```

---

## 9. Web Framework Security

### Express Security Best Practices

```typescript
import express from "express";
import helmet from "helmet";
import cors from "cors";
import rateLimit from "express-rate-limit";

const app = express();

// Security headers
app.use(helmet());

// Body size limits
app.use(express.json({ limit: "100kb" }));
app.use(express.urlencoded({ extended: false, limit: "100kb" }));

// Rate limiting
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
}));

// CORS
app.use(cors({
  origin: ["https://example.com"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE"],
}));

// Disable X-Powered-By (helmet does this too)
app.disable("x-powered-by");

// Trust proxy (when behind reverse proxy)
app.set("trust proxy", 1); // trust first proxy
```

### Fastify Security Best Practices

```typescript
import Fastify from "fastify";
import fastifyHelmet from "@fastify/helmet";
import fastifyCors from "@fastify/cors";
import fastifyRateLimit from "@fastify/rate-limit";

const app = Fastify({
  logger: true,
  bodyLimit: 102400, // 100kb
  trustProxy: true,
});

await app.register(fastifyHelmet);
await app.register(fastifyCors, {
  origin: ["https://example.com"],
  credentials: true,
});
await app.register(fastifyRateLimit, {
  max: 100,
  timeWindow: "15 minutes",
});
```

### NestJS Security Best Practices

```typescript
import { NestFactory } from "@nestjs/core";
import { ValidationPipe } from "@nestjs/common";
import helmet from "helmet";

const app = await NestFactory.create(AppModule);

app.use(helmet());
app.enableCors({
  origin: ["https://example.com"],
  credentials: true,
});
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,         // strip unrecognized properties
  forbidNonWhitelisted: true, // reject if unknown props present
  transform: true,
}));
```

### Next.js Security Best Practices

```typescript
// next.config.js — security headers
const nextConfig = {
  poweredByHeader: false,
  headers: async () => [{
    source: "/(.*)",
    headers: [
      { key: "X-Content-Type-Options", value: "nosniff" },
      { key: "X-Frame-Options", value: "DENY" },
      { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
      { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
    ],
  }],
  // Do NOT expose source maps in production
  productionBrowserSourceMaps: false,
};

// Server-side only secrets (API routes, getServerSideProps, Server Components)
// NEVER use NEXT_PUBLIC_ prefix for secrets
```

### CSRF Protection

```typescript
// Double-submit cookie pattern
import csrf from "csurf";
app.use(csrf({ cookie: { httpOnly: true, secure: true, sameSite: "strict" } }));

// Or use SameSite cookies (modern approach)
// Set SameSite=Strict on session cookies — browser won't send them on cross-origin POST
res.cookie("session", token, {
  httpOnly: true,
  secure: true,
  sameSite: "strict",
});
```

---

## 10. Error Handling and Information Disclosure

### Centralized Error Handler

```typescript
// ❌ Anti-pattern: inconsistent error handling across routes
app.get("/users", async (req, res) => {
  try { /* ... */ } catch (e) { res.status(500).json({ error: (e as Error).stack }); }
});

// ✅ Correct: centralized error handler
class AppError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public isOperational: boolean = true,
  ) {
    super(message);
    this.name = "AppError";
  }
}

// Error handler middleware (must be last)
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError && err.isOperational) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  // Unknown/programming error — log full details, return generic message
  logger.error({ err, url: req.url, method: req.method }, "Unexpected error");
  res.status(500).json({ error: "Internal server error" });
});
```

### Async Error Handling (Express 4)

```typescript
// Express 4 does NOT catch async errors — they cause unhandled rejections

// ❌ Anti-pattern: unhandled async error
app.get("/data", async (req, res) => {
  const data = await fetchData(); // uncaught rejection if this throws
  res.json(data);
});

// ✅ Correct: async wrapper
const asyncHandler = (fn: (req: Request, res: Response, next: NextFunction) => Promise<void>) =>
  (req: Request, res: Response, next: NextFunction) => fn(req, res, next).catch(next);

app.get("/data", asyncHandler(async (req, res) => {
  const data = await fetchData();
  res.json(data);
}));

// ✅ Better: use Express 5+ or Fastify (handle async errors natively)
```

### Process-Level Error Handlers

```typescript
// Catch unhandled rejections and uncaught exceptions
process.on("unhandledRejection", (reason, promise) => {
  logger.fatal({ reason }, "Unhandled promise rejection");
  // Gracefully shut down
  server.close(() => process.exit(1));
});

process.on("uncaughtException", (err) => {
  logger.fatal({ err }, "Uncaught exception");
  // Gracefully shut down
  server.close(() => process.exit(1));
});

// Graceful shutdown on signals
for (const signal of ["SIGTERM", "SIGINT"] as const) {
  process.on(signal, () => {
    logger.info(`Received ${signal}, shutting down gracefully`);
    server.close(() => process.exit(0));
  });
}
```

### Safe Error Responses

```typescript
// ❌ Anti-pattern: leaking internal details
res.status(500).json({
  error: err.message,        // may contain internal details
  stack: err.stack,          // file paths, line numbers
  query: (err as any).query, // SQL query
});

// ✅ Correct: generic message for 5xx, specific for 4xx
function errorResponse(err: Error, res: Response): void {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({ error: err.message });
  } else {
    res.status(500).json({ error: "Internal server error" });
  }
}
```
