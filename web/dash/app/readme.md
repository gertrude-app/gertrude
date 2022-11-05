# Gertrude Dasboard

## Switching to Vite...

Just found out that Snowpack is not actively maintained, this will be switched to Vite (or
Remix?). When you do, you should be able to remove some dependencies, which Snowpack was
complaining about:

```json
{
  "scheduler": "0.23.0",
  "symbol-observable": "4.0.0",
  "ts-invariant": "0.10.3",
  "zen-observable-ts": "1.1.0"
}
```

...also seach for `_SNOWPACK` and delete
