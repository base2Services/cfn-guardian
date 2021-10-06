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
    # boolean tp request a compressed response
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