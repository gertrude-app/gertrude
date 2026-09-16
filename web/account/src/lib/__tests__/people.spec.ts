import { describe, expect, test } from 'vitest';
import type { GetPeople } from '@shared/pairql/src/account';
import { toIosSettingsDevices } from '../people';

type Person = GetPeople.Output[number];

const person: Person = {
  id: `person-1`,
  name: `Sam`,
  relationship: `child`,
  devices: [],
};

const iphone: Extract<Person[`devices`][number], { case: `ios` }> = {
  case: `ios`,
  id: `iphone-1`,
  type: `iphone`,
  iOSVersion: `26.6`,
  modelName: `iPhone 15`,
  modelIdentifier: `iPhone15,4`,
  blockerConnected: false,
};

const mac: Extract<Person[`devices`][number], { case: `mac` }> = {
  case: `mac`,
  id: `mac-1`,
  modelName: `MacBook Air`,
  modelIdentifier: `MacBookAir10,1`,
  online: false,
};

describe(`iOS settings devices`, () => {
  test.each([false, true])(
    `includes a linked iPhone with blockerConnected=%s`,
    (blockerConnected) => {
      expect(
        toIosSettingsDevices({
          ...person,
          devices: [mac, { ...iphone, blockerConnected }],
        }),
      ).toEqual([
        {
          id: iphone.id,
          personId: person.id,
          type: `iphone`,
          iOSVersion: iphone.iOSVersion,
          modelName: iphone.modelName,
          modelIdentifier: iphone.modelIdentifier,
        },
      ]);
    },
  );

  test(`keeps both non-Blocker devices available to the device picker`, () => {
    const devices = toIosSettingsDevices({
      ...person,
      devices: [
        iphone,
        mac,
        {
          ...iphone,
          id: `ipad-1`,
          type: `ipad`,
          modelName: `iPad`,
          modelIdentifier: `iPad13,18`,
        },
      ],
    });

    expect(devices.map((device) => device.id)).toEqual([`iphone-1`, `ipad-1`]);
    expect(devices.map((device) => device.type)).toEqual([`iphone`, `ipad`]);
  });

  test.each([{ devices: [] }, { devices: [mac] }])(
    `has no iOS settings devices without a linked iOS device ($devices)`,
    ({ devices }) => {
      expect(toIosSettingsDevices({ ...person, devices })).toEqual([]);
    },
  );
});
