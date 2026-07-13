import cx from 'clsx';
import React from 'react';
import type { PolymorphicComponent, PolymorphicRef } from './polymorphic';
import { type StackOwnProps, type StackProps, getStackAttributes } from './stack-utils';
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
  const stackAttributes = getStackAttributes({ direction, gap, align, justify, wrap });

  return React.createElement(
    Component,
    {
      ...props,
      ref,
      style: {
        ...stackAttributes.style,
        ...style,
      },
      className: cx(
        `flex`,
        stackAttributes.className,
        getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `flex` }),
        className,
      ),
    },
    children,
  );
};

const Stack = StackRender as StackComponent;

export default Stack;
