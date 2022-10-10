import { ConfirmableEntityAction } from '../types';

export function keychainProps(override: Partial<Keychain> = {}): Keychain {
  return {
    id: `id-${Math.random()}`,
    isPublic: false,
    name: `HTC`,
    description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
    numKeys: 232,
    authorId: `authorId-${Math.random()}`,
    ...override,
  };
}

export function withIds<T extends Record<string, unknown>>(
  items: T[],
): Array<T & { id: UUID }> {
  return items.map((item, index) => ({ ...item, id: `${index + 1}` }));
}

export function withIdsAnd<
  T extends Record<string, unknown>,
  K extends Record<string, unknown>,
>(add: K, items: T[]): Array<T & K & { id: UUID }> {
  return adding(add, withIds(items));
}

export function adding<
  T extends Record<string, unknown>,
  K extends Record<string, unknown>,
>(add: K, items: T[]): Array<T & K> {
  return items.map((item) => ({ ...add, ...item }));
}

export function confirmableEntityAction<
  StartArg = UUID,
>(): ConfirmableEntityAction<StartArg> {
  return {
    start: () => {},
    confirm: () => {},
    cancel: () => {},
  };
}

export const time = {
  now,
  subtracting,
};

function subtracting(amounts: {
  days?: number;
  hours?: number;
  minutes?: number;
}): string {
  const date = new Date();
  if (amounts.days) {
    date.setDate(date.getDate() - amounts.days);
  }
  if (amounts.hours) {
    date.setHours(date.getHours() - amounts.hours);
  }
  if (amounts.minutes) {
    date.setMinutes(date.getMinutes() - amounts.minutes);
  }
  return date.toISOString();
}

function now(): string {
  return new Date().toISOString();
}

export const keyExamples: Record<string, KeyRecord> = {
  // this is a "website" key of the "standard" type, unlocking `*.super-safe.com` for all web browsers
  standardWeb: {
    id: `1`,
    keychainId: `1`,
    key: {
      type: `anySubdomain`, // this is the "standard" address type
      domain: `super-safe.com`,
      scope: {
        type: `webBrowsers`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
  // this is a "website" key of the "strict" type, unlocking `github.com` for web browsers
  strictWeb: {
    id: `1`,
    keychainId: `1`,
    key: {
      type: `domain`, // this is the "standard" address type
      domain: `github.com`,
      scope: {
        type: `webBrowsers`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
  // this is an "app" key, granting unrestricted access to the Slack app
  skeletonApp: {
    id: `2`,
    keychainId: `1`,
    key: {
      type: `skeleton`, // this means app gets unrestricted access
      scope: {
        type: `identifiedAppSlug`,
        // the key only holds a "slug", but we can look up a presentable app name
        identifiedAppSlug: `slack`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
  // this is a variation on the above, but with a bundle ID instead of a slug
  skeletonAppBundleId: {
    id: `3`,
    keychainId: `1`,
    key: {
      type: `skeleton`, // this means app gets unrestricted access
      scope: {
        type: `bundleId`,
        // these bundle ideas are more rare, but not unheard of, and they can be LONG
        bundleId: `WE234WODK.com.lol.reallylongsomtetimes.foobar`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
  // this is a "website" key of the "STRICT" type, unlocking JUST safe-api.google.com, no other subdomains
  strictWebSingleSubdomain: {
    id: `4`,
    keychainId: `1`,
    key: {
      type: `domain`, // this is the "strict" address type
      domain: `safe-api.google.com`,
      scope: {
        type: `webBrowsers`,
      },
    },
    comment: undefined, // as with all other key records, this is optional, most commonly undefined
  },
  // an "advanced" configuration, a website key affecting only a single app, not as important, cuz less common
  singleApp: {
    id: `6`,
    keychainId: `1`,
    key: {
      type: `domain`,
      domain: `rad-vim-themes.biz`,
      scope: {
        type: `single`,
        single: {
          type: `identifiedAppSlug`,
          identifiedAppSlug: `vscode`,
        },
      },
    },
    comment: undefined,
  },
  // unlocks domain for all applications
  unlockedForAllApps: {
    id: `6`,
    keychainId: `1`,
    key: {
      type: `domain`,
      domain: `rad-vim-themes.biz`,
      scope: {
        type: `unrestricted`,
      },
    },
    comment: undefined,
  },
};
