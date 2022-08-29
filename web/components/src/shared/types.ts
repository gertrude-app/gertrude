import type { JSXElementConstructor, ComponentProps } from 'react';

export type Subcomponents<
  T extends keyof JSX.IntrinsicElements | JSXElementConstructor<any>,
> = Array<ComponentProps<T> & { id: string }>;
