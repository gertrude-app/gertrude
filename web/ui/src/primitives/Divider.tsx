import cx from 'clsx';
import React from 'react';
import type {
  PolymorphicComponent,
  PolymorphicProps,
  PolymorphicRef,
} from './polymorphic';
import type { VisibilityProps } from './visibility';
import { getVisibilityClasses } from './visibility';

export type DividerOrientation = `horizontal` | `vertical`;

type DividerAriaProps = {
  [`aria-hidden`]?: React.AriaAttributes[`aria-hidden`];
};

export interface DividerOwnProps extends VisibilityProps {
  children?: never;
  orientation?: DividerOrientation;
  className?: string;
  style?: React.CSSProperties;
}

export type DividerProps<Element extends React.ElementType = `div`> = PolymorphicProps<
  Element,
  DividerOwnProps
>;

type DividerComponent = PolymorphicComponent<`div`, DividerOwnProps>;

const DividerRender = <Element extends React.ElementType = `div`>({
  as,
  orientation = `horizontal`,
  className,
  hideBelow,
  hideAbove,
  ref,
  ...props
}: DividerProps<Element> & { ref?: PolymorphicRef<Element> }): React.ReactElement => {
  const Component = as ?? `div`;
  const ariaProps = props as DividerAriaProps;

  return React.createElement(Component, {
    ...props,
    ref,
    'aria-hidden': ariaProps[`aria-hidden`] ?? true,
    className: cx(
      `shrink-0 bg-stone-200`,
      orientation === `horizontal` ? `h-px w-full` : `w-px self-stretch`,
      getVisibilityClasses({ hideBelow, hideAbove, restoreDisplay: `block` }),
      className,
    ),
  });
};

const Divider = DividerRender as DividerComponent;

export default Divider;
