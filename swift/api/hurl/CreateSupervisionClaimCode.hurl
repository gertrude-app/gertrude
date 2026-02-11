POST {{API_URL}}/pairql/ios-app/CreateSupervisionClaimCode
{
  "deviceId": "deadbeef-dead-beef-dead-beefdeadbeef",
  "modelIdentifier": "iPhone18,2",
  "iosVersion": "26.2",
  "appVersion": "1.5.0"
}

HTTP 200
[Asserts]
jsonpath "$.code" isInteger
jsonpath "$.expiresAt" exists
