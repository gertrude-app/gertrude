import { EditKey, convert, newKeyState } from '@dash/keys';
import { beforeEach, describe, expect, test } from 'vitest';
import reducer from '../edit-key-reducer';

describe(`editKeyReducer()`, () => {
  let state: EditKey.State;

  beforeEach(() => {
    state = newKeyState(`keyid`, `keychainId`);
  });

  test(`toggles strict/standard address type when unlock request address present`, () => {
    state = convert.unlockRequestToState(`keyid`, `keychainId`, {
      url: `https://cdn.foobar.com/jim/jam.js`,
      appCategories: [`browser`],
      appBundleId: `com.brave`,
      appSlug: `brave`,
    });
    state.activeStep = EditKey.Step.SetAddress;
    expect(state.address).toBe(`foobar.com`);

    // toggle to strict, we they shouldn't have to restore the `cdn.` subdomain
    reducer(state, { type: `setAddressType`, to: `strict` });

    expect(state.address).toBe(`cdn.foobar.com`);
    expect(state.addressType).toBe(`strict`);

    // back to standard
    reducer(state, { type: `setAddressType`, to: `standard` });

    expect(state.address).toBe(`foobar.com`);
    expect(state.addressType).toBe(`standard`);
  });

  const nextPrevCases: Array<[string, `next` | `prev`, EditKey.Step, () => void]> = [
    [
      `back from normal key expiration`,
      `prev`,
      EditKey.Step.SetAppScope,
      () => {
        state.activeStep = EditKey.Step.Expiration;
      },
    ],
    [
      `back from single app key expiration`,
      `prev`,
      EditKey.Step.Advanced_ChooseApp,
      () => {
        state.activeStep = EditKey.Step.Expiration;
        state.addressScope = `singleApp`; // <-- advanced option
      },
    ],
    [
      `forward from advanced address scope`,
      `next`,
      EditKey.Step.Advanced_ChooseApp,
      () => {
        state.activeStep = EditKey.Step.SetAppScope;
        state.addressScope = `singleApp`; // <-- advanced option
      },
    ],
    [
      `forward from advanced choose app`,
      `next`,
      EditKey.Step.Expiration,
      () => {
        state.activeStep = EditKey.Step.Advanced_ChooseApp;
        state.addressScope = `singleApp`; // <-- advanced option
      },
    ],
  ];

  test.each(nextPrevCases)(`%s`, (_title, dir, expected, setup) => {
    setup();
    reducer(state, { type: dir === `next` ? `nextStepClicked` : `prevStepClicked` });
    expect(state.activeStep).toBe(expected);
  });

  test(`key creation flow`, () => {
    // new key starts on the address step
    expect(state.activeStep).toBe(EditKey.Step.SetAddress);

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
    expect(state.activeStep).toBe(EditKey.Step.SetAppScope);

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
    expect(state.expiration).toMatch(/^2029-11-\d\dT/);

    // set expiration time
    reducer(state, { type: `setExpirationTime`, to: `17:33` });
    expect(state.expiration).toMatch(/T17:33:00.000Z$/);

    // go on to next step, comment
    reducer(state, { type: `nextStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.Comment);

    // update the comment
    reducer(state, { type: `setComment`, to: `this is a comment` });
    expect(state.comment).toBe(`this is a comment`);

    // now back to the first step
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.Expiration);
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.SetAppScope);
    reducer(state, { type: `prevStepClicked` });
    expect(state.activeStep).toBe(EditKey.Step.SetAddress);

    // choosing a single app scope
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
