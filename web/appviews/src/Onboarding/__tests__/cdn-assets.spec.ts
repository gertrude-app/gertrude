import { expect, test } from 'vitest';
import assets from '../cdn-assets';

const CONCURRENCY = 12;

test(`all cdn assets exist`, { timeout: 60000 }, async () => {
  const urls = assets.all().flatMap((asset) => {
    switch (asset.type) {
      case `video`:
      case `image`:
      case `gif`:
        return [asset.url];
      default:
        return asset.steps.map((step) => step.url);
    }
  });
  const results: Array<[string, number]> = [];
  for (let i = 0; i < urls.length; i += CONCURRENCY) {
    const batch = await Promise.all(
      urls
        .slice(i, i + CONCURRENCY)
        .map((url) =>
          fetch(url, { method: `HEAD` }).then((res): [string, number] => [
            url,
            res.status,
          ]),
        ),
    );
    results.push(...batch);
  }
  const expected = urls.map((url) => [url, 200]);
  expect(results).toEqual(expected);
});
