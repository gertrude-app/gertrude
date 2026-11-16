import { createRouter as createTanStackRouter } from '@tanstack/react-router';
import React from 'react';
import type { QueryClient } from '@tanstack/react-query';
import type { Router } from '@tanstack/react-router';
import ErrorPage from './components/pages/ErrorPage';
import { routeTree } from './routeTree.gen';

const DefaultErrorComponent: React.FC = () => (
  <ErrorPage accountHref="/people" onReload={() => window.location.reload()} />
);

export interface RouterContext {
  queryClient: QueryClient;
}

export function createRouter(queryClient: QueryClient): Router<typeof routeTree> {
  return createTanStackRouter({
    routeTree,
    context: { queryClient },
    defaultPreload: `intent`,
    defaultPreloadStaleTime: 0,
    notFoundMode: `root`,
    defaultErrorComponent: DefaultErrorComponent,
    scrollRestoration: true,
  });
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof createRouter>;
  }
}
