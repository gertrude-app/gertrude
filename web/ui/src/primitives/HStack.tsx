import React from 'react';
import type {
  PolymorphicComponent,
  PolymorphicProps,
  PolymorphicRef,
} from './polymorphic';
import type { StackOwnProps } from './stack-utils';
import Stack from './Stack';

export type HStackOwnProps = Omit<StackOwnProps, `direction`>;
export type HStackProps<Element extends React.ElementType = `div`> = PolymorphicProps<
  Element,
  HStackOwnProps
>;

type HStackComponent = PolymorphicComponent<`div`, HStackOwnProps>;

const HStackRender = <Element extends React.ElementType = `div`>({
  align = `center`,
  ref,
  ...props
}: HStackProps<Element> & {
  ref?: PolymorphicRef<Element>;
}): React.ReactElement =>
  React.createElement(Stack as React.ElementType, {
    ...props,
    ref,
    direction: `horizontal`,
    align,
  });

const HStack = HStackRender as HStackComponent;

export default HStack;
