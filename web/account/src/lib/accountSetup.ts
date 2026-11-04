import type { SetupApp, SetupStepId } from '#/components/onboarding/setupApps';
import type { GetAccountSetup } from '@shared/pairql/src/account';
import { getAppSetupSteps } from '#/components/onboarding/setupApps';

export function needsOnboarding(setup: GetAccountSetup.Output): boolean {
  return setup.selectedApps == null && !setup.hasPeople;
}

export function setupChecklist(
  setup: GetAccountSetup.Output,
): { selectedApps: SetupApp[]; completedSteps: SetupStepId[] } | null {
  const { selectedApps } = setup;
  if (selectedApps == null || !setup.hasPeople) return null;
  const completedSteps: SetupStepId[] = [`person`, ...setup.completedApps];
  const complete = getAppSetupSteps(selectedApps).every((step) =>
    completedSteps.includes(step.id),
  );
  return complete ? null : { selectedApps, completedSteps };
}
