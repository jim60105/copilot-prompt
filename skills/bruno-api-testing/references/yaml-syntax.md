# OpenCollection YAML Syntax Reference

Complete reference for Bruno's YAML-based OpenCollection format (v3.1+).

## Table of Contents

- [Request File Structure](#request-file-structure)
- [Request Types](#request-types)
- [Body Formats](#body-formats)
- [Authentication](#authentication)
- [Headers and Parameters](#headers-and-parameters)
- [Variables](#variables)
- [Scripts](#scripts)
- [Assertions](#assertions)
- [Settings](#settings)
- [Environment Files](#environment-files)
- [Folder Files](#folder-files)
- [Collection Files](#collection-files)
- [opencollection.yml](#opencollectionyml)

## Request File Structure

Top-level sections in a `.yml` request file:

```yaml
info:        # Request metadata (name, type, seq, tags)
http:        # HTTP request configuration
runtime:     # Scripts and assertions
settings:    # Request settings
docs:        # Request documentation (markdown string)
```

### info

```yaml
info:
  name: Get Users          # Display name
  type: http               # http | folder | grpc | ws
  seq: 1                   # Sort order in UI
  tags:                    # Optional tags for filtering
    - smoke
    - regression
```

## Request Types

### HTTP/REST

```yaml
info:
  name: Create User
  type: http
  seq: 1

http:
  method: POST
  url: "{{baseUrl}}/users"
  body:
    type: json
    data: |-
      {
        "username": "johndoe",
        "email": "john@example.com"
      }
  auth:
    type: bearer
    token: "{{token}}"

settings:
  encodeUrl: true
```

### GraphQL

```yaml
info:
  name: Get User Data
  type: http
  seq: 1

http:
  method: POST
  url: "{{baseUrl}}/graphql"
  body:
    type: graphql
    data: |-
      query {
        user(id: "123") {
          id
          name
          email
        }
      }
  auth:
    type: bearer
    token: "{{token}}"
```

### gRPC

```yaml
info:
  name: SayHello
  type: grpc
  seq: 1

grpc:
  url: "{{host}}"
  service: hello.HelloService
  method: SayHello
  body:
    type: json
    data: |-
      {
        "greeting": "hello"
      }
  auth: inherit
```

### WebSocket

```yaml
info:
  name: WebSocket Test
  type: ws
  seq: 1

ws:
  url: "ws://localhost:8081/ws"
  headers:
    - name: Authorization
      value: "Bearer {{token}}"
  auth: inherit
```

## Body Formats

### JSON

```yaml
body:
  type: json
  data: |-
    {
      "username": "johndoe",
      "email": "john@example.com"
    }
```

### Text

```yaml
body:
  type: text
  data: "This is plain text content"
```

### XML

```yaml
body:
  type: xml
  data: |-
    <?xml version="1.0" encoding="UTF-8"?>
    <user>
      <username>johndoe</username>
      <email>john@example.com</email>
    </user>
```

### Form URL Encoded

```yaml
body:
  type: form-urlencoded
  data:
    - name: username
      value: johndoe
    - name: password
      value: secret123
    - name: disabled_field
      value: value
      disabled: true
```

### Multipart Form

```yaml
body:
  type: multipart-form
  data:
    - name: username
      value: johndoe
    - name: avatar
      value: "@file(/path/to/avatar.jpg)"
    - name: description
      value: User profile picture
```

## Authentication

### Bearer Token

```yaml
auth:
  type: bearer
  token: "{{token}}"
```

### Basic Auth

```yaml
auth:
  type: basic
  username: admin
  password: secret123
```

### API Key

```yaml
auth:
  type: apikey
  key: x-api-key
  value: "{{api-key}}"
  placement: header
```

### OAuth2

```yaml
auth:
  type: oauth2
  grant_type: authorization_code
  callback_url: http://localhost:8080/callback
  authorization_url: https://provider.com/oauth/authorize
  access_token_url: https://provider.com/oauth/token
  client_id: "{{client_id}}"
  client_secret: "{{client_secret}}"
  scope: read write
```

### Inherit / None

```yaml
auth: inherit    # Inherit from parent folder or collection
auth:
  type: none     # No authentication
```

Supported types: `none`, `inherit`, `basic`, `bearer`, `apikey`, `digest`, `oauth2`, `awsv4`, `ntlm`.

## Headers and Parameters

### Headers

Array of objects with `name`, `value`, optional `disabled`:

```yaml
http:
  headers:
    - name: content-type
      value: application/json
    - name: x-api-key
      value: "{{apiKey}}"
    - name: x-request-id
      value: "{{$uuid}}"
    - name: disabled-header
      value: some-value
      disabled: true
```

### Query Parameters

```yaml
http:
  params:
    query:
      - name: page
        value: "1"
      - name: limit
        value: "10"
      - name: disabled_param
        value: value
        disabled: true
```

### Path Parameters

```yaml
http:
  params:
    path:
      - name: userId
        value: "123"
```

## Variables

### Variable Interpolation

Use `{{variableName}}` syntax:

- Environment variables: `{{baseUrl}}`, `{{apiKey}}`
- Runtime variables: `{{user_id}}`
- Dynamic variables: `{{$guid}}`, `{{$timestamp}}`, `{{$randomInt}}`
- Response data: `{{res.body.token}}`

### Dynamic Variables

```
{{$guid}}                  Random GUID
{{$timestamp}}             Current Unix timestamp
{{$isoTimestamp}}          ISO 8601 timestamp
{{$randomInt}}             Random integer (0-1000)
{{$randomEmail}}           Random email address
{{$randomFirstName}}       Random first name
{{$randomLastName}}        Random last name
{{$randomPhoneNumber}}     Random phone number
{{$randomCity}}            Random city name
{{$randomStreetAddress}}   Random street address
{{$randomCountry}}         Random country
{{$randomUUID}}            Random UUID v4
```

## Scripts

### Pre-Request Script

```yaml
runtime:
  scripts:
    - type: before-request
      code: |-
        const timestamp = Date.now();
        bru.setVar("request_timestamp", timestamp);
        req.setHeader("X-Timestamp", timestamp.toString());
```

### Post-Response Script

```yaml
runtime:
  scripts:
    - type: after-response
      code: |-
        const token = res.body.token;
        bru.setVar("authToken", token);
        bru.setEnvVar("sessionToken", token);

        if (res.status === 200) {
          bru.setNextRequest("Get User Profile");
        }
```

### Tests Script

```yaml
runtime:
  scripts:
    - type: tests
      code: |-
        test("Status is 200", function() {
          expect(res.status).to.equal(200);
        });

        test("Response has required fields", function() {
          expect(res.body).to.have.property('id');
          expect(res.body).to.have.property('name');
        });
```

Script type must be `tests` (not `test`).

## Assertions

Declarative assertions without JavaScript:

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
    - expression: res.body.id
      operator: isNumber
    - expression: res.headers.content-type
      operator: contains
      value: application/json
```

Operators: `eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `contains`, `startsWith`, `endsWith`, `isNumber`, `isString`, `isBoolean`, `isJson`, `isArray`, `isEmpty`, `isNull`, `isUndefined`, `isTrue`, `isFalse`.

## Settings

```yaml
settings:
  encodeUrl: true          # URL-encode the request URL
  timeout: 0               # Timeout in ms (0 = no timeout)
  followRedirects: true    # Follow HTTP redirects
  maxRedirects: 5          # Max redirects to follow
```

## Environment Files

Located in `environments/` directory with `.yml` extension:

```yaml
variables:
  - name: baseUrl
    value: https://api.example.com
  - name: apiVersion
    value: v1
  - name: timeout
    value: "30000"
  - name: apiKey
    value: ""
    secret: true
  - name: authToken
    value: ""
    secret: true
```

Reference CI/CD secrets with `{{process.env.VARIABLE_NAME}}`.

## Folder Files

`folder.yml` in subdirectories — settings apply to all requests in the folder:

```yaml
info:
  name: User Management
  type: folder

http:
  headers:
    - name: x-api-version
      value: v2
  auth:
    type: bearer
    token: "{{token}}"

runtime:
  scripts:
    - type: before-request
      code: |-
        bru.setVar("folder_timestamp", Date.now());
    - type: tests
      code: |-
        test("Folder level test", function() {
          expect(res.status).to.be.oneOf([200, 201, 204]);
        });
```

## Collection Files

`collection.yml` — settings apply to all requests in the collection:

```yaml
info:
  name: My API Collection

http:
  headers:
    - name: user-agent
      value: Bruno/1.0

runtime:
  scripts:
    - type: before-request
      code: |-
        console.log("Collection pre-request script");
    - type: tests
      code: |-
        test("Response time under 5s", function() {
          expect(res.responseTime).to.be.below(5000);
        });
```

## opencollection.yml

Required at collection root. Identifies the directory as a Bruno OpenCollection.

Minimal:

```yaml
opencollection: 1.0.0

info:
  name: My Collection
```

Full with optional fields:

```yaml
opencollection: 1.0.0

info:
  name: Bruno Example

config:
  proxy:
    inherit: true

request:
  variables:
    - name: tokenVar
      value: tokenCollection
      disabled: true
  scripts:
    - type: before-request
      code: // console.log('Collection Level Script Logic')

docs:
  content: |-
    ### Collection Documentation
  type: text/markdown

bundled: false
ignore:
  - node_modules
  - .git
```

**Do NOT put** request-level fields (`http:`, `method:`, `url:`, `body:`) in `opencollection.yml` — those belong in individual request files.

## Documentation

Request-level docs use markdown:

```yaml
docs: |-
  # User Creation API

  This endpoint creates a new user.

  ## Required Fields
  - name: User's full name
  - email: User's email address
```
