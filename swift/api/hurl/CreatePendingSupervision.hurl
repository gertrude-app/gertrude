POST {{API_URL}}/pairql/ios-app/CreatePendingSupervision
{
  "vendorId": "deadbeef-dead-beef-dead-beefdeadbeef",
  "deviceType": "iPhone",
  "iosVersion": "26.2",
  "appVersion": "1.5.0"
}

HTTP 200
[Asserts]
jsonpath "$.code" isInteger
jsonpath "$.expiresAt" exists
