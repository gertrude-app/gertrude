import { describe, expect, test } from 'vitest';
import type { ChildComputerStatus } from '@dash/types';
import { consolidatedComputerStatus } from '../computerStatus';

const statuses: ChildComputerStatus[] = [
  { case: `offline` },
  { case: `filterOn` },
  { case: `downtime`, ending: `2026-08-19T12:00:00Z` },
  { case: `downtimePaused`, resuming: `2026-08-19T13:00:00Z` },
  { case: `filterSuspended`, resuming: `2026-08-19T14:00:00Z` },
  { case: `unfiltered` },
  { case: `filterOff` },
];

describe(`consolidatedComputerStatus()`, () => {
  test(`selects the highest-priority status regardless of input order`, () => {
    expect(consolidatedComputerStatus(statuses)).toEqual({ case: `filterOff` });
    expect(consolidatedComputerStatus([...statuses].reverse())).toEqual({
      case: `filterOff`,
    });
  });

  test(`selects the latest known time for matching timed statuses`, () => {
    const earlier: ChildComputerStatus = {
      case: `filterSuspended`,
      resuming: `2026-08-19T12:00:00Z`,
    };
    const later: ChildComputerStatus = {
      case: `filterSuspended`,
      resuming: `2026-08-19T14:00:00Z`,
    };

    expect(consolidatedComputerStatus([earlier, later])).toEqual(later);
    expect(consolidatedComputerStatus([later, earlier])).toEqual(later);
  });

  test(`returns offline when there are no statuses`, () => {
    expect(consolidatedComputerStatus([])).toEqual({ case: `offline` });
  });
});
