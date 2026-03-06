# HTTP

## Public HTTP Check

Cloudwatch NameSpace: `HttpCheck`

```yaml
Resources:
  Http:
  # Array of resources defining the http endpoint with the Id: key
  - Id: https://api.example.com
    # enables the status code check
    StatusCode: 200
    # enables the SSL check
    Ssl: true
    # boolean to request a compressed response
    Compressed: true
  - Id: https://www.example.com
    StatusCode: 301
  - Id: https://example.com
    StatusCode: 200
    Ssl: true
    # enables the body regex check
    BodyRegex: 'helloworld'
  - Id: http://www.example.com/images/cat.jpg
    StatusCode: 200
    # md5 hash of the image
    BodyRegex: ae49b4246a89efcb5c639f00a013e812
  - Id: https://api.example.com/user
    StatusCode: 201
    # default method is get but can be overridden to support post/put/head etc
    Method: post
    # specify headers using "key=value key=value"
    Headers: content-type=application/json
    # specify a useragent that contains spaces
    UserAgent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Base2/Lambda
    # pass in custom payload for the request
    Payload: '{"name": "john"}'
```

## HMAC signed requests

For health endpoints that require authenticated requests, Guardian can send HMAC-signed headers so your application can verify the request came from Guardian and resist replay attacks.

When enabled, the HTTP check Lambda (see [aws-lambda-http-check](https://github.com/base2services/aws-lambda-http-check)) adds these headers to each request:

| Header (default prefix `X-Health`) | Description |
|-----------------------------------|-------------|
| `X-Health-Signature` | HMAC-SHA256 hex digest of the canonical string |
| `X-Health-Key-Id` | Key identifier (e.g. `default`) |
| `X-Health-Timestamp` | Unix epoch timestamp in seconds |
| `X-Health-Nonce` | Random value (e.g. UUID hex) to prevent replay |

**Configuration (Public or Internal HTTP):**

| Key | Required | Description |
|-----|----------|-------------|
| `HmacSecretSsm` | Yes | SSM Parameter Store path to the HMAC secret (SecureString). The Guardian-generated IAM role grants the Lambda `ssm:GetParameter` for this path. |
| `HmacKeyId` | No | Key id sent in the `Key-Id` header. Default: `default`. |
| `HmacHeaderPrefix` | No | Prefix for all HMAC header names. Default: `X-Health` (yields `X-Health-Signature`, `X-Health-Key-Id`, etc.). |

**Example:**

```yaml
Resources:
  Http:
  - Id: https://api.example.com/health
    StatusCode: 200
    HmacSecretSsm: /guardian/myapp/hmac-secret
    HmacKeyId: default
    HmacHeaderPrefix: X-Health
```

Internal HTTP checks support the same keys under each host:

```yaml
Resources:
  InternalHttp:
  - Environment: Prod
    VpcId: vpc-1234
    Subnets: [subnet-abcd]
    Hosts:
    - Id: http://api.example.com/health
      StatusCode: 200
      HmacSecretSsm: /guardian/myapp/hmac-secret
```

Create the secret in SSM (e.g. SecureString) and use the same value in your application when verifying the signature.

## Private HTTP Check

Cloudwatch NameSpace: `InternalHttpCheck`

```yaml
Resources:
  InternalHttp:
  # Array of host groups with the uniq identifier of Environment.
  # This will create a nrpe lambda per group attach to the defined vpc and subnets
  - Environment: Prod
    # VPC id for the vpc the EC2 hosts are running in
    VpcId: vpc-1234
    # Array of subnets to attach to the lambda function. Supply multiple if you want to be multi AZ. 
    # Multiple subnets from the same AZ cannot be used!
    Subnets:
      - subnet-abcd
    Hosts:
    # Array of resources defining the http endpoint with the Id: key
    # All the same options as Http including ssl check on the internal endpoint
    - Id: http://api.example.com
```

## Supporting HMAC-signed health checks in your application

If you want Guardian to call a health endpoint that only accepts HMAC-authenticated requests, your server must verify the same scheme the Lambda uses.

**Canonical string (what gets signed):**

The Lambda signs this string (newline-separated, no trailing newline):

```
METHOD\nPATH\nTIMESTAMP\nNONCE\nQUERY\nBODY_HASH
```

- `METHOD` – HTTP method (e.g. `GET`).
- `PATH` – URL path (e.g. `/health`), no query.
- `TIMESTAMP` – Same value as the `{prefix}-Timestamp` header (Unix seconds).
- `NONCE` – Same value as the `{prefix}-Nonce` header.
- `QUERY` – Raw query string (e.g. `foo=bar` or empty).
- `BODY_HASH` – SHA-256 hex digest of the raw request body (empty string for GET; for POST/PUT, hash the body as sent).

**Verification steps (pseudo code):**

1. Read headers (default prefix `X-Health`):  
   `signature`, `key_id`, `timestamp`, `nonce`.
2. **Optional – replay protection:**  
   Reject if `timestamp` is too old (e.g. outside last 5 minutes).  
   Reject if `nonce` has been seen before (e.g. cache or DB) and treat as replay.
3. Look up the shared secret for `key_id` (e.g. from config or secrets store – same value as in SSM for Guardian).
4. Build the canonical string from the incoming request:
   - Use request method, path, and query.
   - Use `timestamp` and `nonce` from the headers.
   - For body: compute SHA-256 hex of the raw request body (empty string for no body).
5. Compute `expected = HMAC-SHA256(secret, canonical_string)` and compare to `signature` (constant-time).
6. If equal, treat the request as authenticated.

**Pseudo code example:**

```python
import hmac
import hashlib

def verify_health_request(request, secret_by_key_id, header_prefix="X-Health", max_age_seconds=300):
    sig_h = f"{header_prefix}-Signature"
    key_h = f"{header_prefix}-Key-Id"
    ts_h  = f"{header_prefix}-Timestamp"
    nonce_h = f"{header_prefix}-Nonce"

    signature = request.headers.get(sig_h)
    key_id    = request.headers.get(key_h)
    timestamp = request.headers.get(ts_h)
    nonce     = request.headers.get(nonce_h)

    if not all([signature, key_id, timestamp, nonce]):
        return False

    # Replay: reject old timestamps
    if abs(int(timestamp) - time.time()) > max_age_seconds:
        return False
    # Replay: reject duplicate nonce (check your cache/DB)
    if nonce_already_used(nonce):
        return False

    secret = secret_by_key_id.get(key_id)
    if not secret:
        return False

    body_hash = hashlib.sha256(request.body or b"").hexdigest()
    canonical = "\n".join([
        request.method,
        request.path,
        timestamp,
        nonce,
        request.query_string or "",
        body_hash,
    ])
    expected = hmac.new(secret.encode(), canonical.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)
```

Use the same HMAC secret in SSM (Guardian config) and in your app’s config or secrets store. Keep the secret in SecureString or equivalent and restrict access appropriately.