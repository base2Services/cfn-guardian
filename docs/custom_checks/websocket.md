# Websocket

## WebsocketCheck

Cloudwatch NameSpace: `WebSocketCheck`

```yaml
Resources:
  WebSocket:
  # Array of resources defining the http endpoint with the Id: key
  - Id: wss://example.com/websocket
    # message to send to websocket
    Message: {'ping-test'}
    # expected suffix response from websocket eg: response message starts with '{"id":"ping-test","message":...,
    Expected_Response: '{"id":"ping-test","message":{...'
```