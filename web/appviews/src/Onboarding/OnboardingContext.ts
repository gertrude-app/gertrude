import { createContext } from 'react';
import type {
  AppEvent,
  MacOSUser,
  OnboardingStep,
  OSGroup,
  ViewAction,
} from './onboarding-store';

const OnboardingContext = createContext<{
  otherUsers: MacOSUser[];
  currentStep: OnboardingStep;
  os: OSGroup;
  systemSettingsName: string;
  emit(event: AppEvent): unknown;
  dispatch(event: ViewAction): unknown;
}>({
  otherUsers: [],
  currentStep: `welcome`,
  os: `venturaOrLater`,
  systemSettingsName: `System Settings`,
  emit() {},
  dispatch() {},
});

export default OnboardingContext;

export const WithinActiveStepContext = createContext(false);
