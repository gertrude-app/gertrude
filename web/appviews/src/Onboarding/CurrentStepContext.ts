import { createContext } from 'react';
import type { OnboardingStep } from './onboarding-store';

const CurrentStepContext = createContext<OnboardingStep>(`welcome`);
export default CurrentStepContext;
