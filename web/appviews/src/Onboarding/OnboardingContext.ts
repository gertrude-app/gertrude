import { createContext } from 'react';
import type { AppEvent, OnboardingStep, OSGroup, ViewAction } from './onboarding-store';

const OnboardingContext = createContext<{
  currentStep: OnboardingStep;
  os: OSGroup;
  systemSettingsName: string;
  emit(event: AppEvent): unknown;
  dispatch(event: ViewAction): unknown;
}>({
  currentStep: `welcome`,
  os: `venturaOrLater`,
  systemSettingsName: `System Settings`,
  emit() {},
  dispatch() {},
});

export default OnboardingContext;
