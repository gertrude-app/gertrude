import { describe, expect, test } from 'vitest';
import { sortExtraMonitoringOptions } from '../SuspensionRequestResponseModal';

describe(`Suspension request response modal`, () => {
  test(`orders screenshot frequencies within each monitoring group`, () => {
    const options = [`@30+k`, `k`, `@60`, `@90+k`, `@30`, `@90`, `@60+k`];

    expect(options.sort(sortExtraMonitoringOptions)).toEqual([
      `@90`,
      `@60`,
      `@30`,
      `k`,
      `@90+k`,
      `@60+k`,
      `@30+k`,
    ]);
  });
});
