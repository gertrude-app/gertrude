import { describe, expect, test } from 'vitest';
import type { Child, SingleAppScope } from '@dash/types';
import reducer from '../user-reducer';
import * as mock from './mocks';

function withChild(child: Child = mock.child()): ReturnType<typeof reducer> {
  return reducer({}, { type: `setChild`, child });
}

const bundle = (bundleId: string): SingleAppScope => ({ type: `bundleId`, bundleId });
const slug = (identifiedAppSlug: string): SingleAppScope => ({
  type: `identifiedAppSlug`,
  identifiedAppSlug,
});

describe(`userReducer() blocked apps`, () => {
  test(`addBlockedApps appends one entry per identifier with unique ids`, () => {
    const next = reducer(withChild(), {
      type: `addBlockedApps`,
      identifiers: [`com.foo.bar`, `Slack`],
    });
    const apps = next.child?.draft.blockedApps ?? [];
    expect(apps.map((a) => a.identifier)).toEqual([`com.foo.bar`, `Slack`]);
    expect(new Set(apps.map((a) => a.id)).size).toBe(2); // ids are distinct
  });

  test(`addBlockedApps preserves already-present blocked apps`, () => {
    const child = mock.child({
      blockedApps: [{ id: `existing`, identifier: `Existing` }],
    });
    const next = reducer(withChild(child), {
      type: `addBlockedApps`,
      identifiers: [`New`],
    });
    expect(next.child?.draft.blockedApps?.map((a) => a.identifier)).toEqual([
      `Existing`,
      `New`,
    ]);
  });

  test(`removeBlockedApp drops only the matching id`, () => {
    const child = mock.child({
      blockedApps: [
        { id: `a`, identifier: `A` },
        { id: `b`, identifier: `B` },
      ],
    });
    const next = reducer(withChild(child), { type: `removeBlockedApp`, id: `a` });
    expect(next.child?.draft.blockedApps?.map((a) => a.id)).toEqual([`b`]);
  });

  test(`addNewBlockedApp appends the pending identifier and clears the field`, () => {
    let state = reducer(withChild(), {
      type: `updateNewBlockedAppIdentifier`,
      identifier: `com.pending.app`,
    });
    state = reducer(state, { type: `addNewBlockedApp` });
    expect(state.child?.draft.blockedApps?.map((a) => a.identifier)).toEqual([
      `com.pending.app`,
    ]);
    expect(state.newBlockedAppIdentifier).toBe(``); // input reset after add
  });

  test(`addNewBlockedApp is a no-op when no identifier is pending`, () => {
    const next = reducer(withChild(), { type: `addNewBlockedApp` });
    expect(next.child?.draft.blockedApps ?? []).toHaveLength(0);
  });

  test(`setBlockedAppSchedule sets the schedule on the matching app`, () => {
    const child = mock.child({ blockedApps: [{ id: `a`, identifier: `A` }] });
    const schedule = {
      mode: `active`,
      days: {
        sunday: true,
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: true,
      },
      window: { start: { hour: 8, minute: 0 }, end: { hour: 17, minute: 0 } },
    } as const;
    const next = reducer(withChild(child), {
      type: `setBlockedAppSchedule`,
      id: `a`,
      schedule,
    });
    expect(next.child?.draft.blockedApps?.[0]?.schedule).toEqual(schedule);
  });
});

describe(`userReducer() unrestricted apps`, () => {
  test(`addUnrestrictedApps appends one entry per scope with unique ids`, () => {
    const next = reducer(withChild(), {
      type: `addUnrestrictedApps`,
      scopes: [slug(`unity-hub`), bundle(`com.foo.bar`)],
    });
    const apps = next.child?.draft.unrestrictedApps ?? [];
    expect(apps.map((a) => a.scope)).toEqual([slug(`unity-hub`), bundle(`com.foo.bar`)]);
    expect(new Set(apps.map((a) => a.id)).size).toBe(2); // ids are distinct
  });

  test(`addUnrestrictedApps preserves already-present unrestricted apps`, () => {
    const child = mock.child({
      unrestrictedApps: [{ id: `existing`, scope: slug(`chrome`) }],
    });
    const next = reducer(withChild(child), {
      type: `addUnrestrictedApps`,
      scopes: [bundle(`com.new.app`)],
    });
    expect(next.child?.draft.unrestrictedApps?.map((a) => a.scope)).toEqual([
      slug(`chrome`),
      bundle(`com.new.app`),
    ]);
  });

  test(`removeUnrestrictedApp drops only the matching id`, () => {
    const child = mock.child({
      unrestrictedApps: [
        { id: `a`, scope: slug(`unity-hub`) },
        { id: `b`, scope: bundle(`com.foo.bar`) },
      ],
    });
    const next = reducer(withChild(child), { type: `removeUnrestrictedApp`, id: `b` });
    expect(next.child?.draft.unrestrictedApps?.map((a) => a.id)).toEqual([`a`]);
  });
});
