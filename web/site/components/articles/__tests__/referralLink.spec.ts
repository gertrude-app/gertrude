import { afterEach, describe, expect, it, vi } from 'vitest';
import { copyToClipboard, friendShareUrl } from '../referralLink';

describe(`friendShareUrl()`, () => {
  it(`builds the friend short URL from a valid code, verbatim`, () => {
    expect(friendShareUrl(`K7M2QP9`)).toBe(`https://gertrude.app/u/K7M2QP9`);
  });

  it(`normalizes whitespace and casing before building the URL`, () => {
    expect(friendShareUrl(`  k7m2qp9 `)).toBe(`https://gertrude.app/u/K7M2QP9`);
  });

  it(`returns undefined for a missing code`, () => {
    expect(friendShareUrl(null)).toBeUndefined();
    expect(friendShareUrl(undefined)).toBeUndefined();
    expect(friendShareUrl(``)).toBeUndefined();
    expect(friendShareUrl(`   `)).toBeUndefined();
  });

  it(`returns undefined for malformed codes rather than a bogus URL`, () => {
    expect(friendShareUrl(`K7M2QP`)).toBeUndefined(); // too short (6)
    expect(friendShareUrl(`K7M2QP90`)).toBeUndefined(); // too long (8)
    expect(friendShareUrl(`K7M2QP0`)).toBeUndefined(); // excluded char 0
    expect(friendShareUrl(`K7M2QP1`)).toBeUndefined(); // excluded char 1
    expect(friendShareUrl(`K7M2QPI`)).toBeUndefined(); // excluded char I
    expect(friendShareUrl(`K7M2QPO`)).toBeUndefined(); // excluded char O
    expect(friendShareUrl(`K7M2QP9 OR 1=1`)).toBeUndefined(); // junk input
  });
});

describe(`copyToClipboard()`, () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it(`writes the text and reports success`, async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    vi.stubGlobal(`navigator`, { clipboard: { writeText } });
    expect(await copyToClipboard(`https://gertrude.app/u/K7M2QP9`)).toBe(true);
    expect(writeText).toHaveBeenCalledWith(`https://gertrude.app/u/K7M2QP9`);
  });

  it(`reports failure without throwing when the clipboard rejects`, async () => {
    const writeText = vi.fn().mockRejectedValue(new Error(`denied`));
    vi.stubGlobal(`navigator`, { clipboard: { writeText } });
    expect(await copyToClipboard(`https://gertrude.app/u/K7M2QP9`)).toBe(false);
  });

  it(`reports failure when no clipboard API is available`, async () => {
    vi.stubGlobal(`navigator`, {});
    expect(await copyToClipboard(`https://gertrude.app/u/K7M2QP9`)).toBe(false);
  });
});
