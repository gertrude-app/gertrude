import { expect, test } from 'vitest';
import assets from '../cdn-assets';

test(`all cdn assets exist`, { timeout: 20000 }, async () => {
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
  const results = await Promise.all(
    urls.map((url) => fetch(url, { method: `HEAD` }).then((res) => [url, res.status])),
  );
  const expected = urls.map((url) => [url, 200]);
  expect(results).toEqual(expected);
});
