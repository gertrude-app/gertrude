import { Toaster } from '@gertrude/ui';
import { Outlet, createRootRouteWithContext } from '@tanstack/react-router';
import React from 'react';
import type { RouterContext } from '#/router';

export const Route = createRootRouteWithContext<RouterContext>()({
  component: RootComponent,
});

function RootComponent(): React.ReactElement {
  return (
    <>
      <Outlet />
      <Toaster />
    </>
  );
}
