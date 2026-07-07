import {
  type CSSVariableProperties,
  type ResponsiveValue,
  type ResponsiveValueMap,
  getResponsiveValueStyle,
} from './responsive';

export type {
  CSSVariableProperties,
  ContainerBreakpoint,
  ContainerName,
  ContainerSize,
  ResponsiveBreakpoint,
  ResponsiveValue,
  ResponsiveValueMap,
  ViewportBreakpoint,
} from './responsive';

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

export type ResponsiveSpacingMap = ResponsiveValueMap<Spacing>;
export type ResponsiveSpacing = ResponsiveValue<Spacing>;

export const stackGapClasses = `gap-[var(--stack-gap)] xs:gap-[var(--stack-gap-xs)] sm:gap-[var(--stack-gap-sm)] md:gap-[var(--stack-gap-md)] lg:gap-[var(--stack-gap-lg)] xl:gap-[var(--stack-gap-xl)] 2xl:gap-[var(--stack-gap-2xl)] @xs/main:gap-[var(--stack-gap-main-xs)] @sm/main:gap-[var(--stack-gap-main-sm)] @md/main:gap-[var(--stack-gap-main-md)] @lg/main:gap-[var(--stack-gap-main-lg)] @xl/main:gap-[var(--stack-gap-main-xl)] @2xl/main:gap-[var(--stack-gap-main-2xl)] @3xl/main:gap-[var(--stack-gap-main-3xl)] @4xl/main:gap-[var(--stack-gap-main-4xl)] @5xl/main:gap-[var(--stack-gap-main-5xl)] @6xl/main:gap-[var(--stack-gap-main-6xl)] @7xl/main:gap-[var(--stack-gap-main-7xl)] @xs/slide:gap-[var(--stack-gap-slide-xs)] @sm/slide:gap-[var(--stack-gap-slide-sm)] @md/slide:gap-[var(--stack-gap-slide-md)] @lg/slide:gap-[var(--stack-gap-slide-lg)] @xl/slide:gap-[var(--stack-gap-slide-xl)] @2xl/slide:gap-[var(--stack-gap-slide-2xl)] @3xl/slide:gap-[var(--stack-gap-slide-3xl)] @4xl/slide:gap-[var(--stack-gap-slide-4xl)] @5xl/slide:gap-[var(--stack-gap-slide-5xl)] @6xl/slide:gap-[var(--stack-gap-slide-6xl)] @7xl/slide:gap-[var(--stack-gap-slide-7xl)]`;

export const cardPaddingClasses = `p-[var(--card-padding)] xs:p-[var(--card-padding-xs)] sm:p-[var(--card-padding-sm)] md:p-[var(--card-padding-md)] lg:p-[var(--card-padding-lg)] xl:p-[var(--card-padding-xl)] 2xl:p-[var(--card-padding-2xl)] @xs/main:p-[var(--card-padding-main-xs)] @sm/main:p-[var(--card-padding-main-sm)] @md/main:p-[var(--card-padding-main-md)] @lg/main:p-[var(--card-padding-main-lg)] @xl/main:p-[var(--card-padding-main-xl)] @2xl/main:p-[var(--card-padding-main-2xl)] @3xl/main:p-[var(--card-padding-main-3xl)] @4xl/main:p-[var(--card-padding-main-4xl)] @5xl/main:p-[var(--card-padding-main-5xl)] @6xl/main:p-[var(--card-padding-main-6xl)] @7xl/main:p-[var(--card-padding-main-7xl)] @xs/slide:p-[var(--card-padding-slide-xs)] @sm/slide:p-[var(--card-padding-slide-sm)] @md/slide:p-[var(--card-padding-slide-md)] @lg/slide:p-[var(--card-padding-slide-lg)] @xl/slide:p-[var(--card-padding-slide-xl)] @2xl/slide:p-[var(--card-padding-slide-2xl)] @3xl/slide:p-[var(--card-padding-slide-3xl)] @4xl/slide:p-[var(--card-padding-slide-4xl)] @5xl/slide:p-[var(--card-padding-slide-5xl)] @6xl/slide:p-[var(--card-padding-slide-6xl)] @7xl/slide:p-[var(--card-padding-slide-7xl)]`;

export const spacingToCssValue = (spacing: Spacing): string =>
  spacing === 0 ? `0px` : `calc(var(--spacing) * ${spacing})`;

export const getResponsiveSpacingStyle = (
  spacing: ResponsiveSpacing,
  variableName: string,
  defaultSpacing: Spacing = 0,
): CSSVariableProperties =>
  getResponsiveValueStyle(spacing, variableName, spacingToCssValue, defaultSpacing);
