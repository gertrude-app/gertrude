import { createRouter as createTanStackRouter } from '@tanstack/react-router';
import type { QueryClient } from '@tanstack/react-query';
import type { Router } from '@tanstack/react-router';
import { routeTree } from './routeTree.gen';

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
    scrollRestoration: true,
  });
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof createRouter>;
  }
}
