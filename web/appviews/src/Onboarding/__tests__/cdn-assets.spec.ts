import { expect, test } from 'vitest';
import assets from '../cdn-assets';

test(
  `all cdn assets exist`,
  async () => {
    const results = await Promise.all(
      assets
        .all()
        .map((asset) =>
          fetch(asset.url, { method: `HEAD` }).then((res) => [asset.url, res.status]),
        ),
    );
    const expected = assets.all().map((asset) => [asset.url, 200]);
    expect(results).toEqual(expected);
  },
  { timeout: 20000 },
);
