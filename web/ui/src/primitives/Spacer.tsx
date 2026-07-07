import cx from 'clsx';
import React from 'react';
import type {
  PolymorphicComponent,
  PolymorphicProps,
  PolymorphicRef,
} from './polymorphic';
import type { VisibilityProps } from './visibility';
import { getVisibilityClasses } from './visibility';

type SpacerAriaProps = {
  [`aria-hidden`]?: React.AriaAttributes[`aria-hidden`];
};

export interface SpacerOwnProps extends VisibilityProps {
  children?: never;
  className?: string;
  style?: React.CSSProperties;
}

export type SpacerProps<Element extends React.ElementType = `div`> = PolymorphicProps<
  Element,
  SpacerOwnProps
>;

type SpacerComponent = PolymorphicComponent<`div`, SpacerOwnProps>;

const SpacerRender = <Element extends React.ElementType = `div`>({
  as,
  className,
  hideBelow,
  hideAbove,
  ref,
  ...props
}: SpacerProps<Element> & {
  ref?: PolymorphicRef<Element>;
}): React.ReactElement => {
  const Component = as ?? `div`;
  const ariaProps = props as SpacerAriaProps;

  return React.createElement(Component, {
    ...props,
    ref,
    'aria-hidden': ariaProps[`aria-hidden`] ?? true,
    className: cx(
      `min-h-0 min-w-0 flex-grow`,
      getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `block` }),
      className,
    ),
  });
};

const Spacer = SpacerRender as SpacerComponent;

export default Spacer;
