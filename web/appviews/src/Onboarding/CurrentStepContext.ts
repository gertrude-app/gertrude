import { createContext } from 'react';
import { OnboardingStep } from './onboarding-store';

const CurrentStepContext = createContext<OnboardingStep>('welcome');
export default CurrentStepContext;
