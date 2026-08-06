import type { CustomAlwaysBlockedRule, Schedule } from '#/components/types';
import type {
  InternetFilteringConfiguration,
  MacKeychain,
  MacMonitoringConfiguration,
  MacSettingsConfiguration,
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
  keychains: MacKeychain[];
  alwaysBlockedGroupIds: string[];
  customAlwaysBlockedRules: CustomAlwaysBlockedRule[];
}

interface EditableForm<Draft> {
  saved: Draft;
  draft: Draft;
}

export type MonitoringFormState = EditableForm<MonitoringDraft>;
export type InternetFilteringFormState = EditableForm<InternetFilteringDraft>;

export interface MacSettingsFormState {
  monitoring: MonitoringFormState;
  internetFiltering: InternetFilteringFormState;
}

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
  | { type: `keychainsAdded`; keychains: MacKeychain[] }
  | { type: `keychainRemoved`; id: string }
  | { type: `keychainScheduleChanged`; id: string; schedule?: Schedule }
  | { type: `alwaysBlockedGroupChanged`; id: string; blocked: boolean }
  | { type: `customAlwaysBlockedRulesChanged`; rules: CustomAlwaysBlockedRule[] }
  | { type: `internetFilteringSaveSucceeded`; submitted: InternetFilteringDraft };

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
  keychains: settings.internetFiltering.keychains,
  alwaysBlockedGroupIds: settings.internetFiltering.alwaysBlockedGroupIds,
  customAlwaysBlockedRules: settings.internetFiltering.customAlwaysBlockedRules,
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
  keychains,
  alwaysBlockedGroupIds,
  customAlwaysBlockedRules,
}: InternetFilteringDraft): InternetFilteringConfiguration => ({
  filteringEnabled,
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
  }
};

export default macSettingsReducer;
