import { Link as TanStackLink } from '@tanstack/react-router';
import type React from 'react';
import HStack from '../HStack';
import Stack from '../Stack';

type LinkProps = {
  to: string;
  children?: React.ReactNode;
  className?: string;
};

const Link = (_props: LinkProps): React.ReactElement | null => null;

export const polymorphicTypeExamples = [
  <Stack as="button" type="button" onClick={(event) => event.currentTarget.focus()} />,
  <Stack as={Link} to="/settings" />,
  <HStack as={Link} to="/people" gap={2} />,
  <Stack as={TanStackLink} to="/settings" />,
  // @ts-expect-error custom component required props are preserved
  <Stack as={Link} />,
  // @ts-expect-error tanstack link destinations stay required
  <Stack as={TanStackLink} />,
  // @ts-expect-error intrinsic props are tied to the selected element
  <Stack as="button" href="/settings" />,
];
