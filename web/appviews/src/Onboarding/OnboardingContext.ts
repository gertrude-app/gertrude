import { createContext } from 'react';
import type {
  AppEvent,
  MacOSUser,
  MacOSVersion,
  OnboardingStep,
  ViewAction,
} from './onboarding-store';

const OnboardingContext = createContext<{
  otherUsers: MacOSUser[];
  currentStep: OnboardingStep;
  osVersion: MacOSVersion;
  systemSettingsName: string;
  isUpgrade: boolean;
  emit(event: AppEvent): unknown;
  dispatch(event: ViewAction): unknown;
}>({
  otherUsers: [],
  currentStep: `welcome`,
  osVersion: { name: `sequoia`, major: 15 },
  systemSettingsName: `System Settings`,
  isUpgrade: false,
  emit() {},
  dispatch() {},
});

export default OnboardingContext;

export const WithinActiveStepContext = createContext(false);
