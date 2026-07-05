import cx from 'clsx';
import React from 'react';
import type { StackProps } from './stack';
import { getResponsiveSpacingStyle, stackGapClasses } from './spacing';
import { stackAlignClasses, stackJustifyClasses } from './stack';

export interface HStackProps extends StackProps {
  wrap?: boolean;
}

const HStack: React.FC<HStackProps> = ({
  as: Component = `div`,
  gap = 0,
  align = `center`,
  justify = `start`,
  wrap = false,
  className,
  children,
  style,
  ...props
}) => (
  <Component
    {...props}
    style={{ ...getResponsiveSpacingStyle(gap, `stack-gap`), ...style }}
    className={cx(
      `flex flex-row`,
      wrap ? `flex-wrap` : `flex-nowrap`,
      stackGapClasses,
      stackAlignClasses[align],
      stackJustifyClasses[justify],
      className,
    )}
  >
    {children}
  </Component>
);

export default HStack;
