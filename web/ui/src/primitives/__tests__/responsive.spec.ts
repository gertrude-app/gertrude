import { describe, expect, test } from 'vitest';
import { createResponsiveClassMap, getResponsiveValueStyle } from '../responsive';
import {
  cardPaddingClasses,
  getCardPaddingAttributes,
  getResponsiveSpacingStyle,
  spacingToCssValue,
  stackGapClasses,
} from '../spacing';
import {
  getStackAttributes,
  getStackStyle,
  stackAlignClasses,
  stackDirectionClasses,
  stackJustifyClasses,
  stackWrapClasses,
} from '../stack-utils';

describe(`getResponsiveValueStyle()`, () => {
  test(`sets only the base variable for scalar values`, () => {
    const style = getResponsiveValueStyle(
      `horizontal`,
      `stack-direction`,
      (value) => value,
      `vertical`,
    );

    expect(style).toEqual({ '--stack-direction': `horizontal` });
  });

  test(`emits change points independently inside viewport and container groups`, () => {
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

    expect(style).toEqual({
      '--stack-direction': `vertical`,
      '--stack-direction-sm': `horizontal`,
      '--stack-direction-main-lg': `horizontal`,
      '--stack-direction-main-3xl': `vertical`,
      '--stack-direction-slide-md': `horizontal`,
    });
  });

  test(`uses the fallback default when a map omits default`, () => {
    const style = getResponsiveValueStyle(
      { '@xl/main': `horizontal` },
      `stack-direction`,
      (value) => value,
      `vertical`,
    );

    expect(style).toEqual({
      '--stack-direction': `vertical`,
      '--stack-direction-main-xl': `horizontal`,
    });
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

    expect(style).toEqual({
      '--stack-gap': `calc(var(--spacing) * 1)`,
      '--stack-gap-main-xl': `calc(var(--spacing) * 3.5)`,
      '--stack-gap-slide-lg': `calc(var(--spacing) * 6)`,
    });
    expect(stackGapClasses).toContain(`@xl/main:gap-[var(--stack-gap-main-xl)]`);
    expect(cardPaddingClasses).toContain(`@lg/slide:p-[var(--card-padding-slide-lg)]`);
  });

  test(`maps static class strings to responsive breakpoint keys`, () => {
    const classMap = createResponsiveClassMap(stackGapClasses);

    expect(classMap.default).toBe(`gap-[var(--stack-gap)]`);
    expect(classMap.sm).toBe(`sm:gap-[var(--stack-gap-sm)]`);
    expect(classMap[`@5xl/main`]).toBe(`@5xl/main:gap-[var(--stack-gap-main-5xl)]`);
    expect(classMap[`@md/slide`]).toBe(`@md/slide:gap-[var(--stack-gap-slide-md)]`);
  });

  test(`returns sparse padding attributes`, () => {
    const attributes = getCardPaddingAttributes({ default: 3, '@2xl/main': 4 }, 3);

    expect(attributes.style).toEqual({
      '--card-padding': `calc(var(--spacing) * 3)`,
      '--card-padding-main-2xl': `calc(var(--spacing) * 4)`,
    });
    expect(attributes.className).toBe(
      `p-[var(--card-padding)] @2xl/main:p-[var(--card-padding-main-2xl)]`,
    );
  });
});

describe(`getStackAttributes()`, () => {
  test(`emits only base attributes for scalar props`, () => {
    const attributes = getStackAttributes({
      direction: `vertical`,
      gap: 2,
      align: `stretch`,
      justify: `start`,
      wrap: false,
    });

    expect(attributes.style).toEqual({
      '--stack-direction': `column`,
      '--stack-gap': `calc(var(--spacing) * 2)`,
      '--stack-align': `stretch`,
      '--stack-justify': `flex-start`,
      '--stack-wrap': `nowrap`,
    });
    expect(attributes.className.split(/\s+/)).toHaveLength(5);
    expect(attributes.className).not.toContain(`xs:`);
    expect(attributes.className).not.toContain(`@xs/main:`);
  });

  test(`maps stack props to sparse responsive CSS variable values and classes`, () => {
    const attributes = getStackAttributes({
      direction: { default: `vertical`, '@xl/main': `horizontal` },
      gap: { default: 2, '@xl/main': 4 },
      align: { default: `stretch`, '@xl/main': `center` },
      justify: { default: `start`, '@xl/main': `between` },
      wrap: { default: true, '@xl/main': false },
    });

    expect(attributes.style).toEqual({
      '--stack-direction': `column`,
      '--stack-direction-main-xl': `row`,
      '--stack-gap': `calc(var(--spacing) * 2)`,
      '--stack-gap-main-xl': `calc(var(--spacing) * 4)`,
      '--stack-align': `stretch`,
      '--stack-align-main-xl': `center`,
      '--stack-justify': `flex-start`,
      '--stack-justify-main-xl': `space-between`,
      '--stack-wrap': `wrap`,
      '--stack-wrap-main-xl': `nowrap`,
    });
    expect(attributes.className).toContain(
      `@xl/main:[flex-direction:var(--stack-direction-main-xl)]`,
    );
    expect(attributes.className).toContain(`@xl/main:gap-[var(--stack-gap-main-xl)]`);
    expect(attributes.className).not.toContain(
      `@2xl/main:[flex-direction:var(--stack-direction-main-2xl)]`,
    );
  });

  test(`keeps getStackStyle as the style-only helper`, () => {
    const style = getStackStyle({
      direction: { default: `vertical`, '@xl/main': `horizontal` },
      gap: 2,
      align: `stretch`,
      justify: `start`,
      wrap: false,
    });

    expect(style[`--stack-direction-main-xl`]).toBe(`row`);
    expect(style[`--stack-gap-xs`]).toBeUndefined();
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
