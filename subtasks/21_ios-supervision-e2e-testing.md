# Task 21: ios-supervision-e2e-testing

## Summary

End-to-end testing of the complete supervision onboarding flow.

## Type

🔒 Blocking (before release)

## Dependencies

**Blocked by:** All iOS tasks (12-16), all API tasks, supervision tool tasks
**Blocks:** Release

## Details

Comprehensive testing of the full supervision flow before release.

### Test Scenarios

#### 1. Happy Path (Ben + Luke Scenario)

Full walkthrough as documented in `supervision-flow-script.md`:
1. Luke opens Gertrude on iPhone, identifies as 18+
2. App generates code, shows handoff instructions
3. Ben visits `gertrude.app/s/ABC123` on Mac
4. Ben signs up/signs in, claims code, names "Luke"
5. Ben downloads supervision tool
6. Ben enters code in tool, connects Luke's iPhone
7. Supervision completes, phone reboots
8. Luke opens Gertrude app
9. App detects supervised status
10. Profile installation flow
11. Filter running, setup complete

#### 2. Luke Initiates Alone

- Luke generates code on his phone
- Luke texts code to Ben (not in same room)
- Ben claims code later
- Luke's app shows "code not claimed" then updates

#### 3. Existing Account

- Ben already has Gertrude account with Mac app child
- Ben adds supervised iOS device
- Verify existing child/Mac setup not affected

#### 4. Interrupted Flow - App Killed

- Luke generates code
- Luke force-quits app
- Ben claims code
- Ben supervises device
- Phone reboots
- Luke opens app
- Verify: app recovers, finds stored code, continues flow

#### 5. Interrupted Flow - Delayed Completion

- Luke generates code
- Ben claims code
- Ben doesn't run supervision tool for 24 hours
- Luke reopens app periodically
- Verify: app shows "waiting" state, doesn't break

#### 6. Network Errors

- Test each API call with network failure
- Verify: appropriate error messages, retry options

#### 7. Supervision Verification Failed

- User taps "No, I don't see it" in tool
- Verify: appropriate troubleshooting flow

#### 8. Profile Installation Cancelled

- User cancels Safari download
- User doesn't install profile in Settings
- Verify: app handles gracefully, allows retry

#### 9. Code Expiration

- Generate code, let it expire (7 days)
- Verify: appropriate error, option to generate new code

#### 10. Multiple Devices

- Ben sets up two supervised devices
- Verify: both work independently

### Testing Checklist

- [ ] All 10 scenarios pass
- [ ] Error messages are clear and actionable
- [ ] No data loss in interrupted flows
- [ ] State persists correctly across app kills
- [ ] Token/credentials stored securely
- [ ] Dashboard shows correct status throughout
- [ ] Supervision tool reports completion correctly

### Test Devices

- iPhone with iOS 17.x
- iPhone with iOS 18.x
- Various iPhone models (SE, regular, Pro)

### Documentation

Document any edge cases discovered during testing for future reference.

### Files

- Create test plan document if needed
- May need to add automated tests where possible
- Manual testing required for full device flow
