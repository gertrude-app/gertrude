import cx from 'clsx';
import React from 'react';
import type { StackProps } from './stack';
import { getResponsiveSpacingStyle, stackGapClasses } from './spacing';
import { stackAlignClasses, stackJustifyClasses } from './stack';

export type VStackProps = StackProps;

const VStack: React.FC<VStackProps> = ({
  as: Component = `div`,
  gap = 0,
  align = `stretch`,
  justify = `start`,
  className,
  children,
  style,
  ...props
}) => (
  <Component
    {...props}
    style={{ ...getResponsiveSpacingStyle(gap, `stack-gap`), ...style }}
    className={cx(
      `flex flex-col`,
      stackGapClasses,
      stackAlignClasses[align],
      stackJustifyClasses[justify],
      className,
    )}
  >
    {children}
  </Component>
);

export default VStack;
