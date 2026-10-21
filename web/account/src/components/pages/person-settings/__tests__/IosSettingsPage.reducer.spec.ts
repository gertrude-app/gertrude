import { describe, expect, test } from 'vitest';
import type { IosBlockerSettings } from '../IosSettingsPage.types';
import iosSettingsReducer, {
  blockedGroupsHaveUnsavedChanges,
  createIosSettingsFormState,
  extendedControlsHaveUnsavedChanges,
  extendedControlsInput,
  profileHasUnsavedChanges,
} from '../IosSettingsPage.reducer';

const blocker = (
  extendedSupervisionControls?: IosBlockerSettings[`extendedSupervisionControls`],
): IosBlockerSettings => ({
  allBlockGroups: [
    { id: `ads`, name: `Ads`, description: ``, longDescription: ``, optIn: false },
    { id: `gifs`, name: `GIFs`, description: ``, longDescription: ``, optIn: false },
    {
      id: `whatsApp`,
      name: `WhatsApp`,
      description: ``,
      longDescription: ``,
      optIn: true,
    },
  ],
  enabledBlockGroupIds: [`ads`],
  isSupervised: true,
  extendedSupervisionControls,
  profileSettings: {
    preventProtectionRemoval: true,
    allowDeletingApps: false,
    allowFactoryReset: false,
    allowInstallingApps: true,
  },
});

describe(`blocked groups`, () => {
  test(`starts clean`, () => {
    const state = createIosSettingsFormState(blocker());
    expect(blockedGroupsHaveUnsavedChanges(state.blockedGroups)).toBe(false);
  });

  test(`blocking a group adds it to the draft`, () => {
    const state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `blockGroupChanged`,
      id: `gifs`,
      blocked: true,
    });
    expect(state.blockedGroups.draft.enabledIds).toEqual([`ads`, `gifs`]);
    expect(state.blockedGroups.saved.enabledIds).toEqual([`ads`]); // saved untouched
    expect(blockedGroupsHaveUnsavedChanges(state.blockedGroups)).toBe(true);
  });

  test(`unblocking removes it`, () => {
    const state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `blockGroupChanged`,
      id: `ads`,
      blocked: false,
    });
    expect(state.blockedGroups.draft.enabledIds).toEqual([]);
    expect(blockedGroupsHaveUnsavedChanges(state.blockedGroups)).toBe(true);
  });

  test(`blocking an already-blocked group does not duplicate it`, () => {
    const state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `blockGroupChanged`,
      id: `ads`,
      blocked: true,
    });
    expect(state.blockedGroups.draft.enabledIds).toEqual([`ads`]);
  });

  test(`toggling back to the original set is not an unsaved change`, () => {
    let state = createIosSettingsFormState(blocker());
    state = iosSettingsReducer(state, {
      type: `blockGroupChanged`,
      id: `gifs`,
      blocked: true,
    });
    state = iosSettingsReducer(state, {
      type: `blockGroupChanged`,
      id: `gifs`,
      blocked: false,
    });
    expect(blockedGroupsHaveUnsavedChanges(state.blockedGroups)).toBe(false);
  });

  test(`order does not count as a change`, () => {
    const state = createIosSettingsFormState({
      ...blocker(),
      enabledBlockGroupIds: [`ads`, `gifs`],
    });
    const reordered = {
      ...state.blockedGroups,
      draft: { enabledIds: [`gifs`, `ads`] },
    };
    expect(blockedGroupsHaveUnsavedChanges(reordered)).toBe(false);
  });

  test(`save succeeded promotes the submitted set to saved`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `blockGroupChanged`,
      id: `gifs`,
      blocked: true,
    });
    state = iosSettingsReducer(state, {
      type: `blockedGroupsSaveSucceeded`,
      submitted: { enabledIds: [`ads`, `gifs`] },
    });
    expect(blockedGroupsHaveUnsavedChanges(state.blockedGroups)).toBe(false);
  });

  test(`edits made while a save is in flight survive the save`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `blockGroupChanged`,
      id: `gifs`,
      blocked: true,
    });
    const submitted = { enabledIds: [...state.blockedGroups.draft.enabledIds] };
    // parent keeps clicking while the request is in flight
    state = iosSettingsReducer(state, {
      type: `blockGroupChanged`,
      id: `whatsApp`,
      blocked: true,
    });
    state = iosSettingsReducer(state, { type: `blockedGroupsSaveSucceeded`, submitted });
    expect(state.blockedGroups.draft.enabledIds).toEqual([`ads`, `gifs`, `whatsApp`]);
    expect(blockedGroupsHaveUnsavedChanges(state.blockedGroups)).toBe(true);
  });
});

describe(`profile settings`, () => {
  test(`flipping a flag marks it unsaved`, () => {
    const state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `profileFlagChanged`,
      flag: `allowFactoryReset`,
      enabled: true,
    });
    expect(state.profile.draft.allowFactoryReset).toBe(true);
    expect(state.profile.saved.allowFactoryReset).toBe(false);
    expect(profileHasUnsavedChanges(state.profile)).toBe(true);
  });

  test(`save succeeded clears unsaved changes`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `profileFlagChanged`,
      flag: `preventProtectionRemoval`,
      enabled: false,
    });
    state = iosSettingsReducer(state, {
      type: `profileSaveSucceeded`,
      submitted: { ...state.profile.draft },
    });
    expect(profileHasUnsavedChanges(state.profile)).toBe(false);
  });
});

describe(`extended controls`, () => {
  test(`save payloads preserve false, zero, and enabled empty approval lists`, () => {
    const state = createIosSettingsFormState(
      blocker({
        allowSafari: false,
        ratingMovies: 0,
        whitelistedAppBundleIds: [],
        webAllowList: [],
      }),
    );
    expect(extendedControlsHaveUnsavedChanges(state.extended)).toBe(false);
    expect(extendedControlsInput(state.extended!.draft)).toEqual({
      allowSafari: false,
      ratingMovies: 0,
      whitelistedAppBundleIds: [],
      webAllowList: [],
    });
  });

  test(`disabled approval lists are omitted, not saved as empty enabled lists`, () => {
    let state = createIosSettingsFormState(
      blocker({
        whitelistedAppBundleIds: [`com.apple.mobilesafari`],
        webAllowList: [{ url: `https://gertrude.app`, title: `Gertrude` }],
      }),
    );
    state = iosSettingsReducer(state, {
      type: `extendedControlsChanged`,
      values: { whitelistedAppBundleIds: null, webAllowList: null },
    });
    const input = extendedControlsInput(state.extended!.draft);
    expect(input.whitelistedAppBundleIds).toBeUndefined();
    expect(input.webAllowList).toBeUndefined();
    expect(extendedControlsHaveUnsavedChanges(state.extended)).toBe(true);
  });

  test(`save results preserve newer edits until they are submitted`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker({})), {
      type: `extendedControlsChanged`,
      values: { allowSafari: false },
    });
    const submitted = { ...state.extended!.draft };
    state = iosSettingsReducer(state, {
      type: `extendedControlsChanged`,
      values: { whitelistedAppBundleIds: [`com.apple.MobileSMS`] },
    });
    state = iosSettingsReducer(state, {
      type: `extendedControlsSaveSucceeded`,
      submitted,
    });
    expect(state.extended!.saved).toEqual(submitted);
    expect(state.extended!.draft.whitelistedAppBundleIds).toEqual([
      `com.apple.MobileSMS`,
    ]);
    expect(extendedControlsHaveUnsavedChanges(state.extended)).toBe(true);
    state = iosSettingsReducer(state, {
      type: `extendedControlsSaveSucceeded`,
      submitted: state.extended!.draft,
    });
    expect(extendedControlsHaveUnsavedChanges(state.extended)).toBe(false);
  });

  test(`refetches refresh clean controls but preserve dirty edits`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker({})), {
      type: `settingsReceived`,
      blocker: blocker({ forceAutomaticDateAndTime: true }),
    });
    expect(state.extended!.draft.forceAutomaticDateAndTime).toBe(true);
    expect(extendedControlsHaveUnsavedChanges(state.extended)).toBe(false);
    state = iosSettingsReducer(state, {
      type: `extendedControlsChanged`,
      values: { allowSafari: false },
    });
    state = iosSettingsReducer(state, {
      type: `settingsReceived`,
      blocker: { ...blocker({ allowAssistant: false }), enabledBlockGroupIds: [`gifs`] },
    });
    expect(state.extended!.draft.allowSafari).toBe(false);
    expect(state.extended!.draft.allowAssistant).toBeNull();
    expect(state.blockedGroups.draft.enabledIds).toEqual([`gifs`]);
    expect(extendedControlsHaveUnsavedChanges(state.extended)).toBe(true);
  });

  test(`losing access discards drafts and ignores subsequent edits`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker({})), {
      type: `extendedControlsChanged`,
      values: { allowSafari: false },
    });
    state = iosSettingsReducer(state, { type: `settingsReceived`, blocker: blocker() });
    expect(state.extended).toBeUndefined();
    expect(extendedControlsHaveUnsavedChanges(state.extended)).toBe(false);
    expect(
      iosSettingsReducer(state, {
        type: `extendedControlsChanged`,
        values: { allowSafari: false },
      }),
    ).toBe(state);
  });
});

describe(`settingsReceived`, () => {
  test(`refetched server data replaces clean sections`, () => {
    const state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `settingsReceived`,
      blocker: { ...blocker(), enabledBlockGroupIds: [`ads`, `gifs`] },
    });
    expect(state.blockedGroups.draft.enabledIds).toEqual([`ads`, `gifs`]);
  });

  test(`refetched server data does NOT clobber a dirty section`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `blockGroupChanged`,
      id: `whatsApp`,
      blocked: true,
    });
    state = iosSettingsReducer(state, {
      type: `settingsReceived`,
      blocker: { ...blocker(), enabledBlockGroupIds: [`gifs`] },
    });
    expect(state.blockedGroups.draft.enabledIds).toEqual([`ads`, `whatsApp`]);
  });

  test(`a dirty section does not block a clean sibling from updating`, () => {
    let state = iosSettingsReducer(createIosSettingsFormState(blocker()), {
      type: `blockGroupChanged`,
      id: `gifs`,
      blocked: true,
    });
    state = iosSettingsReducer(state, {
      type: `settingsReceived`,
      blocker: {
        ...blocker(),
        profileSettings: {
          preventProtectionRemoval: false,
          allowDeletingApps: true,
          allowFactoryReset: true,
          allowInstallingApps: false,
        },
      },
    });
    expect(state.blockedGroups.draft.enabledIds).toEqual([`ads`, `gifs`]); // still dirty
    expect(state.profile.draft.allowDeletingApps).toBe(true); // clean, so updated
  });
});
