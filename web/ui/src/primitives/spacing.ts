import type React from 'react';

export type Spacing =
  | 0
  | 0.5
  | 1
  | 1.5
  | 2
  | 2.5
  | 3
  | 3.5
  | 4
  | 5
  | 6
  | 7
  | 8
  | 9
  | 10
  | 11
  | 12
  | 14
  | 16
  | 20
  | 24;

export type ResponsiveBreakpoint = `xs` | `sm` | `md` | `lg` | `xl` | `2xl`;
export type ResponsiveSpacingMap = { default?: Spacing } & Partial<
  Record<ResponsiveBreakpoint, Spacing>
>;
export type ResponsiveSpacing = Spacing | ResponsiveSpacingMap;

export type CSSVariableProperties = React.CSSProperties &
  Partial<Record<`--${string}`, string>>;

export const responsiveBreakpoints = [`xs`, `sm`, `md`, `lg`, `xl`, `2xl`] as const;

export const stackGapClasses = `gap-[var(--stack-gap)] xs:gap-[var(--stack-gap-xs)] sm:gap-[var(--stack-gap-sm)] md:gap-[var(--stack-gap-md)] lg:gap-[var(--stack-gap-lg)] xl:gap-[var(--stack-gap-xl)] 2xl:gap-[var(--stack-gap-2xl)]`;

export const cardPaddingClasses = `p-[var(--card-padding)] xs:p-[var(--card-padding-xs)] sm:p-[var(--card-padding-sm)] md:p-[var(--card-padding-md)] lg:p-[var(--card-padding-lg)] xl:p-[var(--card-padding-xl)] 2xl:p-[var(--card-padding-2xl)]`;

const spacingToCssValue = (spacing: Spacing): string =>
  spacing === 0 ? `0px` : `calc(var(--spacing) * ${spacing})`;

const isResponsiveSpacingMap = (
  spacing: ResponsiveSpacing,
): spacing is ResponsiveSpacingMap => typeof spacing === `object`;

const setSpacingVariable = (
  style: CSSVariableProperties,
  variableName: string,
  suffix: ResponsiveBreakpoint | undefined,
  spacing: Spacing,
): void => {
  const name = suffix ? `--${variableName}-${suffix}` : `--${variableName}`;
  style[name as `--${string}`] = spacingToCssValue(spacing);
};

export const getResponsiveSpacingStyle = (
  spacing: ResponsiveSpacing,
  variableName: string,
  defaultSpacing: Spacing = 0,
): CSSVariableProperties => {
  const style: CSSVariableProperties = {};

  if (!isResponsiveSpacingMap(spacing)) {
    setSpacingVariable(style, variableName, undefined, spacing);
    responsiveBreakpoints.forEach((breakpoint) => {
      setSpacingVariable(style, variableName, breakpoint, spacing);
    });
    return style;
  }

  let currentSpacing = spacing.default ?? defaultSpacing;
  setSpacingVariable(style, variableName, undefined, currentSpacing);

  responsiveBreakpoints.forEach((breakpoint) => {
    currentSpacing = spacing[breakpoint] ?? currentSpacing;
    setSpacingVariable(style, variableName, breakpoint, currentSpacing);
  });

  return style;
};
