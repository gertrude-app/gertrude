import type { SetupApp, SetupStepId } from '#/components/onboarding/setupApps';
import type { GetAccountSetup } from '@shared/pairql/src/account';
import { getAppSetupSteps } from '#/components/onboarding/setupApps';

export function needsOnboarding(setup: GetAccountSetup.Output): boolean {
  return setup.selectedApps == null && !setup.hasPeople;
}

export function setupChecklist(setup: GetAccountSetup.Output): {
  selectedApps: SetupApp[];
  completedSteps: SetupStepId[];
  includeNotifications: boolean;
} | null {
  const { selectedApps } = setup;
  if (selectedApps == null || !setup.hasPeople) return null;
  const includeNotifications =
    selectedApps.includes(`mac`) || setup.completedApps.includes(`mac`);
  const completedSteps: SetupStepId[] = [
    `person`,
    ...setup.completedApps,
    ...(setup.hasNotifications ? [`notifications` as const] : []),
  ];
  const complete = getAppSetupSteps(selectedApps, includeNotifications).every((step) =>
    completedSteps.includes(step.id),
  );
  return complete ? null : { selectedApps, completedSteps, includeNotifications };
}
