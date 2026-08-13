import { describe, expect, test } from 'vitest';
import type { MacKeychain, MacSettingsConfiguration } from '../MacSettingsPage.types';
import macSettingsReducer, {
  appsConfiguration,
  appsHaveUnsavedChanges,
  createMacSettingsFormState,
  defaultDowntime,
  internetFilteringConfiguration,
  internetFilteringHasUnsavedChanges,
  monitoringConfiguration,
  monitoringHasUnsavedChanges,
  monitoringSubmission,
  monitoringValidation,
} from '../MacSettingsPage.reducer';

const familyKeychain = (): MacKeychain => ({
  id: `family`,
  name: `Family`,
  description: `Everyday websites and services.`,
  isPublic: false,
  isOwn: true,
  numKeys: 42,
});

const schoolKeychain = (): MacKeychain => ({
  id: `school`,
  name: `School`,
  isPublic: true,
  isOwn: false,
  numKeys: 18,
});

const settings = (): MacSettingsConfiguration => ({
  keyloggingEnabled: false,
  showSuspensionActivity: false,
  screenshots: {
    enabled: true,
    resolution: 1080,
    frequency: 120,
    canBeDisabled: true,
  },
  internetFiltering: {
    enabled: true,
    canBeDisabled: true,
    keychains: [familyKeychain()],
    availableKeychains: [familyKeychain(), schoolKeychain()],
    supportsAlwaysBlocked: true,
    availableAlwaysBlockedGroups: [
      {
        id: `adult-content`,
        name: `Adult Content`,
        description: `Adult sites`,
        longDescription: `Adult sites and domains`,
      },
      {
        id: `social-media`,
        name: `Social Media`,
        description: `Social sites`,
        longDescription: `Social media sites`,
      },
    ],
    alwaysBlockedGroupIds: [`adult-content`],
    customAlwaysBlockedRules: [
      {
        id: `reddit`,
        rule: { case: `hostnameOrSubdomain`, value: `reddit.com` },
      },
    ],
  },
  apps: {
    blocked: [
      {
        id: `blocked-minecraft`,
        identifier: `com.mojang.minecraftlauncher`,
      },
    ],
    unrestricted: [
      {
        id: `unrestricted-browser`,
        scope: { type: `identifiedAppSlug`, identifiedAppSlug: `chrome` },
      },
    ],
    publicUnrestricted: [],
  },
  hasMacDevices: true,
});

describe(`macSettingsReducer()`, () => {
  test(`initializes clean forms and produces save configurations`, () => {
    const state = createMacSettingsFormState(settings());

    expect(monitoringHasUnsavedChanges(state.monitoring)).toBe(false);
    expect(internetFilteringHasUnsavedChanges(state.internetFiltering)).toBe(false);
    expect(appsHaveUnsavedChanges(state.apps)).toBe(false);
    expect(monitoringConfiguration(state.monitoring.draft)).toEqual({
      keyloggingEnabled: false,
      showSuspensionActivity: false,
      screenshots: {
        enabled: true,
        resolution: 1080,
        frequency: 120,
      },
    });
    expect(internetFilteringConfiguration(state.internetFiltering.draft)).toEqual({
      filteringEnabled: true,
      downtime: undefined,
      keychains: [{ id: `family`, schedule: undefined }],
      alwaysBlockedGroupIds: [`adult-content`],
      customAlwaysBlockedRules: [
        {
          id: `reddit`,
          rule: { case: `hostnameOrSubdomain`, value: `reddit.com` },
        },
      ],
    });
  });

  test(`updates blocked apps while preserving unrestricted apps`, () => {
    let state = createMacSettingsFormState(settings());
    const schedule = {
      type: `inactive`,
      days: {
        sunday: true,
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: true,
      },
      startTime: { hour: 8, minute: 0 },
      endTime: { hour: 15, minute: 0 },
    } as const;

    state = macSettingsReducer(state, {
      type: `blockedAppsAdded`,
      apps: [
        {
          id: `blocked-discord`,
          identifier: `com.hnc.Discord`,
          name: `Discord`,
        },
      ],
    });
    state = macSettingsReducer(state, {
      type: `blockedAppScheduleChanged`,
      id: `blocked-discord`,
      schedule,
    });
    state = macSettingsReducer(state, {
      type: `blockedAppRemoved`,
      id: `blocked-minecraft`,
    });

    expect(appsConfiguration(state.apps.draft)).toEqual({
      blockedApps: [
        {
          id: `blocked-discord`,
          identifier: `com.hnc.Discord`,
          schedule,
        },
      ],
      unrestrictedApps: [
        {
          id: `unrestricted-browser`,
          scope: { type: `identifiedAppSlug`, identifiedAppSlug: `chrome` },
          schedule: undefined,
        },
      ],
    });
    expect(appsHaveUnsavedChanges(state.apps)).toBe(true);

    state = macSettingsReducer(state, {
      type: `appsSaveSucceeded`,
      submitted: state.apps.draft,
    });

    expect(appsHaveUnsavedChanges(state.apps)).toBe(false);
  });

  test(`keeps public unrestricted apps outside the editable save payload`, () => {
    const configuration = settings();
    configuration.apps.publicUnrestricted = [
      {
        keychainId: `school`,
        keychainName: `School`,
        scope: { type: `bundleId`, bundleId: `edu.mit.scratch` },
      },
    ];
    const state = createMacSettingsFormState(configuration);

    expect(appsConfiguration(state.apps.draft)).toEqual({
      blockedApps: [
        {
          id: `blocked-minecraft`,
          identifier: `com.mojang.minecraftlauncher`,
          schedule: undefined,
        },
      ],
      unrestrictedApps: [
        {
          id: `unrestricted-browser`,
          scope: { type: `identifiedAppSlug`, identifiedAppSlug: `chrome` },
          schedule: undefined,
        },
      ],
    });
    expect(appsHaveUnsavedChanges(state.apps)).toBe(false);
  });

  test(`refreshes public unrestricted apps while editable apps are dirty`, () => {
    let state = createMacSettingsFormState(settings());
    state = macSettingsReducer(state, {
      type: `blockedAppRemoved`,
      id: `blocked-minecraft`,
    });
    const received = settings();
    received.apps.publicUnrestricted = [
      {
        keychainId: `school`,
        keychainName: `School`,
        scope: { type: `bundleId`, bundleId: `edu.mit.scratch` },
      },
    ];

    state = macSettingsReducer(state, { type: `settingsReceived`, settings: received });

    expect(state.apps.draft.blocked).toEqual([]);
    expect(state.apps.draft.publicUnrestricted).toEqual(received.apps.publicUnrestricted);
    expect(appsHaveUnsavedChanges(state.apps)).toBe(true);
  });

  test(`updates unrestricted apps while preserving blocked apps`, () => {
    let state = createMacSettingsFormState(settings());
    const schedule = {
      type: `active`,
      days: {
        sunday: false,
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: false,
      },
      startTime: { hour: 8, minute: 0 },
      endTime: { hour: 15, minute: 0 },
    } as const;

    state = macSettingsReducer(state, {
      type: `unrestrictedAppsAdded`,
      apps: [
        {
          id: `unrestricted-scratch`,
          scope: { type: `bundleId`, bundleId: `edu.mit.scratch` },
          name: `Scratch`,
        },
      ],
    });
    state = macSettingsReducer(state, {
      type: `unrestrictedAppScheduleChanged`,
      id: `unrestricted-scratch`,
      schedule,
    });
    state = macSettingsReducer(state, {
      type: `unrestrictedAppRemoved`,
      id: `unrestricted-browser`,
    });

    expect(appsConfiguration(state.apps.draft)).toEqual({
      blockedApps: [
        {
          id: `blocked-minecraft`,
          identifier: `com.mojang.minecraftlauncher`,
          schedule: undefined,
        },
      ],
      unrestrictedApps: [
        {
          id: `unrestricted-scratch`,
          scope: { type: `bundleId`, bundleId: `edu.mit.scratch` },
          schedule,
        },
      ],
    });
    expect(appsHaveUnsavedChanges(state.apps)).toBe(true);
  });

  test(`uses identified app scopes and serializes display metadata away`, () => {
    let state = createMacSettingsFormState(settings());

    state = macSettingsReducer(state, {
      type: `unrestrictedAppsAdded`,
      apps: [
        {
          id: `unrestricted-discord`,
          scope: { type: `identifiedAppSlug`, identifiedAppSlug: `discord` },
          name: `Discord`,
          appIconUrl: `/discord.png`,
        },
      ],
    });

    expect(appsConfiguration(state.apps.draft).unrestrictedApps[1]).toEqual({
      id: `unrestricted-discord`,
      scope: { type: `identifiedAppSlug`, identifiedAppSlug: `discord` },
      schedule: undefined,
    });
  });

  test(`does not add duplicate unrestricted scopes`, () => {
    let state = createMacSettingsFormState(settings());

    state = macSettingsReducer(state, {
      type: `unrestrictedAppsAdded`,
      apps: [
        {
          id: `duplicate-browser`,
          scope: { type: `identifiedAppSlug`, identifiedAppSlug: `chrome` },
        },
      ],
    });

    expect(state.apps.draft.unrestricted).toHaveLength(1);
    expect(appsHaveUnsavedChanges(state.apps)).toBe(false);
  });

  test(`updates downtime and includes it in the filtering configuration`, () => {
    let state = createMacSettingsFormState(settings());

    state = macSettingsReducer(state, {
      type: `downtimeEnabledChanged`,
      enabled: true,
    });

    expect(state.internetFiltering.draft.downtime).toEqual(defaultDowntime);
    expect(internetFilteringHasUnsavedChanges(state.internetFiltering)).toBe(true);

    const downtime = {
      start: { hour: 22, minute: 30 },
      end: { hour: 6, minute: 15 },
    };
    state = macSettingsReducer(state, { type: `downtimeChanged`, downtime });

    expect(
      internetFilteringConfiguration(state.internetFiltering.draft).downtime,
    ).toEqual(downtime);

    state = macSettingsReducer(state, {
      type: `downtimeEnabledChanged`,
      enabled: false,
    });

    expect(state.internetFiltering.draft.downtime).toBeUndefined();
    expect(internetFilteringHasUnsavedChanges(state.internetFiltering)).toBe(false);
  });

  test(`validates monitoring drafts and restores hidden screenshot values`, () => {
    let state = createMacSettingsFormState(settings());
    state = macSettingsReducer(state, {
      type: `monitoringFrequencyChanged`,
      value: `9`,
    });
    state = macSettingsReducer(state, {
      type: `monitoringResolutionChanged`,
      value: ``,
    });

    expect(monitoringValidation(state.monitoring.draft)).toEqual({
      frequency: undefined,
      resolution: undefined,
      frequencyError: `Enter a whole number of at least 10 seconds.`,
      resolutionError: `Resolution is required.`,
    });
    expect(monitoringConfiguration(state.monitoring.draft)).toBeUndefined();

    state = macSettingsReducer(state, {
      type: `monitoringScreenshotsChanged`,
      enabled: false,
    });

    expect(state.monitoring.draft).toMatchObject({
      screenshotsEnabled: false,
      frequencyDraft: `120`,
      resolutionDraft: `1080`,
    });
  });

  test(`normalizes monitoring input when a save starts`, () => {
    let state = createMacSettingsFormState(settings());
    state = macSettingsReducer(state, {
      type: `monitoringFrequencyChanged`,
      value: `0120`,
    });
    const submission = monitoringSubmission(state.monitoring.draft);

    expect(submission).toMatchObject({
      draft: { frequencyDraft: `120` },
      configuration: { screenshots: { frequency: 120 } },
    });

    state = macSettingsReducer(state, {
      type: `monitoringSaveStarted`,
      submitted: submission!.draft,
    });
    state = macSettingsReducer(state, {
      type: `monitoringSaveSucceeded`,
      submitted: submission!.draft,
    });

    expect(state.monitoring.draft.frequencyDraft).toBe(`120`);
    expect(monitoringHasUnsavedChanges(state.monitoring)).toBe(false);
  });

  test(`refreshes clean slices without overwriting a dirty sibling`, () => {
    let state = createMacSettingsFormState(settings());
    state = macSettingsReducer(state, {
      type: `monitoringKeyloggingChanged`,
      enabled: true,
    });
    const received = settings();
    received.keyloggingEnabled = true;
    received.showSuspensionActivity = true;
    received.internetFiltering.enabled = false;
    received.internetFiltering.keychains = [schoolKeychain()];

    state = macSettingsReducer(state, { type: `settingsReceived`, settings: received });

    expect(state.monitoring.draft).toMatchObject({
      keyloggingEnabled: true,
      showSuspensionActivity: false,
    });
    expect(monitoringHasUnsavedChanges(state.monitoring)).toBe(true);
    expect(state.internetFiltering.draft).toMatchObject({
      filteringEnabled: false,
      keychains: [{ id: `school` }],
    });
    expect(internetFilteringHasUnsavedChanges(state.internetFiltering)).toBe(false);

    state = macSettingsReducer(state, {
      type: `monitoringSaveSucceeded`,
      submitted: state.monitoring.draft,
    });
    state = macSettingsReducer(state, { type: `settingsReceived`, settings: received });

    expect(state.monitoring.draft.showSuspensionActivity).toBe(true);
    expect(monitoringHasUnsavedChanges(state.monitoring)).toBe(false);
  });

  test(`commits the submitted snapshot without clearing newer edits`, () => {
    let state = createMacSettingsFormState(settings());
    state = macSettingsReducer(state, {
      type: `filteringEnabledChanged`,
      enabled: false,
    });
    const submitted = state.internetFiltering.draft;
    state = macSettingsReducer(state, {
      type: `alwaysBlockedGroupChanged`,
      id: `social-media`,
      blocked: true,
    });

    state = macSettingsReducer(state, {
      type: `internetFilteringSaveSucceeded`,
      submitted,
    });

    expect(state.internetFiltering.saved.filteringEnabled).toBe(false);
    expect(state.internetFiltering.saved.alwaysBlockedGroupIds).toEqual([
      `adult-content`,
    ]);
    expect(state.internetFiltering.draft.alwaysBlockedGroupIds).toEqual([
      `adult-content`,
      `social-media`,
    ]);
    expect(internetFilteringHasUnsavedChanges(state.internetFiltering)).toBe(true);

    state = macSettingsReducer(state, {
      type: `internetFilteringSaveSucceeded`,
      submitted: state.internetFiltering.draft,
    });

    expect(internetFilteringHasUnsavedChanges(state.internetFiltering)).toBe(false);
  });

  test(`updates filtering collections without losing advanced rules`, () => {
    let state = createMacSettingsFormState(settings());
    const schedule = {
      type: `active`,
      days: {
        sunday: false,
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: false,
      },
      startTime: { hour: 8, minute: 0 },
      endTime: { hour: 16, minute: 0 },
    } as const;
    const rules = [
      {
        id: `advanced`,
        comment: `Preserve this rule`,
        rule: {
          case: `both`,
          a: { case: `bundleIdContains`, value: `com.example.app` },
          b: { case: `hostnameOrSubdomain`, value: `example.com` },
        },
      },
    ] as const;

    state = macSettingsReducer(state, {
      type: `keychainsAdded`,
      keychains: [familyKeychain(), schoolKeychain()],
    });
    state = macSettingsReducer(state, {
      type: `keychainScheduleChanged`,
      id: `school`,
      schedule,
    });
    state = macSettingsReducer(state, { type: `keychainRemoved`, id: `family` });
    state = macSettingsReducer(state, {
      type: `customAlwaysBlockedRulesChanged`,
      rules: [...rules],
    });

    expect(internetFilteringConfiguration(state.internetFiltering.draft)).toEqual({
      filteringEnabled: true,
      downtime: undefined,
      keychains: [{ id: `school`, schedule }],
      alwaysBlockedGroupIds: [`adult-content`],
      customAlwaysBlockedRules: rules,
    });
  });
});
