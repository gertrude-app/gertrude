import { expect, test, describe } from 'vitest';
import * as key from '@dashboard/lib/keys';

describe(`key.category()`, () => {
  test(`returns the "category" (app|website) of a key`, () => {
    const cases: Array<[Key, 'app' | 'website']> = [
      [
        {
          type: `skeleton`,
          scope: { type: `identifiedAppSlug`, identifiedAppSlug: `foo` },
        },
        `app`,
      ],

      [
        {
          type: `domain`,
          domain: `goats.com`,
          scope: { type: `unrestricted` },
        },
        `website`,
      ],
    ];
    test.each(cases)(`key categorized correctly`, (input, expected) => {
      expect(key.category(input)).toBe(expected);
    });
  });
});

describe(`key.parse()`, () => {
  const cases: Array<[Record<string, unknown>, Key | boolean]> = [
    [{}, false],
    [
      {
        __typename: `IpAddressData`,
        type: `ipAddress`,
        ipAddress: `1.2.3.4`,
        scope: { type: `unrestricted` },
        extraField: true, // <-- extra props not allowed
      },
      false,
    ],
    [
      {
        __typename: `IpAddressData`,
        type: `ipAddress`,
        domain: `goats.com`, // <-- mismatched prop key',
        scope: { type: `unrestricted` },
      },
      false,
    ],
    [
      {
        __typename: `IpAddressData`,
        type: `ipAddress`,
        ipAddress: `1.2.3.4`,
        scope: { type: `unrestricted`, __typename: `UnrestrictedData` },
      },
      true,
    ],
    [
      {
        __typename: `SkeletonData`,
        scope: {
          __typename: `IdentifiedAppData`,
          type: `identifiedAppSlug`,
          identifiedAppSlug: `goats`,
        },
        type: `skeleton`,
      },
      true,
    ],
  ];

  test.each(cases)(`parse input %s`, (obj, isValid) => {
    if (isValid) {
      expect(key.parse(JSON.stringify(obj))).toEqual(obj);
    } else {
      expect(key.parse(JSON.stringify(obj))).toBeNull();
    }
  });
});
