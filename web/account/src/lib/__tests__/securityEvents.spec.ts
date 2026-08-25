import { describe, expect, test } from 'vitest';
import type { GetSecurityEvents } from '@shared/pairql/src/account';
import {
  type SecurityEventFilters,
  filterSecurityEvents,
  toSecurityEvent,
} from '../securityEvents';

const macEvent: GetSecurityEvents.Output[number] = {
  case: `macApp`,
  id: `event-1`,
  personId: `person-1`,
  personName: `Jude`,
  deviceId: `device-1`,
  deviceName: `Jude's MacBook`,
  title: `App quit`,
  explanation: `The app was quit.`,
  severity: `high`,
  createdAt: `2026-07-03T14:05:00Z`,
};

const accountEvent: GetSecurityEvents.Output[number] = {
  case: `account`,
  id: `event-2`,
  title: `Successful login`,
  detail: `using magic link`,
  explanation: `A parent logged in.`,
  severity: `low`,
  ipAddress: `203.0.113.42`,
  createdAt: `2026-07-03T13:05:00Z`,
};

describe(`toSecurityEvent`, () => {
  test(`maps Mac app and Account events`, () => {
    expect(toSecurityEvent(macEvent)).toMatchObject({
      type: `mac-app`,
      personId: `person-1`,
      deviceId: `device-1`,
      severity: `high`,
    });
    expect(toSecurityEvent(accountEvent)).toMatchObject({
      type: `account`,
      detail: `using magic link`,
      ipAddress: `203.0.113.42`,
      severity: `low`,
    });
  });
});

describe(`filterSecurityEvents`, () => {
  const events = [toSecurityEvent(macEvent), toSecurityEvent(accountEvent)];

  test(`shows every event when no filters are active`, () => {
    const filters: SecurityEventFilters = { severities: [], sources: [] };
    expect(filterSecurityEvents(events, filters)).toEqual(events);
  });

  test(`combines exact severity and source filters`, () => {
    const filters: SecurityEventFilters = {
      severities: [`high`, `medium`],
      sources: [`mac-app`],
    };
    expect(filterSecurityEvents(events, filters).map((event) => event.id)).toEqual([
      `event-1`,
    ]);
  });
});
