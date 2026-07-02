# Gertrude Music

## Physical-device debug builds

For debug builds on a physical iPhone/iPad, the generated Xcode project must point at the
Mac's current LAN address and the local API port. Do not use `localhost` for a physical
device.

- Start the local API from the repo root with `just watch-api`.
- Read the port from the repo-root `.gtask-ports` file (`API_PORT`, often not `8080`).
- Get the current Wi-Fi IP with `ipconfig getifaddr en0`.
- Regenerate after switching Wi-Fi networks or when `.gtask-ports` changes:

```bash
cd swift/music
just gen "http://<wifi-ip>:<API_PORT>"
```
