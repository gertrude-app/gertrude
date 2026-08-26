import fs from 'fs';
import path from 'path';
import matter from 'gray-matter';
import { describe, expect, it, vi } from 'vitest';
import {
  type ArticleType,
  getArticlePaths,
  getBlogArticlePath,
  getGuideArticlePath,
  getHelpArticlePath,
  getLegalArticlePath,
  getProgramArticlePath,
  getUpdateArticlePath,
  validatePublishingMetadata,
} from '../files';

vi.mock(`../config`, () => ({ config: {} }));

const ARTICLE_TYPES: ArticleType[] = [
  `blog`,
  `program`,
  `help`,
  `guide`,
  `update`,
  `legal`,
];

describe(`article assets`, () => {
  it(`references local images that exist`, async () => {
    const articlePaths = (
      await Promise.all(ARTICLE_TYPES.map((type) => getArticlePaths(type)))
    ).flat();
    const missingAssets: string[] = [];

    for (const articlePath of articlePaths) {
      const rawText = fs.readFileSync(articlePath, `utf8`);
      const metadata = matter(rawText).data as Record<string, unknown>;
      const imageSources = Array.from(
        rawText.matchAll(/{%\s+(?:image|figure)\s+[^%]*?src=["']([^"']+)["']/g),
        (match) => match[1]!,
      );
      if (typeof metadata[`image`] === `string`) {
        imageSources.push(metadata[`image`]);
      }

      for (const source of imageSources) {
        if (/^https?:\/\//.test(source)) continue;
        const assetPath = source.startsWith(`/`)
          ? path.join(process.cwd(), `public`, source)
          : path.join(process.cwd(), `public/docs/images`, source);
        if (!fs.existsSync(assetPath)) {
          missingAssets.push(`${path.basename(articlePath)}: ${source}`);
        }
      }
    }

    expect(missingAssets).toEqual([]);
  });
});

describe(`validatePublishingMetadata()`, () => {
  it(`validates Help metadata and defaults product associations`, () => {
    expect(
      validatePublishingMetadata(
        `help`,
        {
          title: `Resolve a Screen Time filter conflict`,
          description: `How to restore Gertrude filtering on a Mac.`,
          updated: `2026-08-18`,
          platforms: [`macos`],
        },
        `screen-time-filter-conflict`,
      ),
    ).toEqual({
      title: `Resolve a Screen Time filter conflict`,
      description: `How to restore Gertrude filtering on a Mac.`,
      image: undefined,
      updated: `2026-08-18`,
      products: [],
      platforms: [`macos`],
    });
  });

  it(`supports iOS and iPadOS Help articles`, () => {
    expect(
      validatePublishingMetadata(
        `help`,
        {
          title: `Resolve a filter problem`,
          description: `How to restore filtering.`,
          platforms: [`ios`, `ipados`],
        },
        `resolve-a-filter-problem`,
      ),
    ).toMatchObject({ platforms: [`ios`, `ipados`] });
  });

  it(`requires at least one Help platform`, () => {
    expect(() =>
      validatePublishingMetadata(
        `help`,
        {
          title: `Resolve a filter problem`,
          description: `How to restore filtering.`,
        },
        `resolve-a-filter-problem`,
      ),
    ).toThrow(`Help article resolve-a-filter-problem.md must have at least one platform`);
  });

  it(`rejects Help articles spanning Mac and mobile`, () => {
    expect(() =>
      validatePublishingMetadata(
        `help`,
        {
          title: `Resolve a filter problem`,
          description: `How to restore filtering.`,
          platforms: [`macos`, `ios`],
        },
        `resolve-a-filter-problem`,
      ),
    ).toThrow(
      `Help article resolve-a-filter-problem.md cannot mix Mac and mobile platforms`,
    );
  });

  it(`validates update-specific metadata and associations`, () => {
    expect(
      validatePublishingMetadata(
        `update`,
        {
          title: `Gertrude Music is here`,
          description: `Introducing approved-only music on iPhone and iPad.`,
          image: `music-launch.png`,
          date: `2025-11-12T12:00:00.000Z`,
          weight: `featured`,
          products: [`music`],
          platforms: [`ios`, `ipados`],
        },
        `gertrude-music-launch`,
      ),
    ).toEqual({
      title: `Gertrude Music is here`,
      description: `Introducing approved-only music on iPhone and iPad.`,
      image: `music-launch.png`,
      updated: undefined,
      date: `2025-11-12T12:00:00.000Z`,
      weight: `featured`,
      products: [`music`],
      platforms: [`ios`, `ipados`],
    });
  });

  it(`rejects unknown metadata fields`, () => {
    expect(() =>
      validatePublishingMetadata(
        `guide`,
        {
          title: `A guide`,
          description: `A useful guide.`,
          category: `ios`,
        },
        `a-guide`,
      ),
    ).toThrow(`Unexpected metadata in a-guide.md: category`);
  });

  it(`rejects invalid association values`, () => {
    expect(() =>
      validatePublishingMetadata(
        `legal`,
        {
          title: `Privacy policy`,
          description: `How Gertrude protects your privacy.`,
          products: [`unknown`],
        },
        `privacy`,
      ),
    ).toThrow(
      `Invalid products in privacy.md; expected values from: mac, blocker, music, podcasts`,
    );
  });

  it(`rejects invalid updated dates`, () => {
    expect(() =>
      validatePublishingMetadata(
        `guide`,
        {
          title: `A guide`,
          description: `A useful guide.`,
          updated: `not-a-date`,
        },
        `a-guide`,
      ),
    ).toThrow(`Invalid updated in a-guide.md`);
  });

  it(`rejects invalid update dates`, () => {
    expect(() =>
      validatePublishingMetadata(
        `update`,
        {
          title: `A product update`,
          description: `Something changed.`,
          date: `not-a-date`,
          weight: `brief`,
        },
        `a-product-update`,
      ),
    ).toThrow(`Invalid date in a-product-update.md: not-a-date`);
  });

  it(`requires a supported update weight`, () => {
    expect(() =>
      validatePublishingMetadata(
        `update`,
        {
          title: `A product update`,
          description: `Something changed.`,
          date: `2026-08-12T12:00:00.000Z`,
          weight: `medium`,
        },
        `a-product-update`,
      ),
    ).toThrow(
      `Missing or invalid weight in a-product-update.md; expected one of: brief, featured`,
    );
  });
});

describe(`getHelpArticlePath()`, () => {
  it.each([
    [`screen-time-filter-conflict`, `/help/mac/screen-time-filter-conflict`],
    [`block-apps`, `/help/mac/block-apps`],
    [`use-one-mac-for-multiple-children`, `/help/mac/use-one-mac-for-multiple-children`],
    [`decide-whether-to-unblock-youtube`, `/help/mac/decide-whether-to-unblock-youtube`],
    [
      `why-browsers-quit-after-filter-suspension`,
      `/help/mac/why-browsers-quit-after-filter-suspension`,
    ],
    [`give-admin-user-internet-access`, `/help/mac/give-admin-user-internet-access`],
    [`run-health-check`, `/help/mac/run-health-check`],
    [`diagnose-blocked-network-requests`, `/help/mac/diagnose-blocked-network-requests`],
    [`restart-filter`, `/help/mac/restart-filter`],
    [`unblock-website-or-app`, `/help/mac/unblock-website-or-app`],
    [
      `website-still-broken-after-unblocking`,
      `/help/mac/website-still-broken-after-unblocking`,
    ],
    [`send-unlock-request`, `/help/mac/send-unlock-request`],
  ])(`uses the Mac URL segment for %s`, (slug, expectedPath) => {
    expect(getHelpArticlePath({ platforms: [`macos`], slug })).toBe(expectedPath);
  });

  it.each([
    [`get-connection-code`, `/help/iphone-ipad/get-connection-code`],
    [`use-blocker-over-18`, `/help/iphone-ipad/use-blocker-over-18`],
    [`block-gif-search-in-messages`, `/help/iphone-ipad/block-gif-search-in-messages`],
    [`block-explicit-images-in-maps`, `/help/iphone-ipad/block-explicit-images-in-maps`],
    [
      `block-web-content-in-device-search`,
      `/help/iphone-ipad/block-web-content-in-device-search`,
    ],
    [`block-look-up-web-results`, `/help/iphone-ipad/block-look-up-web-results`],
    [`block-siri-internet-access`, `/help/iphone-ipad/block-siri-internet-access`],
    [`block-apple-music-artwork`, `/help/iphone-ipad/block-apple-music-artwork`],
  ])(`uses the iPhone and iPad URL segment for %s`, (slug, expectedPath) => {
    expect(getHelpArticlePath({ platforms: [`ios`, `ipados`], slug })).toBe(expectedPath);
  });
});

describe(`getBlogArticlePath()`, () => {
  it(`uses the Blog URL`, () => {
    expect(getBlogArticlePath({ slug: `mac-internet-filter` })).toBe(
      `/blog/mac-internet-filter`,
    );
  });
});

describe(`getProgramArticlePath()`, () => {
  it(`uses the root URL`, () => {
    expect(getProgramArticlePath({ slug: `refer-a-friend` })).toBe(`/refer-a-friend`);
  });
});

describe(`getUpdateArticlePath()`, () => {
  it(`uses the Updates URL`, () => {
    expect(getUpdateArticlePath({ slug: `gertrude-music-launch` })).toBe(
      `/updates/gertrude-music-launch`,
    );
  });
});

describe(`getLegalArticlePath()`, () => {
  it.each([
    [`privacy/blocker`, `/legal/privacy/blocker`],
    [`privacy/music`, `/legal/privacy/music`],
    [`privacy/podcasts`, `/legal/privacy/podcasts`],
    [`terms`, `/legal/terms`],
  ])(`uses the Legal URL for %s`, (slug, expectedPath) => {
    expect(getLegalArticlePath({ slug })).toBe(expectedPath);
  });
});

describe(`getGuideArticlePath()`, () => {
  it.each([
    [
      `unblocking-websites-and-apps-on-mac`,
      `/guides/unblocking-websites-and-apps-on-mac`,
    ],
    [
      `getting-started-with-gertrude-for-mac`,
      `/guides/getting-started-with-gertrude-for-mac`,
    ],
    [`keeping-kids-safe-online`, `/guides/keeping-kids-safe-online`],
    [`locking-down-an-iphone`, `/guides/locking-down-an-iphone`],
    [`locking-down-an-iphone/ios-17`, `/guides/locking-down-an-iphone/ios-17`],
  ])(`uses the Guides URL for %s`, (slug, expectedPath) => {
    expect(getGuideArticlePath({ slug })).toBe(expectedPath);
  });
});
