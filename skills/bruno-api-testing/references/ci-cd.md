# CI/CD Integration Reference

Guide for running Bruno tests in CI/CD pipelines using the bru CLI.

## Table of Contents

- [bru CLI Installation](#bru-cli-installation)
- [CLI Commands](#cli-commands)
- [Reporters and Reports](#reporters-and-reports)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Environment Variables in CI](#environment-variables-in-ci)
- [Best Practices](#best-practices)

---

## bru CLI Installation

```bash
npm install -g @usebruno/cli
```

Verify:

```bash
bru --version
```

### Safe Mode (v3.0.0+)

bru CLI v3.0.0 introduced **Safe Mode** as default. This restricts script capabilities.

- `--sandbox=safe` (default) — Restricted mode, no file system access or external modules
- `--sandbox=developer` — Full access to Node.js APIs and external modules

If tests use `require()`, `fs`, or other Node.js APIs, you MUST use `--sandbox=developer`.

---

## CLI Commands

### Run Collection

```bash
bru run --env <environment>
```

From the collection root directory. Runs all requests in sequence order.

### Run Single Request

```bash
bru run request.bru --env <environment>
```

### Run Folder

```bash
bru run folder/ --env <environment>
```

### Key Options

| Option | Description |
|--------|-------------|
| `--env <name>` | Environment to use |
| `--env-var "key=value"` | Override/set environment variables |
| `--output <path>` | Output directory for reports |
| `--reporter-html [path]` | Generate HTML report |
| `--reporter-junit [path]` | Generate JUnit XML report |
| `--reporter-json [path]` | Generate JSON report |
| `--reporter-html-skip-all-headers` | Omit headers from HTML report |
| `--reporter-html-skip-all-bodies` | Omit bodies from HTML report |
| `--reporter-json-skip-all-headers` | Omit headers from JSON report |
| `--reporter-json-skip-all-bodies` | Omit bodies from JSON report |
| `--sandbox <mode>` | `safe` (default) or `developer` |
| `--bail` | Stop on first failure |
| `--cacert <path>` | CA certificate file |
| `--insecure` | Skip SSL verification |
| `-r` | Recursive run |

### Examples

```bash
# Run full collection with HTML + JUnit reports
bru run --env production \
  --reporter-html results/report.html \
  --reporter-junit results/report.xml

# Run with environment variable overrides
bru run --env staging \
  --env-var "baseUrl=https://staging-api.example.com" \
  --env-var "apiKey=$API_KEY"

# Run specific folder with developer sandbox
bru run users/ --env dev --sandbox=developer

# Run with bail (stop on first failure)
bru run --env production --bail
```

---

## Reporters and Reports

### HTML Report

```bash
bru run --env prod --reporter-html results/report.html
```

Options:
- `--reporter-html-skip-all-headers` — Exclude request/response headers
- `--reporter-html-skip-all-bodies` — Exclude request/response bodies

### JUnit XML Report

```bash
bru run --env prod --reporter-junit results/report.xml
```

JUnit XML is compatible with most CI systems (GitHub Actions, Jenkins, GitLab CI).

### JSON Report

```bash
bru run --env prod --reporter-json results/report.json
```

Options:
- `--reporter-json-skip-all-headers` — Exclude headers
- `--reporter-json-skip-all-bodies` — Exclude bodies

### Multiple Reporters

Combine reporters in a single run:

```bash
bru run --env prod \
  --reporter-html results/report.html \
  --reporter-junit results/report.xml \
  --reporter-json results/report.json
```

---

## GitHub Actions Workflows

### Basic Workflow

```yaml
name: API Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  api-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install bru CLI
        run: npm install -g @usebruno/cli

      - name: Run API tests
        working-directory: ./bruno-collection
        run: |
          bru run --env ci \
            --reporter-html results/report.html \
            --reporter-junit results/report.xml

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: bruno-collection/results/
```

**CRITICAL**: `working-directory` MUST point to the collection root directory (where `opencollection.yml` or `bruno.json` lives).

### With Environment Secrets

```yaml
      - name: Run API tests
        working-directory: ./bruno-collection
        env:
          API_KEY: ${{ secrets.API_KEY }}
          BASE_URL: ${{ vars.API_BASE_URL }}
        run: |
          bru run --env ci \
            --env-var "apiKey=$API_KEY" \
            --env-var "baseUrl=$BASE_URL" \
            --reporter-junit results/report.xml
```

### Matrix Testing (Multiple Environments)

```yaml
jobs:
  api-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [staging, production]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install bru CLI
        run: npm install -g @usebruno/cli

      - name: Run API tests (${{ matrix.environment }})
        working-directory: ./bruno-collection
        run: |
          bru run --env ${{ matrix.environment }} \
            --reporter-html results/${{ matrix.environment }}-report.html \
            --reporter-junit results/${{ matrix.environment }}-report.xml

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.environment }}
          path: bruno-collection/results/
```

### With JUnit Test Report

```yaml
      - name: Publish test report
        if: always()
        uses: mikepenz/action-junit-report@v4
        with:
          report_paths: 'bruno-collection/results/report.xml'
          fail_on_failure: true
```

### Scheduled Tests (Monitoring)

```yaml
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:        # Manual trigger

jobs:
  api-monitoring:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install -g @usebruno/cli
      - name: Run health checks
        working-directory: ./bruno-collection
        run: |
          bru run health-checks/ --env production \
            --reporter-json results/health.json \
            --bail
```

---

## Environment Variables in CI

### CI Environment File

Create a dedicated `ci.yml` (YAML) or `ci.bru` (Bru) environment file for CI:

**YAML format** (`environments/ci.yml`):

```yaml
variables:
  - name: baseUrl
    value: "https://api.example.com"
    enabled: true
  - name: apiKey
    value: ""
    enabled: true
    secret: true
```

**Bru format** (`environments/ci.bru`):

```
vars {
  baseUrl: https://api.example.com
}

vars:secret [
  apiKey
]
```

### Injecting Secrets

Pass secrets via `--env-var` flags:

```bash
bru run --env ci \
  --env-var "apiKey=${API_KEY}" \
  --env-var "dbPassword=${DB_PASSWORD}"
```

**NEVER** hardcode secrets in environment files committed to git.

---

## Best Practices

### Collection Structure for CI

```
bruno-collection/
├── opencollection.yml          # or bruno.json
├── environments/
│   ├── local.yml               # Local development
│   ├── staging.yml             # Staging environment
│   ├── production.yml          # Production environment
│   └── ci.yml                  # CI-specific environment
├── health-checks/              # Quick smoke tests
│   ├── folder.yml
│   └── api-health.yml
├── auth/                       # Authentication flows
│   ├── folder.yml
│   ├── 1-login.yml
│   └── 2-refresh-token.yml
├── users/                      # CRUD tests
│   ├── folder.yml
│   ├── 1-create-user.yml
│   ├── 2-get-user.yml
│   ├── 3-update-user.yml
│   └── 4-delete-user.yml
└── .gitignore
```

### .gitignore for Bruno Collections

```gitignore
# Test results
results/

# Local environment overrides
environments/local.yml
environments/local.bru
```

### Ordering Requests

Use `seq` (sequence number) in request metadata to control execution order. Requests run in ascending `seq` order within each folder.

### Request Chaining Pattern

Use runtime variables to chain requests:

```javascript
// In login request's after-response / tests:
bru.setVar("authToken", res.body.token);
bru.setVar("userId", res.body.user.id);
```

```yaml
# In subsequent request's auth:
auth:
  mode: bearer
  bearer:
    token: "{{authToken}}"
```

### Fail-Fast Strategy

Use `--bail` in CI to stop on first failure for faster feedback:

```bash
bru run --env ci --bail --reporter-junit results/report.xml
```

### Parallel Test Suites

Run different folders as separate CI jobs for parallelism:

```yaml
strategy:
  matrix:
    test-suite: [auth, users, orders, products]
steps:
  - name: Run ${{ matrix.test-suite }} tests
    working-directory: ./bruno-collection
    run: bru run ${{ matrix.test-suite }}/ --env ci --reporter-junit results/report.xml
```
