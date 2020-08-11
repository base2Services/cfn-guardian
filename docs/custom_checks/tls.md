# TLS

CloudWatch Namespace: `TLSVersionCheck`

```yaml
Resources:
  TLS:
    # endpoint
  - Id: example.com
    # port to check, defaults to 443
    Port: 443
    # list of tls versions to validate against
    # there is a metric for each version with a 0 being no supported and 1 for supported
    # alarm thresholds will have to be adjusted to suit your checking requirements
    # defaults to all versions shown below
    Versions:
      - SSLv2
      - SSLv3
      - TLSv1
      - TLSv1.1
      - TLSv1.2
    # checks and reports the max tls version supported as an int
    # ['SSLv2 => 1', 'SSLv3 => 2', 'TLSv1 => 3','TLSv1.1 => 4', 'TLSv1.2 => 5']
    MaxSupported: '1'
```