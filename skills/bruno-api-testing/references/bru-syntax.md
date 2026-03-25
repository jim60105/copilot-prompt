# Bru File Format Reference (Legacy)

Reference for Bruno's legacy `.bru` plain-text markup format. Use for existing Bru-format collections.

## Table of Contents

- [Collection Root](#collection-root)
- [Request File Structure](#request-file-structure)
- [Request Types](#request-types)
- [Body Formats](#body-formats)
- [Authentication](#authentication)
- [Headers and Parameters](#headers-and-parameters)
- [Variables](#variables)
- [Scripts](#scripts)
- [Testing](#testing)
- [Environment Files](#environment-files)
- [Folder and Collection Files](#folder-and-collection-files)

## Collection Root

`bruno.json` — required at collection root:

```json
{
  "version": "1",
  "name": "Your Collection Name",
  "type": "collection"
}
```

Do NOT add `pathname`, `files`, `activeEnvironmentUid`. Keep minimal.

## Request File Structure

`.bru` files use block syntax:

```
meta {
  name: Request Name
  type: http
  seq: 1
}

get {
  url: {{baseUrl}}/endpoint
  body: none
  auth: none
}

headers {
  content-type: application/json
  authorization: Bearer {{token}}
}

body:json {
  {
    "key": "value"
  }
}

script:pre-request {
  bru.setVar("timestamp", Date.now());
}

tests {
  test("Status is 200", function() {
    expect(res.status).to.equal(200);
  });
}
```

## Request Types

### HTTP/REST

Method name is the block name (lowercase): `get`, `post`, `put`, `patch`, `delete`, `options`, `head`.

```
meta {
  name: Create User
  type: http
  seq: 1
}

post {
  url: {{baseUrl}}/users
  body: json
  auth: bearer
}

body:json {
  {
    "username": "johndoe",
    "email": "john@example.com"
  }
}

auth:bearer {
  token: {{token}}
}
```

### GraphQL

```
meta {
  name: Get User Data
  type: graphql-request
  seq: 1
}

post {
  url: {{baseUrl}}/graphql
  body: graphql
  auth: bearer
}

body:graphql {
  query {
    user(id: "123") {
      id
      name
      email
    }
  }
}

body:graphql:vars {
  {
    "userId": "123"
  }
}
```

### gRPC

```
meta {
  name: SayHello
  type: grpc
  seq: 1
}

grpc {
  url: {{host}}
  method: /hello.HelloService/SayHello
  body: grpc
  auth: inherit
  methodType: unary
}

body:grpc {
  name: message 1
  content: '''
    {
      "greeting": "hello"
    }
  '''
}
```

### WebSocket

```
meta {
  name: WebSocket Test
  type: ws
  seq: 1
}

ws {
  url: ws://localhost:8081/ws
  auth: inherit
}

headers {
  Authorization: Bearer {{token}}
}
```

## Body Formats

### JSON

```
body:json {
  {
    "username": "johndoe",
    "email": "john@example.com"
  }
}
```

### Text

```
body:text {
  This is plain text content
}
```

### XML

```
body:xml {
  <?xml version="1.0" encoding="UTF-8"?>
  <user>
    <username>johndoe</username>
  </user>
}
```

### Form URL Encoded

```
body:form-urlencoded {
  username: johndoe
  password: secret123
  ~disabled_field: value
}
```

### Multipart Form

```
body:multipart-form {
  username: johndoe
  avatar: @file(/path/to/avatar.jpg)
}
```

## Authentication

### Bearer Token

```
auth:bearer {
  token: {{token}}
}
```

### Basic Auth

```
auth:basic {
  username: admin
  password: secret123
}
```

### API Key

```
auth:apikey {
  key: x-api-key
  value: api-secret-key-12345
  placement: header
}
```

### OAuth2

```
auth:oauth2 {
  grant_type: authorization_code
  callback_url: http://localhost:8080/callback
  authorization_url: https://provider.com/oauth/authorize
  access_token_url: https://provider.com/oauth/token
  client_id: {{client_id}}
  client_secret: {{client_secret}}
  scope: read write
}
```

Supported auth types: `none`, `inherit`, `basic`, `bearer`, `apikey`, `digest`, `oauth2`, `awsv4`, `ntlm`.

## Headers and Parameters

### Headers

```
headers {
  content-type: application/json
  x-api-key: {{apiKey}}
  ~disabled-header: value
}
```

Prefix with `~` to disable.

### Query Parameters

```
params:query {
  page: 1
  limit: 10
  ~disabled_param: value
}
```

### Path Parameters

```
params:path {
  userId: 123
  status: active
}
```

## Variables

### Request-Level Variables

```
vars:pre-request {
  user_id: 12345
  environment: production
}

vars:post-response {
  response_id: {{res.body.id}}
  processed_at: {{$timestamp}}
}
```

### Variable Interpolation

Same as YAML format: `{{variableName}}`, `{{$guid}}`, `{{$timestamp}}`, etc.

## Scripts

### Pre-Request

```
script:pre-request {
  const timestamp = Date.now();
  bru.setVar("request_timestamp", timestamp);
  req.setHeader("X-Timestamp", timestamp.toString());
}
```

### Post-Response

```
script:post-response {
  const token = res.body.token;
  bru.setVar("authToken", token);
  bru.setEnvVar("sessionToken", token);
}
```

## Testing

### Assert Block (Simple)

```
assert {
  res.status: eq 200
  res.body.success: eq true
  res.body.data: isJson
  res.body.id: isNumber
  res.headers.content-type: contains application/json
  ~res.body.optional: eq value
}
```

Disable with `~` prefix. Same operators as YAML format.

### Tests Block (Complex)

```
tests {
  test("Status is 200", function() {
    expect(res.status).to.equal(200);
  });

  test("Response has required fields", function() {
    expect(res.body).to.have.property('id');
    expect(res.body).to.have.property('name');
  });
}
```

## Environment Files

Located in `environments/` with `.bru` extension:

```
vars {
  baseUrl: https://api.example.com
  apiVersion: v1
  timeout: 30000
}

vars:secret [
  apiKey,
  authToken,
  clientSecret
]
```

## Folder and Collection Files

### folder.bru

```
meta {
  name: User Management
  seq: 1
}

headers {
  x-api-version: v2
}

auth {
  mode: bearer
}

auth:bearer {
  token: {{token}}
}

script:pre-request {
  bru.setVar("folder_timestamp", Date.now());
}

tests {
  test("Folder level test", function() {
    expect(res.status).to.be.oneOf([200, 201, 204]);
  });
}
```

### collection.bru

```
meta {
  name: My API Collection
}

headers {
  user-agent: Bruno/1.0
}

script:pre-request {
  console.log("Collection pre-request script");
}

tests {
  test("Response time under 5s", function() {
    expect(res.responseTime).to.be.below(5000);
  });
}
```
