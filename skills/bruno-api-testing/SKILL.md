---
name: bruno-api-testing
description: "Create, run, and maintain API test collections using Bruno (OpenCollection YAML format and legacy Bru format). Use when the user wants to: (1) create a Bruno API test collection from scratch or from OpenAPI/Swagger specs, (2) write API request files with tests and assertions, (3) run API tests using bru CLI, (4) generate test reports (HTML, JUnit, JSON), (5) set up CI/CD pipelines (GitHub Actions) for automated API testing, (6) debug or fix failing Bruno API tests, (7) add environment configurations for API testing, (8) chain API requests with data extraction, or (9) work with any .yml/.bru Bruno collection files. Triggers on mentions of 'Bruno', 'bru CLI', 'API testing collection', 'OpenCollection', or requests to automate API testing with file-based collections."
---

# Bruno API Testing

Create and run API test collections using Bruno — a Git-first, offline-only API client that stores collections as plain files.

## Format Selection

Bruno supports two file formats. Determine which to use:

- **YAML (OpenCollection)** — Default since Bruno v3.1. Uses `.yml` files and `opencollection.yml` root. Preferred for new projects.
- **Bru (Legacy)** — Uses `.bru` files and `bruno.json` root. Use only for existing Bru-format collections.

Detect format by checking the collection root: `opencollection.yml` → YAML, `bruno.json` → Bru.

For **YAML format** syntax details, see [references/yaml-syntax.md](references/yaml-syntax.md).
For **Bru format** syntax details, see [references/bru-syntax.md](references/bru-syntax.md).

## Workflow

### 1. Create Collection Structure

Create the directory layout with the collection root file, environments, and organized request folders.

**YAML format:**

```
my-api-tests/
├── opencollection.yml          # REQUIRED: collection root
├── environments/
│   ├── Local.yml
│   ├── Staging.yml
│   └── Production.yml
├── Auth/
│   ├── folder.yml
│   └── Login.yml
└── Users/
    ├── folder.yml
    ├── Get Users.yml
    ├── Get User by ID.yml
    └── Create User.yml
```

Minimal `opencollection.yml`:

```yaml
opencollection: 1.0.0

info:
  name: My API Tests
```

**Bru format:** Same structure but use `bruno.json` + `.bru` extensions. See [references/bru-syntax.md](references/bru-syntax.md).

### 2. Create Environment Files

**YAML** (`environments/Local.yml`):

```yaml
variables:
  - name: baseUrl
    value: http://localhost:3000/api
  - name: apiKey
    value: ""
    secret: true
```

**Bru** (`environments/Local.bru`):

```
vars {
  baseUrl: http://localhost:3000/api
}

vars:secret [
  apiKey
]
```

### 3. Write Request Files with Tests

**YAML format** — a complete request with tests:

```yaml
info:
  name: Get Users
  type: http
  seq: 1

http:
  method: GET
  url: "{{baseUrl}}/users"
  headers:
    - name: accept
      value: application/json
    - name: authorization
      value: "Bearer {{authToken}}"

runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
    - expression: res.body
      operator: isArray
  scripts:
    - type: tests
      code: |-
        test("returns 200", function() {
          expect(res.status).to.equal(200);
        });

        test("returns array of users", function() {
          expect(res.body).to.be.an('array');
          expect(res.body).to.have.lengthOf.at.least(1);
        });

        test("each user has required fields", function() {
          res.body.forEach(user => {
            expect(user).to.have.property('id');
            expect(user).to.have.property('email');
          });
        });

settings:
  encodeUrl: true
```

Use **assertions** (declarative) for simple checks, **tests** scripts (Chai.js) for complex logic.

### 4. Chain Requests with Data Extraction

Extract data from one response and use it in subsequent requests:

**YAML — Login request saving a token:**

```yaml
info:
  name: Login
  type: http
  seq: 1

http:
  method: POST
  url: "{{baseUrl}}/auth/login"
  body:
    type: json
    data: |-
      {
        "username": "{{username}}",
        "password": "{{password}}"
      }
  auth:
    type: none

runtime:
  scripts:
    - type: after-response
      code: |-
        bru.setEnvVar("authToken", res.body.access_token);
    - type: tests
      code: |-
        test("login successful", function() {
          expect(res.status).to.equal(200);
          expect(res.body).to.have.property('access_token');
        });
```

Then reference `{{authToken}}` in subsequent requests via `Bearer {{authToken}}`.

### 5. Run Tests with bru CLI

Install and run:

```bash
npm install -g @usebruno/cli

# Run entire collection
cd my-api-tests && bru run --env Local

# Run specific folder
bru run Auth --env Local

# Run with developer mode (for external packages, fs access)
bru run --env Local --sandbox=developer

# Filter by tags
bru run --tags=smoke --env Local

# Generate reports
bru run --env Local \
  --reporter-html results.html \
  --reporter-junit results.xml \
  --reporter-json results.json

# Pass secrets via CLI
bru run --env Local --env-var API_KEY=secret123

# Parallel execution
bru run --env Local --parallel

# Data-driven testing
bru run --csv-file-path data.csv --env Local
```

**v3.0.0 breaking change**: Default is now Safe Mode. Use `--sandbox=developer` for developer mode features.

### 6. Set Up CI/CD

See [references/ci-cd.md](references/ci-cd.md) for complete GitHub Actions workflows, matrix testing, and reporting patterns.

Minimal GitHub Actions workflow:

```yaml
name: API Tests
on: [push, pull_request]

jobs:
  api-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm install -g @usebruno/cli
      - name: Run API Tests
        working-directory: ./my-api-tests
        env:
          API_KEY: ${{ secrets.API_KEY }}
        run: bru run --env CI --reporter-html results.html --reporter-junit results.xml
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: |
            ./my-api-tests/results.html
            ./my-api-tests/results.xml
```

**Critical**: Always set `working-directory` to the collection root in CI/CD.

## Testing Patterns

### Assertions (Declarative) — Use for Simple Checks

```yaml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
    - expression: res.body.success
      operator: eq
      value: "true"
    - expression: res.body.data
      operator: isJson
    - expression: res.headers.content-type
      operator: contains
      value: application/json
```

Operators vary slightly by Bruno version and editor surface. Check Bruno's current Assertions docs for the exact operator names supported by your version when writing declarative assertions.

### Tests (Chai.js) — Use for Complex Validation

```yaml
runtime:
  scripts:
    - type: tests
      code: |-
        test("status and structure", function() {
          expect(res.status).to.equal(200);
          expect(res.body).to.be.an('object');
          expect(res.body).to.have.all.keys('id', 'name', 'email');
        });

        test("validates email format", function() {
          expect(res.body.email).to.match(/^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$/);
        });

        test("response time acceptable", function() {
          expect(res.responseTime).to.be.below(2000);
        });

        test("pagination works", function() {
          expect(res.body.data).to.be.an('array');
          expect(res.body.meta.total).to.be.a('number');
          expect(res.body.meta.page).to.equal(1);
        });
```

For the complete JavaScript API (`req`, `res`, `bru` objects), see [references/javascript-api.md](references/javascript-api.md).

## Common Mistakes

1. Missing `opencollection.yml` (YAML) or `bruno.json` (Bru) at collection root
2. Using `meta:` instead of `info:` in YAML request files
3. Using script type `test` instead of `tests` (plural)
4. Putting request-level fields (`http:`, `method:`) in `opencollection.yml`
5. Forgetting `working-directory` in CI/CD steps
6. Committing secrets — use `secret: true` in env files + CI/CD secrets
7. Using `|-` for body data is required in YAML to preserve JSON formatting
8. Missing `seq` number in `info:` — controls execution order

## Script Execution Order

Bruno supports two script flows:

1. **Sandwich** (default): Collection `before-request` → Folder `before-request` → Request `before-request` → **Request is sent** → Request `after-response` → Folder `after-response` → Collection `after-response`
2. **Sequential**: Collection `before-request` → Folder `before-request` → Request `before-request` → **Request is sent** → Collection `after-response` → Folder `after-response` → Request `after-response`

Request assertions and request `tests` run after the post-response scripts.

## Variable Precedence (Highest to Lowest)

1. Runtime variables (`bru.setVar()`)
2. Request variables
3. Folder variables
4. Collection variables
5. Environment variables

Use `bru.getGlobalEnvVar()` for global environment values and `bru.getProcessEnv()` for OS process environment variables. They are not documented as part of the standard collection variable precedence chain.

## References

- **[YAML Syntax](references/yaml-syntax.md)** — Complete OpenCollection YAML format for requests, bodies, auth, headers, params, environments, folders, collections
- **[Bru Syntax](references/bru-syntax.md)** — Legacy `.bru` file format reference
- **[JavaScript API](references/javascript-api.md)** — Full `req`, `res`, `bru` object API with runner control, cookies, utilities
- **[CI/CD Integration](references/ci-cd.md)** — GitHub Actions workflows, report generation, matrix testing, environment secrets
