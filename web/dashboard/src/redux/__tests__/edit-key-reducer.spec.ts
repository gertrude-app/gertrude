import { expect, test, describe, beforeEach } from 'vitest';
import { newKeyState } from '@dashboard/lib/keys';
import * as EditKey from '@dashboard/lib/keys/edit';
import reducer from '../edit-key-reducer';

describe(`editKeyReducer()`, () => {
  let state: EditKey.State;

  beforeEach(() => {
    state = newKeyState(`abc123`);
  });

  test(`changing keyType`, () => {
    reducer(state, { type: `setKeyType`, to: `app` });
    expect(state.keyType).toBe(`app`);
  });

  const nextPrevCases: Array<[string, () => ['next' | 'prev', EditKey.Step]]> = [
    [
      `back from normal website key expiration`,
      () => {
        state.activeStep = EditKey.Step.Expiration;
        state.keyType = `website`;
        return [`prev`, EditKey.Step.WebsiteKey_SetAppScope];
      },
    ],
    [
      `back from single app website key expiration`,
      () => {
        state.activeStep = EditKey.Step.Expiration;
        state.keyType = `website`;
        state.addressScope = `singleApp`; // <-- advanced option
        return [`prev`, EditKey.Step.WebsiteKey_Advanced_ChooseApp];
      },
    ],
    [
      `back from normal app key expiration`,
      () => {
        state.activeStep = EditKey.Step.Expiration;
        state.keyType = `app`;
        return [`prev`, EditKey.Step.AppKey_SetAppScope];
      },
    ],
    [
      `back from advanced address-scoped app key expiration`,
      () => {
        state.activeStep = EditKey.Step.Expiration;
        state.keyType = `app`;
        state.appScope = `address`; // <-- advanced option
        return [`prev`, EditKey.Step.AppKey_Advanced_SetAddress];
      },
    ],
    [
      `forward from website key advanced address scope`,
      () => {
        state.keyType = `website`;
        state.activeStep = EditKey.Step.WebsiteKey_SetAppScope;
        state.addressScope = `singleApp`; // <-- advanced option
        return [`next`, EditKey.Step.WebsiteKey_Advanced_ChooseApp];
      },
    ],
    [
      `forward from website key advanced choose app`,
      () => {
        state.keyType = `website`;
        state.activeStep = EditKey.Step.WebsiteKey_Advanced_ChooseApp;
        state.addressScope = `singleApp`; // <-- advanced option
        return [`next`, EditKey.Step.Expiration];
      },
    ],
  ];

  test.each(nextPrevCases)(`%s`, (_title, setup) => {
    const [dir, expected] = setup();
    reducer(state, { type: dir === `next` ? `nextStepClicked` : `prevStepClicked` });
    expect(state.activeStep).toBe(expected);
  });

  test(`key creation flow`, () => {
    state.keyType = `website`;

    // go forward to websiteKey_setAddress
    reducer(state, { type: `nextStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.WebsiteKey_SetAddress);

    // update the address
    reducer(state, { type: `setAddress`, to: `goats.com` });
    expect(state.address).toBe(`goats.com`);

    // set show advanced address options
    reducer(state, { type: `setShowAdvancedAddressOptions`, to: true });
    expect(state.showAdvancedAddressOptions).toBe(true);

    // set address type to strict
    reducer(state, { type: `setAddressType`, to: `strict` });
    expect(state.addressType).toBe(`strict`);

    // go to next step, set address scope
    reducer(state, { type: `nextStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.WebsiteKey_SetAppScope);

    // set app scope to unrestricted
    reducer(state, { type: `setAddressScope`, to: `unrestricted` });
    expect(state.addressScope).toBe(`unrestricted`);

    // enable addvanced app scope options
    reducer(state, { type: `setShowAdvancedAddressScopeOptions`, to: true });
    expect(state.showAdvancedAddressScopeOptions).toBe(true);

    // set address scope to be the "advanced" single app option
    reducer(state, { type: `setAddressScope`, to: `singleApp` });
    expect(state.addressScope).toBe(`singleApp`);

    // now disable advanced app scope options
    reducer(state, { type: `setShowAdvancedAddressScopeOptions`, to: false });
    // because the selected option is no longer visible, set it backTo webBrowsers
    expect(state.addressScope).toBe(`webBrowsers`);

    // go to next step, set expiration
    reducer(state, { type: `nextStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.Expiration);

    // set expiration
    expect(state.expiration).toBeUndefined();
    reducer(state, { type: `setExpirationDate`, to: `2029-11-29` });
    expect(state.expiration).toMatch(/^2029-11-29T/);

    // set expiration time
    reducer(state, { type: `setExpirationTime`, to: `17:33` });
    expect(state.expiration).toMatch(/T17:33:00.000Z$/);

    // go on to next step, comment
    reducer(state, { type: `nextStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.Comment);

    // update the comment
    reducer(state, { type: `setComment`, to: `this is a comment` });
    expect(state.comment).toBe(`this is a comment`);

    // now back to setKeyType
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.Expiration);
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.WebsiteKey_SetAppScope);
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.WebsiteKey_SetAddress);
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.SetKeyType);

    // now set type toApp and go forward to appKey_chooseApp
    reducer(state, { type: `setKeyType`, to: `app` });
    reducer(state, { type: `nextStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.AppKey_ChooseApp);

    // now back to setKeyType
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.SetKeyType);

    // set the application name
    reducer(state, { type: `setAppSlug`, to: `slack` });
    expect(state.appSlug).toBe(`slack`);

    // switch app identification method to bundle id
    reducer(state, { type: `setAppIdentificationType`, to: `bundleId` });
    expect(state.appIdentificationType).toBe(`bundleId`);

    // set the bundle id
    reducer(state, { type: `setAppBundleId`, to: `com.slack.Slack` });
    expect(state.appBundleId).toBe(`com.slack.Slack`);
  });
});
