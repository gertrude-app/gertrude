import type { PolymorphicProps } from './polymorphic';
import type { VisibilityProps } from './visibility';
import type React from 'react';
import {
  type ResponsiveValueAttributes,
  createResponsiveClassMap,
  getResponsiveValueAttributes,
  mergeResponsiveValueAttributes,
} from './responsive';
import {
  type CSSVariableProperties,
  type ResponsiveSpacing,
  type ResponsiveValue,
  type Spacing,
  getStackGapAttributes,
} from './spacing';

export type StackGap = Spacing;
export type ResponsiveStackGap = ResponsiveSpacing;
export type StackDirection = `vertical` | `horizontal`;
export type StackAlign = `start` | `center` | `end` | `stretch` | `baseline`;
export type StackJustify = `start` | `center` | `end` | `between` | `around` | `evenly`;
export type StackWrap = boolean;
export type ResponsiveStackDirection = ResponsiveValue<StackDirection>;
export type ResponsiveStackAlign = ResponsiveValue<StackAlign>;
export type ResponsiveStackJustify = ResponsiveValue<StackJustify>;
export type ResponsiveStackWrap = ResponsiveValue<StackWrap>;
export type StackElement = React.ElementType;

export interface StackOwnProps extends VisibilityProps {
  children?: React.ReactNode;
  direction?: ResponsiveStackDirection;
  gap?: ResponsiveStackGap;
  align?: ResponsiveStackAlign;
  justify?: ResponsiveStackJustify;
  wrap?: ResponsiveStackWrap;
  className?: string;
  style?: React.CSSProperties;
}

export type StackProps<Element extends React.ElementType = `div`> = PolymorphicProps<
  Element,
  StackOwnProps
>;

export type StackStyleOptions = Required<
  Pick<StackOwnProps, `direction` | `gap` | `align` | `justify` | `wrap`>
>;

const stackDirectionCssValues: Record<StackDirection, string> = {
  vertical: `column`,
  horizontal: `row`,
};

const stackAlignCssValues: Record<StackAlign, string> = {
  start: `flex-start`,
  center: `center`,
  end: `flex-end`,
  stretch: `stretch`,
  baseline: `baseline`,
};

const stackJustifyCssValues: Record<StackJustify, string> = {
  start: `flex-start`,
  center: `center`,
  end: `flex-end`,
  between: `space-between`,
  around: `space-around`,
  evenly: `space-evenly`,
};

const stackWrapCssValue = (wrap: StackWrap): string => (wrap ? `wrap` : `nowrap`);

export const stackDirectionClasses = `[flex-direction:var(--stack-direction)] xs:[flex-direction:var(--stack-direction-xs)] sm:[flex-direction:var(--stack-direction-sm)] md:[flex-direction:var(--stack-direction-md)] lg:[flex-direction:var(--stack-direction-lg)] xl:[flex-direction:var(--stack-direction-xl)] 2xl:[flex-direction:var(--stack-direction-2xl)] @xs/main:[flex-direction:var(--stack-direction-main-xs)] @sm/main:[flex-direction:var(--stack-direction-main-sm)] @md/main:[flex-direction:var(--stack-direction-main-md)] @lg/main:[flex-direction:var(--stack-direction-main-lg)] @xl/main:[flex-direction:var(--stack-direction-main-xl)] @2xl/main:[flex-direction:var(--stack-direction-main-2xl)] @3xl/main:[flex-direction:var(--stack-direction-main-3xl)] @4xl/main:[flex-direction:var(--stack-direction-main-4xl)] @5xl/main:[flex-direction:var(--stack-direction-main-5xl)] @6xl/main:[flex-direction:var(--stack-direction-main-6xl)] @7xl/main:[flex-direction:var(--stack-direction-main-7xl)] @xs/slide:[flex-direction:var(--stack-direction-slide-xs)] @sm/slide:[flex-direction:var(--stack-direction-slide-sm)] @md/slide:[flex-direction:var(--stack-direction-slide-md)] @lg/slide:[flex-direction:var(--stack-direction-slide-lg)] @xl/slide:[flex-direction:var(--stack-direction-slide-xl)] @2xl/slide:[flex-direction:var(--stack-direction-slide-2xl)] @3xl/slide:[flex-direction:var(--stack-direction-slide-3xl)] @4xl/slide:[flex-direction:var(--stack-direction-slide-4xl)] @5xl/slide:[flex-direction:var(--stack-direction-slide-5xl)] @6xl/slide:[flex-direction:var(--stack-direction-slide-6xl)] @7xl/slide:[flex-direction:var(--stack-direction-slide-7xl)]`;

export const stackAlignClasses = `[align-items:var(--stack-align)] xs:[align-items:var(--stack-align-xs)] sm:[align-items:var(--stack-align-sm)] md:[align-items:var(--stack-align-md)] lg:[align-items:var(--stack-align-lg)] xl:[align-items:var(--stack-align-xl)] 2xl:[align-items:var(--stack-align-2xl)] @xs/main:[align-items:var(--stack-align-main-xs)] @sm/main:[align-items:var(--stack-align-main-sm)] @md/main:[align-items:var(--stack-align-main-md)] @lg/main:[align-items:var(--stack-align-main-lg)] @xl/main:[align-items:var(--stack-align-main-xl)] @2xl/main:[align-items:var(--stack-align-main-2xl)] @3xl/main:[align-items:var(--stack-align-main-3xl)] @4xl/main:[align-items:var(--stack-align-main-4xl)] @5xl/main:[align-items:var(--stack-align-main-5xl)] @6xl/main:[align-items:var(--stack-align-main-6xl)] @7xl/main:[align-items:var(--stack-align-main-7xl)] @xs/slide:[align-items:var(--stack-align-slide-xs)] @sm/slide:[align-items:var(--stack-align-slide-sm)] @md/slide:[align-items:var(--stack-align-slide-md)] @lg/slide:[align-items:var(--stack-align-slide-lg)] @xl/slide:[align-items:var(--stack-align-slide-xl)] @2xl/slide:[align-items:var(--stack-align-slide-2xl)] @3xl/slide:[align-items:var(--stack-align-slide-3xl)] @4xl/slide:[align-items:var(--stack-align-slide-4xl)] @5xl/slide:[align-items:var(--stack-align-slide-5xl)] @6xl/slide:[align-items:var(--stack-align-slide-6xl)] @7xl/slide:[align-items:var(--stack-align-slide-7xl)]`;

export const stackJustifyClasses = `[justify-content:var(--stack-justify)] xs:[justify-content:var(--stack-justify-xs)] sm:[justify-content:var(--stack-justify-sm)] md:[justify-content:var(--stack-justify-md)] lg:[justify-content:var(--stack-justify-lg)] xl:[justify-content:var(--stack-justify-xl)] 2xl:[justify-content:var(--stack-justify-2xl)] @xs/main:[justify-content:var(--stack-justify-main-xs)] @sm/main:[justify-content:var(--stack-justify-main-sm)] @md/main:[justify-content:var(--stack-justify-main-md)] @lg/main:[justify-content:var(--stack-justify-main-lg)] @xl/main:[justify-content:var(--stack-justify-main-xl)] @2xl/main:[justify-content:var(--stack-justify-main-2xl)] @3xl/main:[justify-content:var(--stack-justify-main-3xl)] @4xl/main:[justify-content:var(--stack-justify-main-4xl)] @5xl/main:[justify-content:var(--stack-justify-main-5xl)] @6xl/main:[justify-content:var(--stack-justify-main-6xl)] @7xl/main:[justify-content:var(--stack-justify-main-7xl)] @xs/slide:[justify-content:var(--stack-justify-slide-xs)] @sm/slide:[justify-content:var(--stack-justify-slide-sm)] @md/slide:[justify-content:var(--stack-justify-slide-md)] @lg/slide:[justify-content:var(--stack-justify-slide-lg)] @xl/slide:[justify-content:var(--stack-justify-slide-xl)] @2xl/slide:[justify-content:var(--stack-justify-slide-2xl)] @3xl/slide:[justify-content:var(--stack-justify-slide-3xl)] @4xl/slide:[justify-content:var(--stack-justify-slide-4xl)] @5xl/slide:[justify-content:var(--stack-justify-slide-5xl)] @6xl/slide:[justify-content:var(--stack-justify-slide-6xl)] @7xl/slide:[justify-content:var(--stack-justify-slide-7xl)]`;

export const stackWrapClasses = `[flex-wrap:var(--stack-wrap)] xs:[flex-wrap:var(--stack-wrap-xs)] sm:[flex-wrap:var(--stack-wrap-sm)] md:[flex-wrap:var(--stack-wrap-md)] lg:[flex-wrap:var(--stack-wrap-lg)] xl:[flex-wrap:var(--stack-wrap-xl)] 2xl:[flex-wrap:var(--stack-wrap-2xl)] @xs/main:[flex-wrap:var(--stack-wrap-main-xs)] @sm/main:[flex-wrap:var(--stack-wrap-main-sm)] @md/main:[flex-wrap:var(--stack-wrap-main-md)] @lg/main:[flex-wrap:var(--stack-wrap-main-lg)] @xl/main:[flex-wrap:var(--stack-wrap-main-xl)] @2xl/main:[flex-wrap:var(--stack-wrap-main-2xl)] @3xl/main:[flex-wrap:var(--stack-wrap-main-3xl)] @4xl/main:[flex-wrap:var(--stack-wrap-main-4xl)] @5xl/main:[flex-wrap:var(--stack-wrap-main-5xl)] @6xl/main:[flex-wrap:var(--stack-wrap-main-6xl)] @7xl/main:[flex-wrap:var(--stack-wrap-main-7xl)] @xs/slide:[flex-wrap:var(--stack-wrap-slide-xs)] @sm/slide:[flex-wrap:var(--stack-wrap-slide-sm)] @md/slide:[flex-wrap:var(--stack-wrap-slide-md)] @lg/slide:[flex-wrap:var(--stack-wrap-slide-lg)] @xl/slide:[flex-wrap:var(--stack-wrap-slide-xl)] @2xl/slide:[flex-wrap:var(--stack-wrap-slide-2xl)] @3xl/slide:[flex-wrap:var(--stack-wrap-slide-3xl)] @4xl/slide:[flex-wrap:var(--stack-wrap-slide-4xl)] @5xl/slide:[flex-wrap:var(--stack-wrap-slide-5xl)] @6xl/slide:[flex-wrap:var(--stack-wrap-slide-6xl)] @7xl/slide:[flex-wrap:var(--stack-wrap-slide-7xl)]`;

const stackDirectionClassMap = createResponsiveClassMap(stackDirectionClasses);
const stackAlignClassMap = createResponsiveClassMap(stackAlignClasses);
const stackJustifyClassMap = createResponsiveClassMap(stackJustifyClasses);
const stackWrapClassMap = createResponsiveClassMap(stackWrapClasses);

export const getStackAttributes = ({
  direction,
  gap,
  align,
  justify,
  wrap,
}: StackStyleOptions): ResponsiveValueAttributes =>
  mergeResponsiveValueAttributes(
    getResponsiveValueAttributes<StackDirection>(
      direction,
      `stack-direction`,
      (value) => stackDirectionCssValues[value],
      `vertical`,
      stackDirectionClassMap,
    ),
    getStackGapAttributes(gap),
    getResponsiveValueAttributes<StackAlign>(
      align,
      `stack-align`,
      (value) => stackAlignCssValues[value],
      `stretch`,
      stackAlignClassMap,
    ),
    getResponsiveValueAttributes<StackJustify>(
      justify,
      `stack-justify`,
      (value) => stackJustifyCssValues[value],
      `start`,
      stackJustifyClassMap,
    ),
    getResponsiveValueAttributes<StackWrap>(
      wrap,
      `stack-wrap`,
      stackWrapCssValue,
      false,
      stackWrapClassMap,
    ),
  );

export const getStackStyle = (options: StackStyleOptions): CSSVariableProperties =>
  getStackAttributes(options).style;
