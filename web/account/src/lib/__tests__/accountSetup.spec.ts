import { describe, expect, test } from 'vitest';
import { needsOnboarding, setupChecklist } from '../accountSetup';

describe(`Account setup`, () => {
  test(`only sends parents who never chose apps and have no people to onboarding`, () => {
    expect(needsOnboarding({ hasPeople: false, completedApps: [] })).toBe(true);
    expect(needsOnboarding({ hasPeople: true, completedApps: [] })).toBe(false);
    expect(
      needsOnboarding({ selectedApps: [], hasPeople: false, completedApps: [] }),
    ).toBe(false);
  });

  test(`hides the checklist until apps are chosen and a person exists`, () => {
    expect(setupChecklist({ hasPeople: true, completedApps: [`mac`] })).toBeNull();
    expect(
      setupChecklist({ selectedApps: [`mac`], hasPeople: false, completedApps: [] }),
    ).toBeNull();
  });

  test(`marks the person step and connected apps as complete`, () => {
    expect(
      setupChecklist({
        selectedApps: [`mac`, `music`],
        hasPeople: true,
        completedApps: [`mac`, `blocker`],
      }),
    ).toEqual({
      selectedApps: [`mac`, `music`],
      completedSteps: [`person`, `mac`, `blocker`],
    });
  });

  test(`hides the checklist once every chosen app is connected`, () => {
    expect(
      setupChecklist({
        selectedApps: [`mac`, `music`],
        hasPeople: true,
        completedApps: [`music`, `mac`, `blocker`],
      }),
    ).toBeNull();
  });

  test(`keeps the choose-apps step open for parents who decided later`, () => {
    expect(
      setupChecklist({ selectedApps: [], hasPeople: true, completedApps: [`mac`] }),
    ).toEqual({ selectedApps: [], completedSteps: [`person`, `mac`] });
  });
});
