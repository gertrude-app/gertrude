import { describe, expect, test } from 'vitest';
import {
  getResponsiveValueStyle,
  responsiveBreakpointSuffixes,
  responsiveBreakpoints,
} from '../responsive';
import {
  cardPaddingClasses,
  getResponsiveSpacingStyle,
  spacingToCssValue,
  stackGapClasses,
} from '../spacing';
import {
  getStackStyle,
  stackAlignClasses,
  stackDirectionClasses,
  stackJustifyClasses,
  stackWrapClasses,
} from '../stack-utils';

const variableNamesFor = (variableName: string): string[] => [
  `--${variableName}`,
  ...responsiveBreakpoints.map(
    (breakpoint) => `--${variableName}-${responsiveBreakpointSuffixes[breakpoint]}`,
  ),
];

describe(`getResponsiveValueStyle()`, () => {
  test(`sets every supported breakpoint for scalar values`, () => {
    const style = getResponsiveValueStyle(
      `horizontal`,
      `stack-direction`,
      (value) => value,
      `vertical`,
    );

    expect(Object.keys(style).sort()).toEqual(variableNamesFor(`stack-direction`).sort());
    expect(style[`--stack-direction`]).toBe(`horizontal`);
    expect(style[`--stack-direction-md`]).toBe(`horizontal`);
    expect(style[`--stack-direction-main-5xl`]).toBe(`horizontal`);
    expect(style[`--stack-direction-slide-lg`]).toBe(`horizontal`);
  });

  test(`inherits values independently inside viewport and container groups`, () => {
    const style = getResponsiveValueStyle(
      {
        default: `vertical`,
        sm: `horizontal`,
        '@lg/main': `horizontal`,
        '@3xl/main': `vertical`,
        '@md/slide': `horizontal`,
      },
      `stack-direction`,
      (value) => value,
      `vertical`,
    );

    expect(style[`--stack-direction-xs`]).toBe(`vertical`);
    expect(style[`--stack-direction-sm`]).toBe(`horizontal`);
    expect(style[`--stack-direction-2xl`]).toBe(`horizontal`);
    expect(style[`--stack-direction-main-md`]).toBe(`vertical`);
    expect(style[`--stack-direction-main-lg`]).toBe(`horizontal`);
    expect(style[`--stack-direction-main-2xl`]).toBe(`horizontal`);
    expect(style[`--stack-direction-main-3xl`]).toBe(`vertical`);
    expect(style[`--stack-direction-slide-sm`]).toBe(`vertical`);
    expect(style[`--stack-direction-slide-md`]).toBe(`horizontal`);
    expect(style[`--stack-direction-slide-7xl`]).toBe(`horizontal`);
  });

  test(`uses the fallback default when a map omits default`, () => {
    const style = getResponsiveValueStyle(
      { '@xl/main': `horizontal` },
      `stack-direction`,
      (value) => value,
      `vertical`,
    );

    expect(style[`--stack-direction`]).toBe(`vertical`);
    expect(style[`--stack-direction-lg`]).toBe(`vertical`);
    expect(style[`--stack-direction-main-lg`]).toBe(`vertical`);
    expect(style[`--stack-direction-main-xl`]).toBe(`horizontal`);
    expect(style[`--stack-direction-main-7xl`]).toBe(`horizontal`);
    expect(style[`--stack-direction-slide-7xl`]).toBe(`vertical`);
  });
});

describe(`spacing responsive helpers`, () => {
  test(`serializes the spacing scale into CSS values`, () => {
    expect(spacingToCssValue(0)).toBe(`0px`);
    expect(spacingToCssValue(3.5)).toBe(`calc(var(--spacing) * 3.5)`);
  });

  test(`supports container breakpoints for gap and padding variables`, () => {
    const style = getResponsiveSpacingStyle(
      { default: 1, '@xl/main': 3.5, '@lg/slide': 6 },
      `stack-gap`,
    );

    expect(style[`--stack-gap`]).toBe(`calc(var(--spacing) * 1)`);
    expect(style[`--stack-gap-main-lg`]).toBe(`calc(var(--spacing) * 1)`);
    expect(style[`--stack-gap-main-xl`]).toBe(`calc(var(--spacing) * 3.5)`);
    expect(style[`--stack-gap-main-7xl`]).toBe(`calc(var(--spacing) * 3.5)`);
    expect(style[`--stack-gap-slide-md`]).toBe(`calc(var(--spacing) * 1)`);
    expect(style[`--stack-gap-slide-lg`]).toBe(`calc(var(--spacing) * 6)`);
    expect(stackGapClasses).toContain(`@xl/main:gap-[var(--stack-gap-main-xl)]`);
    expect(cardPaddingClasses).toContain(`@lg/slide:p-[var(--card-padding-slide-lg)]`);
  });
});

describe(`getStackStyle()`, () => {
  test(`maps stack props to responsive CSS variable values`, () => {
    const style = getStackStyle({
      direction: { default: `vertical`, '@xl/main': `horizontal` },
      gap: { default: 2, '@xl/main': 4 },
      align: { default: `stretch`, '@xl/main': `center` },
      justify: { default: `start`, '@xl/main': `between` },
      wrap: { default: true, '@xl/main': false },
    });

    expect(style[`--stack-direction`]).toBe(`column`);
    expect(style[`--stack-direction-main-xl`]).toBe(`row`);
    expect(style[`--stack-gap-main-xl`]).toBe(`calc(var(--spacing) * 4)`);
    expect(style[`--stack-align-main-xl`]).toBe(`center`);
    expect(style[`--stack-justify-main-xl`]).toBe(`space-between`);
    expect(style[`--stack-wrap`]).toBe(`wrap`);
    expect(style[`--stack-wrap-main-xl`]).toBe(`nowrap`);
  });

  test(`keeps Tailwind-visible classes for every responsive stack property`, () => {
    expect(stackDirectionClasses).toContain(
      `@xl/main:[flex-direction:var(--stack-direction-main-xl)]`,
    );
    expect(stackAlignClasses).toContain(
      `@md/slide:[align-items:var(--stack-align-slide-md)]`,
    );
    expect(stackJustifyClasses).toContain(
      `2xl:[justify-content:var(--stack-justify-2xl)]`,
    );
    expect(stackWrapClasses).toContain(
      `@7xl/main:[flex-wrap:var(--stack-wrap-main-7xl)]`,
    );
  });
});
