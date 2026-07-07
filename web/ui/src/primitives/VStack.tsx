import React from 'react';
import type {
  PolymorphicComponent,
  PolymorphicProps,
  PolymorphicRef,
} from './polymorphic';
import type { StackOwnProps } from './stack-utils';
import Stack from './Stack';

export type VStackOwnProps = Omit<StackOwnProps, `direction` | `wrap`>;
export type VStackProps<Element extends React.ElementType = `div`> = PolymorphicProps<
  Element,
  VStackOwnProps
>;

type VStackComponent = PolymorphicComponent<`div`, VStackOwnProps>;

const VStackRender = <Element extends React.ElementType = `div`>({
  align = `stretch`,
  ref,
  ...props
}: VStackProps<Element> & {
  ref?: PolymorphicRef<Element>;
}): React.ReactElement =>
  React.createElement(Stack as React.ElementType, {
    ...props,
    ref,
    direction: `vertical`,
    align,
  });

const VStack = VStackRender as VStackComponent;

export default VStack;
