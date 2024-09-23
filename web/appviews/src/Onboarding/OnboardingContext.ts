import { createContext } from 'react';
import type {
  AppEvent,
  MacOSUser,
  OnboardingStep,
  MacOSVersion,
  ViewAction,
} from './onboarding-store';

const OnboardingContext = createContext<{
  otherUsers: MacOSUser[];
  currentStep: OnboardingStep;
  osVersion: MacOSVersion;
  systemSettingsName: string;
  emit(event: AppEvent): unknown;
  dispatch(event: ViewAction): unknown;
}>({
  otherUsers: [],
  currentStep: `welcome`,
  osVersion: { name: `sequoia`, major: 15 },
  systemSettingsName: `System Settings`,
  emit() {},
  dispatch() {},
});

export default OnboardingContext;

export const WithinActiveStepContext = createContext(false);
