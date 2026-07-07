import cx from 'clsx';
import React from 'react';
import type { PolymorphicComponent, PolymorphicRef } from './polymorphic';
import { stackGapClasses } from './spacing';
import {
  type StackOwnProps,
  type StackProps,
  getStackStyle,
  stackAlignClasses,
  stackDirectionClasses,
  stackJustifyClasses,
  stackWrapClasses,
} from './stack-utils';
import { getVisibilityClasses } from './visibility';

type StackComponent = PolymorphicComponent<`div`, StackOwnProps>;

const StackRender = <Element extends React.ElementType = `div`>({
  as,
  direction = `vertical`,
  gap = 0,
  align = `stretch`,
  justify = `start`,
  wrap = false,
  className,
  children,
  style,
  hideBelow,
  hideAbove,
  ref,
  ...props
}: StackProps<Element> & { ref?: PolymorphicRef<Element> }): React.ReactElement => {
  const Component = as ?? `div`;

  return React.createElement(
    Component,
    {
      ...props,
      ref,
      style: {
        ...getStackStyle({ direction, gap, align, justify, wrap }),
        ...style,
      },
      className: cx(
        `flex`,
        stackDirectionClasses,
        stackGapClasses,
        stackAlignClasses,
        stackJustifyClasses,
        stackWrapClasses,
        getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `flex` }),
        className,
      ),
    },
    children,
  );
};

const Stack = StackRender as StackComponent;

export default Stack;
