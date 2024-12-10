import type { PlainTimeWindow, RuleSchedule } from './pairql/shared';

export function timeWindow(): PlainTimeWindow {
  return {
    start: { hour: 21, minute: 0 },
    end: { hour: 5, minute: 0 },
  };
}

export function ruleSchedule(): RuleSchedule {
  return {
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
    window: {
      start: { hour: 7, minute: 0 },
      end: { hour: 17, minute: 0 },
    },
  };
}
