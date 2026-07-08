# Gertrude Music

## Physical-device debug builds

For debug builds on a physical iPhone/iPad, the generated Xcode project must point at the
Mac's current LAN address and the local API port. Do not use `localhost` for a physical
device.

- Start the local API from the repo root with `just watch-api`.
- The local API endpoint is inferred by `scripts/local-api-endpoint`, using `LOCAL_API_ENDPOINT` when set,
  otherwise the Wi-Fi IP and repo-root `.gtask-ports` `API_PORT`.
- Regenerate after switching Wi-Fi networks or when `.gtask-ports` changes:

```bash
just music gen
```
