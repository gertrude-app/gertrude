import type { CustomAlwaysBlockedRule, Schedule } from '#/components/types';
import type {
  BlockedMacApp,
  DowntimeWindow,
  InternetFilteringConfiguration,
  MacAppsConfiguration,
  MacKeychain,
  MacMonitoringConfiguration,
  MacSettingsConfiguration,
  PublicUnrestrictedMacApp,
  UnrestrictedMacApp,
} from './MacSettingsPage.types';

export interface MonitoringDraft {
  keyloggingEnabled: boolean;
  screenshotsEnabled: boolean;
  showSuspensionActivity: boolean;
  frequencyDraft: string;
  resolutionDraft: string;
}

export interface InternetFilteringDraft {
  filteringEnabled: boolean;
  downtime?: DowntimeWindow;
  keychains: MacKeychain[];
  alwaysBlockedGroupIds: string[];
  customAlwaysBlockedRules: CustomAlwaysBlockedRule[];
}

export interface AppsDraft {
  blocked: BlockedMacApp[];
  unrestricted: UnrestrictedMacApp[];
  publicUnrestricted: PublicUnrestrictedMacApp[];
}

interface EditableForm<Draft> {
  saved: Draft;
  draft: Draft;
}

export type MonitoringFormState = EditableForm<MonitoringDraft>;
export type InternetFilteringFormState = EditableForm<InternetFilteringDraft>;
export type AppsFormState = EditableForm<AppsDraft>;

export interface MacSettingsFormState {
  monitoring: MonitoringFormState;
  internetFiltering: InternetFilteringFormState;
  apps: AppsFormState;
}

export const defaultDowntime: DowntimeWindow = {
  start: { hour: 21, minute: 0 },
  end: { hour: 5, minute: 0 },
};

export type MacSettingsAction =
  | { type: `settingsReceived`; settings: MacSettingsConfiguration }
  | { type: `monitoringKeyloggingChanged`; enabled: boolean }
  | { type: `monitoringScreenshotsChanged`; enabled: boolean }
  | { type: `monitoringSuspensionActivityChanged`; enabled: boolean }
  | { type: `monitoringFrequencyChanged`; value: string }
  | { type: `monitoringResolutionChanged`; value: string }
  | { type: `monitoringSaveStarted`; submitted: MonitoringDraft }
  | { type: `monitoringSaveSucceeded`; submitted: MonitoringDraft }
  | { type: `filteringEnabledChanged`; enabled: boolean }
  | { type: `downtimeEnabledChanged`; enabled: boolean }
  | { type: `downtimeChanged`; downtime: DowntimeWindow }
  | { type: `keychainsAdded`; keychains: MacKeychain[] }
  | { type: `keychainRemoved`; id: string }
  | { type: `keychainScheduleChanged`; id: string; schedule?: Schedule }
  | { type: `alwaysBlockedGroupChanged`; id: string; blocked: boolean }
  | { type: `customAlwaysBlockedRulesChanged`; rules: CustomAlwaysBlockedRule[] }
  | { type: `internetFilteringSaveSucceeded`; submitted: InternetFilteringDraft }
  | { type: `blockedAppsAdded`; apps: BlockedMacApp[] }
  | { type: `blockedAppRemoved`; id: string }
  | { type: `blockedAppScheduleChanged`; id: string; schedule?: Schedule }
  | { type: `unrestrictedAppsAdded`; apps: UnrestrictedMacApp[] }
  | { type: `unrestrictedAppRemoved`; id: string }
  | { type: `unrestrictedAppScheduleChanged`; id: string; schedule?: Schedule }
  | { type: `appsSaveSucceeded`; submitted: AppsDraft };

export interface MonitoringValidation {
  frequency?: number;
  resolution?: number;
  frequencyError?: string;
  resolutionError?: string;
}

export interface MonitoringSubmission {
  draft: MonitoringDraft;
  configuration: MacMonitoringConfiguration;
}

const integerAtLeast = (value: string, minimum: number): number | undefined => {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= minimum ? parsed : undefined;
};

const monitoringDraft = (settings: MacSettingsConfiguration): MonitoringDraft => ({
  keyloggingEnabled: settings.keyloggingEnabled,
  screenshotsEnabled: settings.screenshots.enabled,
  showSuspensionActivity: settings.showSuspensionActivity,
  frequencyDraft: String(settings.screenshots.frequency),
  resolutionDraft: String(settings.screenshots.resolution),
});

const internetFilteringDraft = (
  settings: MacSettingsConfiguration,
): InternetFilteringDraft => ({
  filteringEnabled: settings.internetFiltering.enabled,
  downtime: settings.internetFiltering.downtime,
  keychains: settings.internetFiltering.keychains,
  alwaysBlockedGroupIds: settings.internetFiltering.alwaysBlockedGroupIds,
  customAlwaysBlockedRules: settings.internetFiltering.customAlwaysBlockedRules,
});

const appsDraft = (settings: MacSettingsConfiguration): AppsDraft => ({
  blocked: settings.apps.blocked,
  unrestricted: settings.apps.unrestricted,
  publicUnrestricted: settings.apps.publicUnrestricted,
});

const editableForm = <Draft>(draft: Draft): EditableForm<Draft> => ({
  saved: draft,
  draft,
});

export const createMacSettingsFormState = (
  settings: MacSettingsConfiguration,
): MacSettingsFormState => ({
  monitoring: editableForm(monitoringDraft(settings)),
  internetFiltering: editableForm(internetFilteringDraft(settings)),
  apps: editableForm(appsDraft(settings)),
});

export const monitoringHasUnsavedChanges = ({
  saved,
  draft,
}: MonitoringFormState): boolean =>
  draft.keyloggingEnabled !== saved.keyloggingEnabled ||
  draft.screenshotsEnabled !== saved.screenshotsEnabled ||
  draft.showSuspensionActivity !== saved.showSuspensionActivity ||
  draft.frequencyDraft !== saved.frequencyDraft ||
  draft.resolutionDraft !== saved.resolutionDraft;

export const internetFilteringConfiguration = ({
  filteringEnabled,
  downtime,
  keychains,
  alwaysBlockedGroupIds,
  customAlwaysBlockedRules,
}: InternetFilteringDraft): InternetFilteringConfiguration => ({
  filteringEnabled,
  downtime,
  keychains: keychains.map(({ id, schedule }) => ({ id, schedule })),
  alwaysBlockedGroupIds,
  customAlwaysBlockedRules,
});

export const internetFilteringHasUnsavedChanges = ({
  saved,
  draft,
}: InternetFilteringFormState): boolean =>
  JSON.stringify(internetFilteringConfiguration(draft)) !==
  JSON.stringify(internetFilteringConfiguration(saved));

export const appsConfiguration = ({
  blocked,
  unrestricted,
}: AppsDraft): MacAppsConfiguration => ({
  blockedApps: blocked.map(({ id, identifier, schedule }) => ({
    id,
    identifier,
    schedule,
  })),
  unrestrictedApps: unrestricted.map(({ id, scope, schedule }) => ({
    id,
    scope,
    schedule,
  })),
});

export const appsHaveUnsavedChanges = ({ saved, draft }: AppsFormState): boolean =>
  JSON.stringify(appsConfiguration(draft)) !== JSON.stringify(appsConfiguration(saved));

export const monitoringValidation = ({
  frequencyDraft,
  resolutionDraft,
}: MonitoringDraft): MonitoringValidation => {
  const frequency = integerAtLeast(frequencyDraft, 10);
  const resolution = integerAtLeast(resolutionDraft, 1);

  return {
    frequency,
    resolution,
    frequencyError:
      frequencyDraft.trim() === ``
        ? `Frequency is required.`
        : frequency === undefined
          ? `Enter a whole number of at least 10 seconds.`
          : undefined,
    resolutionError:
      resolutionDraft.trim() === ``
        ? `Resolution is required.`
        : resolution === undefined
          ? `Enter a positive whole number.`
          : undefined,
  };
};

export const monitoringConfiguration = (
  draft: MonitoringDraft,
): MacMonitoringConfiguration | undefined => {
  const { frequency, resolution } = monitoringValidation(draft);
  if (frequency === undefined || resolution === undefined) {
    return undefined;
  }

  return {
    keyloggingEnabled: draft.keyloggingEnabled,
    showSuspensionActivity: draft.showSuspensionActivity,
    screenshots: {
      enabled: draft.screenshotsEnabled,
      resolution,
      frequency,
    },
  };
};

export const monitoringSubmission = (
  draft: MonitoringDraft,
): MonitoringSubmission | undefined => {
  const configuration = monitoringConfiguration(draft);
  if (!configuration) {
    return undefined;
  }

  return {
    draft: {
      ...draft,
      frequencyDraft: String(configuration.screenshots.frequency),
      resolutionDraft: String(configuration.screenshots.resolution),
    },
    configuration,
  };
};

const updateMonitoring = (
  state: MacSettingsFormState,
  draft: MonitoringDraft,
): MacSettingsFormState => ({
  ...state,
  monitoring: { ...state.monitoring, draft },
});

const updateInternetFiltering = (
  state: MacSettingsFormState,
  draft: InternetFilteringDraft,
): MacSettingsFormState => ({
  ...state,
  internetFiltering: { ...state.internetFiltering, draft },
});

const updateApps = (
  state: MacSettingsFormState,
  draft: AppsDraft,
): MacSettingsFormState => ({
  ...state,
  apps: { ...state.apps, draft },
});

const macSettingsReducer = (
  state: MacSettingsFormState,
  action: MacSettingsAction,
): MacSettingsFormState => {
  switch (action.type) {
    case `settingsReceived`: {
      const received = createMacSettingsFormState(action.settings);
      return {
        monitoring: monitoringHasUnsavedChanges(state.monitoring)
          ? state.monitoring
          : received.monitoring,
        internetFiltering: internetFilteringHasUnsavedChanges(state.internetFiltering)
          ? state.internetFiltering
          : received.internetFiltering,
        apps: appsHaveUnsavedChanges(state.apps)
          ? {
              saved: {
                ...state.apps.saved,
                publicUnrestricted: received.apps.saved.publicUnrestricted,
              },
              draft: {
                ...state.apps.draft,
                publicUnrestricted: received.apps.draft.publicUnrestricted,
              },
            }
          : received.apps,
      };
    }
    case `monitoringKeyloggingChanged`:
      return updateMonitoring(state, {
        ...state.monitoring.draft,
        keyloggingEnabled: action.enabled,
      });
    case `monitoringScreenshotsChanged`:
      return updateMonitoring(state, {
        ...state.monitoring.draft,
        screenshotsEnabled: action.enabled,
        frequencyDraft: action.enabled
          ? state.monitoring.draft.frequencyDraft
          : state.monitoring.saved.frequencyDraft,
        resolutionDraft: action.enabled
          ? state.monitoring.draft.resolutionDraft
          : state.monitoring.saved.resolutionDraft,
      });
    case `monitoringSuspensionActivityChanged`:
      return updateMonitoring(state, {
        ...state.monitoring.draft,
        showSuspensionActivity: action.enabled,
      });
    case `monitoringFrequencyChanged`:
      return updateMonitoring(state, {
        ...state.monitoring.draft,
        frequencyDraft: action.value,
      });
    case `monitoringResolutionChanged`:
      return updateMonitoring(state, {
        ...state.monitoring.draft,
        resolutionDraft: action.value,
      });
    case `monitoringSaveStarted`:
      return updateMonitoring(state, action.submitted);
    case `monitoringSaveSucceeded`:
      return {
        ...state,
        monitoring: {
          saved: action.submitted,
          draft: state.monitoring.draft,
        },
      };
    case `filteringEnabledChanged`:
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        filteringEnabled: action.enabled,
      });
    case `downtimeEnabledChanged`:
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        downtime: action.enabled
          ? (state.internetFiltering.draft.downtime ?? defaultDowntime)
          : undefined,
      });
    case `downtimeChanged`:
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        downtime: action.downtime,
      });
    case `keychainsAdded`: {
      const assignedIds = new Set(
        state.internetFiltering.draft.keychains.map(({ id }) => id),
      );
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        keychains: [
          ...state.internetFiltering.draft.keychains,
          ...action.keychains.filter(({ id }) => !assignedIds.has(id)),
        ],
      });
    }
    case `keychainRemoved`:
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        keychains: state.internetFiltering.draft.keychains.filter(
          ({ id }) => id !== action.id,
        ),
      });
    case `keychainScheduleChanged`:
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        keychains: state.internetFiltering.draft.keychains.map((keychain) =>
          keychain.id === action.id
            ? { ...keychain, schedule: action.schedule }
            : keychain,
        ),
      });
    case `alwaysBlockedGroupChanged`: {
      const current = state.internetFiltering.draft.alwaysBlockedGroupIds;
      const alwaysBlockedGroupIds = action.blocked
        ? current.includes(action.id)
          ? current
          : [...current, action.id]
        : current.filter((id) => id !== action.id);
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        alwaysBlockedGroupIds,
      });
    }
    case `customAlwaysBlockedRulesChanged`:
      return updateInternetFiltering(state, {
        ...state.internetFiltering.draft,
        customAlwaysBlockedRules: action.rules,
      });
    case `internetFilteringSaveSucceeded`:
      return {
        ...state,
        internetFiltering: {
          saved: action.submitted,
          draft: state.internetFiltering.draft,
        },
      };
    case `blockedAppsAdded`: {
      const existingIdentifiers = new Set(
        state.apps.draft.blocked.map(({ identifier }) => identifier),
      );
      return updateApps(state, {
        ...state.apps.draft,
        blocked: [
          ...state.apps.draft.blocked,
          ...action.apps.filter(({ identifier }) => !existingIdentifiers.has(identifier)),
        ],
      });
    }
    case `blockedAppRemoved`:
      return updateApps(state, {
        ...state.apps.draft,
        blocked: state.apps.draft.blocked.filter(({ id }) => id !== action.id),
      });
    case `blockedAppScheduleChanged`:
      return updateApps(state, {
        ...state.apps.draft,
        blocked: state.apps.draft.blocked.map((app) =>
          app.id === action.id ? { ...app, schedule: action.schedule } : app,
        ),
      });
    case `unrestrictedAppsAdded`: {
      const existingScopes = new Set(
        state.apps.draft.unrestricted.map((app) => JSON.stringify(app.scope)),
      );
      const unrestricted = [...state.apps.draft.unrestricted];
      for (const app of action.apps) {
        const scope = JSON.stringify(app.scope);
        if (!existingScopes.has(scope)) {
          existingScopes.add(scope);
          unrestricted.push(app);
        }
      }
      return updateApps(state, { ...state.apps.draft, unrestricted });
    }
    case `unrestrictedAppRemoved`:
      return updateApps(state, {
        ...state.apps.draft,
        unrestricted: state.apps.draft.unrestricted.filter(({ id }) => id !== action.id),
      });
    case `unrestrictedAppScheduleChanged`:
      return updateApps(state, {
        ...state.apps.draft,
        unrestricted: state.apps.draft.unrestricted.map((app) =>
          app.id === action.id ? { ...app, schedule: action.schedule } : app,
        ),
      });
    case `appsSaveSucceeded`:
      return {
        ...state,
        apps: {
          saved: {
            ...action.submitted,
            publicUnrestricted: state.apps.saved.publicUnrestricted,
          },
          draft: state.apps.draft,
        },
      };
  }
};

export default macSettingsReducer;
