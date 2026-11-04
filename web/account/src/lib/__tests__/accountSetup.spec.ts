import { describe, expect, test } from 'vitest';
import type { GetAccountSetup } from '@shared/pairql/src/account';
import { needsOnboarding, setupChecklist } from '../accountSetup';
import { getAppSetupSteps } from '#/components/onboarding/setupApps';

const setup = (
  overrides: Partial<GetAccountSetup.Output> = {},
): GetAccountSetup.Output => ({
  hasPeople: true,
  completedApps: [],
  hasNotifications: false,
  ...overrides,
});

describe(`Account setup`, () => {
  test(`only sends parents who never chose apps and have no people to onboarding`, () => {
    expect(needsOnboarding(setup({ hasPeople: false }))).toBe(true);
    expect(needsOnboarding(setup())).toBe(false);
    expect(needsOnboarding(setup({ selectedApps: [], hasPeople: false }))).toBe(false);
  });

  test(`hides the checklist until apps are chosen and a person exists`, () => {
    expect(setupChecklist(setup({ completedApps: [`mac`] }))).toBeNull();
    expect(setupChecklist(setup({ selectedApps: [`mac`], hasPeople: false }))).toBeNull();
  });

  test(`marks the person step and connected apps as complete`, () => {
    expect(
      setupChecklist(setup({ selectedApps: [`music`], completedApps: [`blocker`] })),
    ).toEqual({
      selectedApps: [`music`],
      completedSteps: [`person`, `blocker`],
      includeNotifications: false,
    });
  });

  test(`hides the checklist once every chosen app is connected`, () => {
    expect(
      setupChecklist(setup({ selectedApps: [`music`], completedApps: [`music`] })),
    ).toBeNull();
  });

  test(`keeps the choose-apps step open for parents who decided later`, () => {
    expect(setupChecklist(setup({ selectedApps: [] }))).toEqual({
      selectedApps: [],
      completedSteps: [`person`],
      includeNotifications: false,
    });
  });

  test(`asks Mac families to set up notifications right after the Mac step`, () => {
    expect(getAppSetupSteps([`mac`, `music`]).map((step) => step.id)).toEqual([
      `mac`,
      `notifications`,
      `music`,
    ]);
    expect(getAppSetupSteps([`music`]).map((step) => step.id)).toEqual([`music`]);
  });

  test(`keeps setup open until a Mac family creates a notification`, () => {
    const macConnected = setup({ selectedApps: [`mac`], completedApps: [`mac`] });
    expect(setupChecklist(macConnected)?.includeNotifications).toBe(true);
    expect(setupChecklist({ ...macConnected, hasNotifications: true })).toBeNull();
  });

  test(`asks for notifications when a Mac connects even if it wasn't chosen`, () => {
    expect(
      setupChecklist(setup({ selectedApps: [`music`], completedApps: [`music`, `mac`] })),
    ).toEqual({
      selectedApps: [`music`],
      completedSteps: [`person`, `music`, `mac`],
      includeNotifications: true,
    });
  });
});
