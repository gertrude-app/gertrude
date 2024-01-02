import { env } from '@shared/components';
import { time } from '@shared/datetime';
import type { ActivityFeedItem } from '@dash/components';
import type { ConfirmableEntityAction, KeychainSummary, Key } from '@dash/types';
import Placeholder400x600 from './static/placeholder/400x600.png';
import Placeholder300x200 from './static/placeholder/300x200.png';
import Placeholder400x200 from './static/placeholder/400x200.png';
import Placeholder500x300 from './static/placeholder/500x300.png';
import Placeholder700x200 from './static/placeholder/700x200.png';
import Placeholder800x600 from './static/placeholder/800x600.png';
import Placeholder800x900 from './static/placeholder/800x900.png';
import Placeholder1200x400 from './static/placeholder/1200x400.png';

export { time };

export function keychainProps(override: Partial<KeychainSummary> = {}): KeychainSummary {
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

const PLACEHOLDERS: Record<string, string> = {
  '400x600': Placeholder400x600,
  '300x200': Placeholder300x200,
  '400x200': Placeholder400x200,
  '500x300': Placeholder500x300,
  '700x200': Placeholder700x200,
  '800x600': Placeholder800x600,
  '800x900': Placeholder800x900,
  '1200x400': Placeholder1200x400,
};

export function testImgUrl(width: number, height: number): string {
  if (!env.isScreenshotTest()) {
    return `https://placekitten.com/${width}/${height}`;
  }

  const key = `${width}x${height}`;
  const placeholder = PLACEHOLDERS[key];
  if (!placeholder) {
    throw new Error(
      `No deterministic placeholder image for size \`${key}\`. Use an existing supported size, or add a new one.`,
    );
  }
  return placeholder;
}

export function withIds<T>(items: T[]): Array<T & { id: UUID }> {
  return items.map((item, index) => ({ ...item, id: `${index + 1}` }));
}

export function withIdsAnd<T, K>(add: K, items: T[]): Array<T & K & { id: UUID }> {
  return adding(add, withIds(items));
}

export function adding<T, K>(add: K, items: T[]): Array<T & K> {
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

export function props<T>(args: T): { args: T } {
  return { args };
}

export const keyExamples = {
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
} satisfies Record<string, Key>;

export const keychains = [
  keychainProps({ name: `HTC`, numKeys: 232, isPublic: true }),
  keychainProps({ name: `Jimmy's Music Theory`, numKeys: 7 }),
  keychainProps({ name: `Jason's blog`, numKeys: 3, description: undefined }),
  keychainProps({ name: `Misc McStrandardishlong Keys`, numKeys: 1027 }),
  keychainProps({ name: `Smith family`, numKeys: 9, description: `A short description` }),
  keychainProps({ name: `Meyer Hatchery`, numKeys: 14, isPublic: true }),
  keychainProps({
    name: `Friends Library Internationalization Remote Safety Keychain for MSF`,
    numKeys: 2,
    description: `Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.`,
  }),
];

export const activity = [
  {
    userName: `Little Jimmy`,
    highlightSuspensionActivity: false,
    items: [
      keystrokeLine(
        `Xcode`,
        `importFoundationhereisareallylonglinethatwillcauseproblemspotentiallyblahblahblahlorem`,
      ),
      screenshot(400, 600, true, true), // during suspension, but not highlighted because of user setting
      keystrokeLine(`Brave`, `Hello world`),
      keystrokeLine(`Xcode`, `import Foundation`),
      screenshot(),
    ],
  },
  {
    userName: `Henry`,
    highlightSuspensionActivity: true,
    items: [
      keystrokeLine(`Firefox`, `turtles`),
      screenshot(400, 600, true, true),
      keystrokeLine(`Brave`, `Hello world`, true),
      keystrokeLine(`Xcode`, `import Foundation`, true),
      screenshot(),
      screenshot(),
      keystrokeLine(`Messages`, `Sounds good, thanks`, true),
      screenshot(),
    ],
  },
  {
    userName: `Sally`,
    highlightSuspensionActivity: true,
    items: [
      keystrokeLine(`Skype`, `No puedo nadar.`, true),
      screenshot(800, 600, true, true),
      keystrokeLine(`Brave`, `Hello world`, true),
    ],
  },
];

export function common(): { id: string; ids: string[]; date: string } {
  const current = `item-${Math.random()}`;
  return {
    id: `${current}`,
    ids: [`${current}`],
    date: time.stable(),
  };
}

export function keystrokeLine(
  appName: string,
  line: string,
  deleted?: boolean,
  duringSuspension?: boolean,
): ActivityFeedItem {
  return {
    ...common(),
    type: `KeystrokeLine`,
    appName,
    line,
    deleted,
    duringSuspension: duringSuspension || false,
  };
}

export function screenshot(
  width = 800,
  height = 600,
  deleted?: boolean,
  duringSuspension?: boolean,
): ActivityFeedItem {
  return {
    ...common(),
    type: `Screenshot`,
    url: testImgUrl(width, height),
    width,
    height,
    deleted,
    duringSuspension: duringSuspension || false,
  };
}

export function appWindow(width = 900, height = 600): Record<string, any> {
  return {
    layout: `fullscreen`,
    viewport: {
      viewports: {
        appWindow: {
          name: `AppWindow`,
          styles: {
            width: `${width}px`,
            height: `${height}px`,
          },
        },
      },
      defaultViewport: `appWindow`,
    },
  };
}

export function fixedViewport(width: number, height: number): Record<string, any> {
  return {
    layout: `fullscreen`,
    viewport: {
      viewports: {
        fixed: {
          name: `Fixed`,
          styles: {
            width: `${width}px`,
            height: `${height}px`,
          },
        },
      },
      defaultViewport: `fixed`,
    },
  };
}
