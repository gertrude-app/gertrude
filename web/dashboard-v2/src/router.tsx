import {
  type Router,
  createRouter as createTanStackRouter,
} from '@tanstack/react-router';
import { routeTree } from './routeTree.gen';

export function getRouter(): Router<typeof routeTree> {
  const router = createTanStackRouter({
    routeTree,
    scrollRestoration: true,
    defaultPreload: `intent`,
    defaultPreloadStaleTime: 0,
  });

  return router;
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof getRouter>;
  }
}
