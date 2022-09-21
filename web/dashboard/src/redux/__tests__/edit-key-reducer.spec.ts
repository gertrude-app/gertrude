import { expect, test, describe, beforeEach } from 'vitest';
import { newKeyState } from '@dashboard/lib/keys';
import reducer from '../edit-key-reducer';

describe(`editKeyReducer()`, () => {
  let state: EditKey.State;

  beforeEach(() => {
    state = newKeyState();
  });

  test(`changing keyType`, () => {
    reducer(state, { set: `keyType`, to: `app` });
    expect(state.keyType).toBe(`app`);
  });

  const nextPrevCases: Array<[string, () => ['next' | 'prev', EditKey.Step]]> = [
    [
      `back from normal website key expiration`,
      () => {
        state.currentStep = `expiration`;
        state.keyType = `website`;
        return [`prev`, `websiteKey_setAppScope`];
      },
    ],
    [
      `back from single app website key expiration`,
      () => {
        state.currentStep = `expiration`;
        state.keyType = `website`;
        state.addressScope = `singleApp`; // <-- advanced option
        return [`prev`, `websiteKey_chooseApp`];
      },
    ],
    [
      `back from normal app key expiration`,
      () => {
        state.currentStep = `expiration`;
        state.keyType = `app`;
        return [`prev`, `appKey_setAppScope`];
      },
    ],
    [
      `back from advanced address-scoped app key expiration`,
      () => {
        state.currentStep = `expiration`;
        state.keyType = `app`;
        state.appScope = `address`; // <-- advanced option
        return [`prev`, `appKey_setAddress`];
      },
    ],
    [
      `forward from website key advanced address scope`,
      () => {
        state.keyType = `website`;
        state.currentStep = `websiteKey_setAppScope`;
        state.addressScope = `singleApp`; // <-- advanced option
        return [`next`, `websiteKey_chooseApp`];
      },
    ],
    [
      `forward from website key advanced choose app`,
      () => {
        state.keyType = `website`;
        state.currentStep = `websiteKey_chooseApp`;
        state.addressScope = `singleApp`; // <-- advanced option
        return [`next`, `expiration`];
      },
    ],
  ];

  test.each(nextPrevCases)(`%s`, (_title, setup) => {
    const [dir, expected] = setup();
    reducer(state, { set: `currentStep`, to: dir });
    expect(state.currentStep).toBe(expected);
  });

  test(`key creation flow`, () => {
    state.keyType = `website`;

    // go forward to websiteKey_setAddress
    reducer(state, { set: `currentStep`, to: `next` });
    expect(state.currentStep).toBe(`websiteKey_setAddress`);

    // update the address
    reducer(state, { set: `address`, to: `goats.com` });
    expect(state.address).toBe(`goats.com`);

    // set show advanced address options
    reducer(state, { set: `showAdvancedAddressOptions`, to: true });
    expect(state.showAdvancedAddressOptions).toBe(true);

    // set address type to strict
    reducer(state, { set: `addressType`, to: `strict` });
    expect(state.addressType).toBe(`strict`);

    // go to next step, set address scope
    reducer(state, { set: `currentStep`, to: `next` });
    expect(state.currentStep).toBe(`websiteKey_setAppScope`);

    // set app scope to unrestricted
    reducer(state, { set: `addressScope`, to: `unrestricted` });
    expect(state.addressScope).toBe(`unrestricted`);

    // enable addvanced app scope options
    reducer(state, { set: `showAdvancedAddressScopeOptions`, to: true });
    expect(state.showAdvancedAddressScopeOptions).toBe(true);

    // set address scope to be the "advanced" single app option
    reducer(state, { set: `addressScope`, to: `singleApp` });
    expect(state.addressScope).toBe(`singleApp`);

    // now disable advanced app scope options
    reducer(state, { set: `showAdvancedAddressScopeOptions`, to: false });
    // because the selected option is no longer visible, set it backTo webBrowsers
    expect(state.addressScope).toBe(`webBrowsers`);

    // go to next step, set expiration
    reducer(state, { set: `currentStep`, to: `next` });
    expect(state.currentStep).toBe(`expiration`);

    // set expiration
    expect(state.expiration).toBeUndefined();
    reducer(state, { set: `expirationDate`, to: `2029-11-29` });
    expect(state.expiration).toMatch(/^2029-11-29T/);

    // set expiration time
    reducer(state, { set: `expirationTime`, to: `17:33` });
    expect(state.expiration).toMatch(/T17:33:00.000Z$/);

    // go on to next step, comment
    reducer(state, { set: `currentStep`, to: `next` });
    expect(state.currentStep).toBe(`comment`);

    // update the comment
    reducer(state, { set: `comment`, to: `this is a comment` });
    expect(state.comment).toBe(`this is a comment`);

    // now back to setKeyType
    reducer(state, { set: `currentStep`, to: `prev` });
    expect(state.currentStep).toBe(`expiration`);
    reducer(state, { set: `currentStep`, to: `prev` });
    expect(state.currentStep).toBe(`websiteKey_setAppScope`);
    reducer(state, { set: `currentStep`, to: `prev` });
    expect(state.currentStep).toBe(`websiteKey_setAddress`);
    reducer(state, { set: `currentStep`, to: `prev` });
    expect(state.currentStep).toBe(`setKeyType`);

    // now set type toApp and go forward to appKey_chooseApp
    reducer(state, { set: `keyType`, to: `app` });
    reducer(state, { set: `currentStep`, to: `next` });
    expect(state.currentStep).toBe(`appKey_chooseApp`);

    // now back to setKeyType
    reducer(state, { set: `currentStep`, to: `prev` });
    expect(state.currentStep).toBe(`setKeyType`);

    // set the application name
    reducer(state, { set: `appSlug`, to: `slack` });
    expect(state.appSlug).toBe(`slack`);

    // switch app identification method to bundle id
    reducer(state, { set: `appIdentificationType`, to: `bundleId` });
    expect(state.appIdentificationType).toBe(`bundleId`);

    // set the bundle id
    reducer(state, { set: `appBundleId`, to: `com.slack.Slack` });
    expect(state.appBundleId).toBe(`com.slack.Slack`);
  });
});
