import { Toaster } from '@gertrude/ui';
import { Outlet, createRootRouteWithContext } from '@tanstack/react-router';
import React from 'react';
import type { RouterContext } from '#/router';
import NotFoundPage from '#/components/pages/NotFoundPage';

const NotFoundComponent: React.FC = () => <NotFoundPage accountHref="/people" />;

export const Route = createRootRouteWithContext<RouterContext>()({
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
});

function RootComponent(): React.ReactElement {
  return (
    <>
      <Outlet />
      <Toaster />
    </>
  );
}
