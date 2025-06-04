import { describe, expect, it, test } from 'vitest';
import { SIZES, extractScreenshotTest, parseTestSizes } from '../extract-screenshot-test';

describe(`parseTestSizes()`, () => {
  const cases: Array<[string | undefined, Array<{ width: number; height: number }>]> = [
    [undefined, [SIZES.xs]],
    [``, [SIZES.xs]],
    [`xs`, [SIZES.xs]],
    [`100/200`, [{ width: 100, height: 200 }]],
    [`xs/200`, [{ width: 375, height: 200 }]],
    [`sm`, [SIZES.sm]],
    [`md`, [SIZES.md]],
    [`lg`, [SIZES.lg]],
    [`xl`, [SIZES.xl]],
    [`xs,sm`, [SIZES.xs, SIZES.sm]],
    [
      `50/60,30/xl,sm/800`,
      [
        { width: 50, height: 60 },
        { width: 30, height: SIZES.xl.height },
        { width: SIZES.sm.width, height: 800 },
      ],
    ],
  ];
  test.each(cases)(`\`%s\` parsed correctly`, (sizeStr, expected) => {
    expect(parseTestSizes(sizeStr)).toEqual(expected);
  });
});

describe(`extractScreenshotTest()`, () => {
  it(`should extract a notated screenshot test`, () => {
    const file = [
      `// @screenshot: xs`,
      `export const RoflCopter = Template.bind({});`,
    ].join(`\n`);

    const data = {
      id: `foo-bar-baz--rofl-copter`,
      title: `Foo/Bar/Baz`,
      name: `Rofl Copter`,
    };

    const test = extractScreenshotTest(file, data);
    expect(test).toEqual({
      id: `foo-bar-baz--rofl-copter`,
      sizes: [{ width: 375, height: 812 }],
    });
  });

  it(`should can handle multiple screenshots`, () => {
    const file = [
      `// @screenshot: md`,
      `export const LolRofl = Template.bind({});`,
      `// @screenshot: xs`,
      `export const RoflCopter = Template.bind({});`,
    ].join(`\n`);

    const data = {
      id: `foo-bar-baz--rofl-copter`,
      title: `Foo/Bar/Baz`,
      name: `Rofl Copter`,
    };

    const test = extractScreenshotTest(file, data);
    expect(test).toEqual({
      id: `foo-bar-baz--rofl-copter`,
      sizes: [{ width: 375, height: 812 }],
    });
  });
});
