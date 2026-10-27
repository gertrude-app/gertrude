import { describe, expect, test } from 'vitest';
import type { GetPeople } from '@shared/pairql/src/account';
import { toPersonCardPerson } from '../people';

describe(`person device connections`, () => {
  test(`keeps individual Mac login ids and usernames distinct on the same Mac`, () => {
    const mac = {
      case: `mac` as const,
      name: `Family Mac`,
      modelName: `MacBook Air`,
      modelIdentifier: `Mac14,2`,
      online: true,
    };
    const person: GetPeople.Output[number] = {
      id: `person-1`,
      name: `Jude`,
      relationship: `child`,
      devices: [
        { ...mac, id: `connection-1`, username: `jude` },
        { ...mac, id: `connection-2`, username: `jude-school` },
      ],
    };

    expect(toPersonCardPerson(person).devices).toMatchObject([
      { id: `connection-1`, personId: `person-1`, type: `mac`, username: `jude` },
      { id: `connection-2`, personId: `person-1`, type: `mac`, username: `jude-school` },
    ]);
  });
});
