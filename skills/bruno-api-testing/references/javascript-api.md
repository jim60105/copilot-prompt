# Bruno JavaScript API Reference

Complete reference for the `req`, `res`, and `bru` objects available in Bruno scripts and tests.

## Table of Contents

- [req Object](#req-object)
- [res Object](#res-object)
- [bru Object](#bru-object)
- [Chai.js Assertions](#chaijs-assertions)

---

## req Object

Available in `before-request` (pre-request) scripts.

### URL & Method

| Method | Description |
|--------|-------------|
| `req.getUrl()` | Get the current request URL |
| `req.setUrl(url)` | Set the request URL |
| `req.getMethod()` | Get the HTTP method |
| `req.setMethod(method)` | Set the HTTP method |

### Headers

| Method | Description |
|--------|-------------|
| `req.getHeader(name)` | Get a single header value |
| `req.getHeaders()` | Get all headers as an object |
| `req.setHeader(name, value)` | Set a header |
| `req.setHeaders(headers)` | Set multiple headers (merges) |
| `req.removeHeader(name)` | Remove a header |

### Body

| Method | Description |
|--------|-------------|
| `req.getBody()` | Get the request body |
| `req.setBody(data)` | Set the request body |

### Timeout

| Method | Description |
|--------|-------------|
| `req.getTimeout()` | Get the request timeout (ms) |
| `req.setTimeout(ms)` | Set the request timeout (ms) |

### Execution Context

| Method | Description |
|--------|-------------|
| `req.getExecutionMode()` | Returns `"standalone"` or `"runner"` |
| `req.getRequestSequence()` | Get execution order index (runner mode) |

### Request Error Handling

| Method | Description |
|--------|-------------|
| `req.getMaxRedirects()` | Get max redirects |
| `req.setMaxRedirects(n)` | Set max redirects |

### Example

```javascript
// before-request script
const timestamp = Date.now().toString();
req.setHeader("X-Request-Timestamp", timestamp);

// Modify URL dynamically
const url = req.getUrl();
req.setUrl(url + "?nocache=" + timestamp);
```

---

## res Object

Available in `after-response` (post-response) and `tests` scripts.

### Properties & Methods

| Method | Description |
|--------|-------------|
| `res.status` | HTTP status code (number) |
| `res.statusText` | HTTP status text (string) |
| `res.headers` | Response headers object |
| `res.body` | Parsed response body (object for JSON, string for text) |
| `res.responseTime` | Response time in milliseconds |
| `res.getStatus()` | Get HTTP status code |
| `res.getHeader(name)` | Get a single response header |
| `res.getHeaders()` | Get all response headers |
| `res.getBody()` | Get the response body |
| `res.getResponseTime()` | Get response time (ms) |
| `res.getUrl()` | Get the final request URL |
| `res.getSize()` | Get response size information |

### Example

```javascript
// after-response script
if (res.status === 200) {
  const token = res.body.token;
  bru.setVar("authToken", token);
}

// tests block
test("Status is 200", function() {
  expect(res.status).to.equal(200);
});

test("Response time acceptable", function() {
  expect(res.responseTime).to.be.below(2000);
});
```

---

## bru Object

Available in all script contexts.

### Environment Variables

Environment variables are available across the active Bruno environment. `bru.setEnvVar()` is in-memory by default; pass `{ persist: true }` to write the change to disk.

| Method | Description |
|--------|-------------|
| `bru.getEnvVar(name)` | Get an environment variable |
| `bru.setEnvVar(name, value, options?)` | Set an environment variable; use `{ persist: true }` to save it to file |
| `bru.getEnvName()` | Get the active environment name |
| `bru.hasEnvVar(name)` | Check if an environment variable exists |
| `bru.deleteEnvVar(name)` | Delete an environment variable |
| `bru.getAllEnvVars()` | Get all environment variables as an object |
| `bru.deleteAllEnvVars()` | Delete all environment variables in the active environment |
| `bru.getGlobalEnvVar(name)` | Get a global environment variable |
| `bru.setGlobalEnvVar(name, value)` | Set a global environment variable |
| `bru.getAllGlobalEnvVars()` | Get all global environment variables as an object |

### Collection, Folder, and Request Variables

| Method | Description |
|--------|-------------|
| `bru.getCollectionName()` | Get the current collection name |
| `bru.getCollectionVar(name)` | Get a collection variable |
| `bru.hasCollectionVar(name)` | Check if a collection variable exists |
| `bru.getFolderVar(name)` | Get a folder variable |
| `bru.getRequestVar(name)` | Get a request-level variable |

### Process Environment Variables

| Method | Description |
|--------|-------------|
| `bru.getProcessEnv(name)` | Get a process environment variable exposed by the OS or CI runtime |

### Runtime Variables

Runtime variables exist only during the current execution and are NOT persisted:

| Method | Description |
|--------|-------------|
| `bru.hasVar(name)` | Check whether a runtime variable exists |
| `bru.getVar(name)` | Get a runtime variable |
| `bru.setVar(name, value)` | Set a runtime variable |
| `bru.deleteVar(name)` | Delete a runtime variable |
| `bru.getAllVars()` | Get all runtime variables as an object |
| `bru.deleteAllVars()` | Delete all runtime variables |

### Runner Control (Collection Runner Only)

| Method | Description |
|--------|-------------|
| `bru.setNextRequest(name)` | Set the next request to execute by name |
| `bru.runner.setNextRequest(name)` | Set the next request to execute by name |
| `bru.runner.skipRequest()` | Skip the current request |
| `bru.runner.stopExecution()` | Stop the collection run |

### Utilities

| Method | Description |
|--------|-------------|
| `bru.sleep(ms)` | Sleep for specified milliseconds |
| `bru.interpolate(string)` | Interpolate variables in a string |
| `bru.cwd()` | Get the collection root directory path |
| `bru.getTestResults()` | Get test results for current request |
| `bru.getAssertionResults()` | Get assertion results for current request |

### Cookie Management

Bruno exposes a cookie jar API in scripts:

```javascript
const jar = bru.cookies.jar();

jar.setCookie("https://example.com", "sessionId", "abc123");
const sessionCookie = await jar.getCookie("https://example.com", "sessionId");
const allCookies = await jar.getCookies("https://example.com");
```

### sendRequest

Send additional HTTP requests from within scripts:

```javascript
// Basic sendRequest
const response = await bru.sendRequest({
  method: "POST",
  url: "https://api.example.com/oauth/token",
  headers: {
    "Content-Type": "application/x-www-form-urlencoded"
  },
  data: "grant_type=client_credentials&client_id=xxx"
});

bru.setVar("accessToken", response.body.access_token);
```

### runRequest

Execute another request from the same collection:

```javascript
// Run another request from the collection
await bru.runRequest("path/to/request.bru");
```

---

## Chai.js Assertions

Bruno uses Chai.js `expect` style assertions in test blocks. The `expect` function is globally available.

### Basic Assertions

```javascript
expect(value).to.equal(expected);           // Strict equality
expect(value).to.not.equal(unexpected);     // Not equal
expect(value).to.deep.equal(expected);      // Deep equality
expect(value).to.be.true;                   // Strictly true
expect(value).to.be.false;                  // Strictly false
expect(value).to.be.null;                   // Is null
expect(value).to.be.undefined;              // Is undefined
expect(value).to.exist;                     // Not null/undefined
expect(value).to.be.ok;                     // Truthy
```

### Type Assertions

```javascript
expect(value).to.be.a('string');
expect(value).to.be.a('number');
expect(value).to.be.a('boolean');
expect(value).to.be.an('object');
expect(value).to.be.an('array');
expect(value).to.be.an.instanceof(Constructor);
```

### Numeric Comparisons

```javascript
expect(value).to.be.above(5);              // Greater than
expect(value).to.be.below(100);            // Less than
expect(value).to.be.at.least(5);           // >=
expect(value).to.be.at.most(100);          // <=
expect(value).to.be.within(5, 100);        // Range inclusive
expect(value).to.be.closeTo(10, 0.5);      // Approx equal
```

### String Assertions

```javascript
expect(str).to.include('substring');
expect(str).to.match(/regex/);
expect(str).to.have.lengthOf(10);
expect(str).to.be.empty;                   // Length 0
```

### Object Assertions

```javascript
expect(obj).to.have.property('name');
expect(obj).to.have.property('name', 'John');
expect(obj).to.have.nested.property('user.name');
expect(obj).to.have.all.keys('id', 'name', 'email');
expect(obj).to.have.any.keys('id', 'name');
expect(obj).to.include({ name: 'John' });
expect(obj).to.deep.include({ user: { name: 'John' } });
```

### Array Assertions

```javascript
expect(arr).to.have.lengthOf(3);
expect(arr).to.include('item');
expect(arr).to.include.members(['a', 'b']);
expect(arr).to.have.ordered.members(['a', 'b', 'c']);
expect(arr).to.deep.include({ id: 1 });
expect(arr).to.be.an('array').that.is.not.empty;
expect(arr).to.satisfy(a => a.every(x => x > 0));
```

### Chaining

Chain language helpers for readability (no behavioral effect):
`to`, `be`, `been`, `is`, `that`, `which`, `and`, `has`, `have`, `with`, `at`, `of`, `same`, `but`, `does`, `still`, `also`.

```javascript
expect(res.body).to.be.an('object').that.has.property('id');
expect(res.status).to.be.a('number').and.to.equal(200);
```

---

## Script Execution Order

Bruno supports two script flows:

1. **Sandwich** (default): Collection `before-request` → Folder `before-request` → Request `before-request` → **HTTP request executes** → Request `after-response` → Folder `after-response` → Collection `after-response`
2. **Sequential**: Collection `before-request` → Folder `before-request` → Request `before-request` → **HTTP request executes** → Collection `after-response` → Folder `after-response` → Request `after-response`

Request assertions and the request `tests` script run after the post-response scripts.

---

## Variable Precedence (Highest to Lowest)

1. Runtime variables (`bru.setVar`)
2. Request variables
3. Folder variables (innermost first)
4. Collection variables
5. Environment variables

Use `bru.getGlobalEnvVar()` for global environment variables and `bru.getProcessEnv()` for process environment variables. Bruno's docs only define the precedence chain through environment variables.

---

## Dynamic Variables

Available in variable interpolation:

| Variable | Description |
|----------|-------------|
| `{{$guid}}` | Random UUID v4 |
| `{{$timestamp}}` | Unix timestamp (seconds) |
| `{{$isoTimestamp}}` | ISO 8601 timestamp |
| `{{$randomInt}}` | Random integer |

---

## Assert Block Operators

Used in the `assert` / `assertions` sections:

| Operator | Description | Example |
|----------|-------------|---------|
| `eq` | Equals | `res.status: eq 200` |
| `neq` | Not equals | `res.status: neq 404` |
| `gt` | Greater than | `res.body.count: gt 0` |
| `gte` | Greater than or equal | `res.body.count: gte 1` |
| `lt` | Less than | `res.responseTime: lt 5000` |
| `lte` | Less than or equal | `res.body.age: lte 100` |
| `in` | In list | `res.status: in [200, 201]` |
| `notIn` | Not in list | `res.status: notIn [500, 502]` |
| `contains` | Contains substring | `res.body.name: contains John` |
| `notContains` | Not contains | `res.body.msg: notContains error` |
| `matches` | Regex match | `res.body.email: matches @.*\\.com` |
| `length` | Array/string length | `res.body.items: length 10` |
| `between` | Range (inclusive) | `res.body.score: between 0 100` |
| `isString` | Type check | `res.body.name: isString` |
| `isNumber` | Type check | `res.body.id: isNumber` |
| `isBoolean` | Type check | `res.body.active: isBoolean` |
| `isNull` | Is null | `res.body.deleted: isNull` |
| `isJson` | Is valid JSON | `res.body: isJson` |
| `isDefined` | Is defined | `res.body.id: isDefined` |
| `isUndefined` | Is undefined | `res.body.deleted: isUndefined` |
| `isEmpty` | Is empty | `res.body.errors: isEmpty` |
| `isTruthy` | Truthy value | `res.body.success: isTruthy` |
| `isFalsy` | Falsy value | `res.body.error: isFalsy` |
