# Gertie Smoke Tests

For local testing, add a `./smoke/cypress.env.json` with values like:

```json
{
  "SMOKE_TEST_TESTMAIL_NAMESPACE": "your-ns",
  "SMOKE_TEST_EMAIL_INBOX_URL": "https://api.testmail.app/api/json?apikey=not-real&namespace=your-ns",
  "SMOKE_TEST_API_URL": "http://localhost:2222"
}
```
