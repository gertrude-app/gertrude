import { describe, expect, test } from 'vitest';
import { sortExtraMonitoringOpts } from '../SuspendFilterRequestForm';

describe(`sortExtraMonitoringOpts()`, () => {
  const cases: Array<[string[], string[]]> = [
    [
      [`@30+k`, `@90+k`, `@90`],
      [`@90`, `@30+k`, `@90+k`],
    ],
    [
      [`@90`, `@60`, `@30`],
      [`@30`, `@60`, `@90`],
    ],
    [
      [`@90`, `@120`, `@30`],
      [`@30`, `@90`, `@120`],
    ],
    [
      [`k`, `@90`, `@60`, `@30`],
      [`@30`, `@60`, `@90`, `k`],
    ],
    [
      [`@1200+k`, `@30+k`, `k`, `@90`, `@60`, `@30`],
      [`@30`, `@60`, `@90`, `k`, `@30+k`, `@1200+k`],
    ],
  ];
  test.each(cases)(`sorts %s to %s`, (input, expected) => {
    const sorted = [...input].sort(sortExtraMonitoringOpts);
    expect(sorted).toEqual(expected);
  });
});
