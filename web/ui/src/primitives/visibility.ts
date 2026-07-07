import type { ResponsiveBreakpoint } from './responsive';

export type VisibilityBreakpoint = ResponsiveBreakpoint;
export type VisibilityRestoreDisplay = `block` | `flex` | `inline`;

export interface VisibilityProps {
  hideBelow?: VisibilityBreakpoint;
  hideAbove?: VisibilityBreakpoint;
}

const visibleAtOrAboveClasses: Record<
  VisibilityBreakpoint,
  Record<VisibilityRestoreDisplay, string>
> = {
  xs: { block: `xs:block`, flex: `xs:flex`, inline: `xs:inline` },
  sm: { block: `sm:block`, flex: `sm:flex`, inline: `sm:inline` },
  md: { block: `md:block`, flex: `md:flex`, inline: `md:inline` },
  lg: { block: `lg:block`, flex: `lg:flex`, inline: `lg:inline` },
  xl: { block: `xl:block`, flex: `xl:flex`, inline: `xl:inline` },
  '2xl': { block: `2xl:block`, flex: `2xl:flex`, inline: `2xl:inline` },
  '@xs/main': {
    block: `@xs/main:block`,
    flex: `@xs/main:flex`,
    inline: `@xs/main:inline`,
  },
  '@sm/main': {
    block: `@sm/main:block`,
    flex: `@sm/main:flex`,
    inline: `@sm/main:inline`,
  },
  '@md/main': {
    block: `@md/main:block`,
    flex: `@md/main:flex`,
    inline: `@md/main:inline`,
  },
  '@lg/main': {
    block: `@lg/main:block`,
    flex: `@lg/main:flex`,
    inline: `@lg/main:inline`,
  },
  '@xl/main': {
    block: `@xl/main:block`,
    flex: `@xl/main:flex`,
    inline: `@xl/main:inline`,
  },
  '@2xl/main': {
    block: `@2xl/main:block`,
    flex: `@2xl/main:flex`,
    inline: `@2xl/main:inline`,
  },
  '@3xl/main': {
    block: `@3xl/main:block`,
    flex: `@3xl/main:flex`,
    inline: `@3xl/main:inline`,
  },
  '@4xl/main': {
    block: `@4xl/main:block`,
    flex: `@4xl/main:flex`,
    inline: `@4xl/main:inline`,
  },
  '@5xl/main': {
    block: `@5xl/main:block`,
    flex: `@5xl/main:flex`,
    inline: `@5xl/main:inline`,
  },
  '@6xl/main': {
    block: `@6xl/main:block`,
    flex: `@6xl/main:flex`,
    inline: `@6xl/main:inline`,
  },
  '@7xl/main': {
    block: `@7xl/main:block`,
    flex: `@7xl/main:flex`,
    inline: `@7xl/main:inline`,
  },
  '@xs/slide': {
    block: `@xs/slide:block`,
    flex: `@xs/slide:flex`,
    inline: `@xs/slide:inline`,
  },
  '@sm/slide': {
    block: `@sm/slide:block`,
    flex: `@sm/slide:flex`,
    inline: `@sm/slide:inline`,
  },
  '@md/slide': {
    block: `@md/slide:block`,
    flex: `@md/slide:flex`,
    inline: `@md/slide:inline`,
  },
  '@lg/slide': {
    block: `@lg/slide:block`,
    flex: `@lg/slide:flex`,
    inline: `@lg/slide:inline`,
  },
  '@xl/slide': {
    block: `@xl/slide:block`,
    flex: `@xl/slide:flex`,
    inline: `@xl/slide:inline`,
  },
  '@2xl/slide': {
    block: `@2xl/slide:block`,
    flex: `@2xl/slide:flex`,
    inline: `@2xl/slide:inline`,
  },
  '@3xl/slide': {
    block: `@3xl/slide:block`,
    flex: `@3xl/slide:flex`,
    inline: `@3xl/slide:inline`,
  },
  '@4xl/slide': {
    block: `@4xl/slide:block`,
    flex: `@4xl/slide:flex`,
    inline: `@4xl/slide:inline`,
  },
  '@5xl/slide': {
    block: `@5xl/slide:block`,
    flex: `@5xl/slide:flex`,
    inline: `@5xl/slide:inline`,
  },
  '@6xl/slide': {
    block: `@6xl/slide:block`,
    flex: `@6xl/slide:flex`,
    inline: `@6xl/slide:inline`,
  },
  '@7xl/slide': {
    block: `@7xl/slide:block`,
    flex: `@7xl/slide:flex`,
    inline: `@7xl/slide:inline`,
  },
};

const hiddenAtOrAboveClasses: Record<VisibilityBreakpoint, string> = {
  xs: `xs:hidden`,
  sm: `sm:hidden`,
  md: `md:hidden`,
  lg: `lg:hidden`,
  xl: `xl:hidden`,
  '2xl': `2xl:hidden`,
  '@xs/main': `@xs/main:hidden`,
  '@sm/main': `@sm/main:hidden`,
  '@md/main': `@md/main:hidden`,
  '@lg/main': `@lg/main:hidden`,
  '@xl/main': `@xl/main:hidden`,
  '@2xl/main': `@2xl/main:hidden`,
  '@3xl/main': `@3xl/main:hidden`,
  '@4xl/main': `@4xl/main:hidden`,
  '@5xl/main': `@5xl/main:hidden`,
  '@6xl/main': `@6xl/main:hidden`,
  '@7xl/main': `@7xl/main:hidden`,
  '@xs/slide': `@xs/slide:hidden`,
  '@sm/slide': `@sm/slide:hidden`,
  '@md/slide': `@md/slide:hidden`,
  '@lg/slide': `@lg/slide:hidden`,
  '@xl/slide': `@xl/slide:hidden`,
  '@2xl/slide': `@2xl/slide:hidden`,
  '@3xl/slide': `@3xl/slide:hidden`,
  '@4xl/slide': `@4xl/slide:hidden`,
  '@5xl/slide': `@5xl/slide:hidden`,
  '@6xl/slide': `@6xl/slide:hidden`,
  '@7xl/slide': `@7xl/slide:hidden`,
};

export const getVisibilityClasses = ({
  hideBelow,
  hideAbove,
  restoreDisplay,
}: VisibilityProps & { restoreDisplay: VisibilityRestoreDisplay }): string[] => [
  hideBelow ? `hidden` : ``,
  hideBelow ? visibleAtOrAboveClasses[hideBelow][restoreDisplay] : ``,
  hideAbove ? hiddenAtOrAboveClasses[hideAbove] : ``,
];
