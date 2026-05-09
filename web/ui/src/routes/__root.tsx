import { TanStackDevtools } from '@tanstack/react-devtools';
import { Outlet, createRootRoute } from '@tanstack/react-router';
import { TanStackRouterDevtoolsPanel } from '@tanstack/react-router-devtools';
import type React from 'react';

import '../styles.css';

const RootComponent: React.FC = () => (
  <>
    <Outlet />
    <TanStackDevtools
      config={{
        position: `bottom-right`,
      }}
      plugins={[
        {
          name: `TanStack Router`,
          render: <TanStackRouterDevtoolsPanel />,
        },
      ]}
    />
  </>
);

export const Route = createRootRoute({
  component: RootComponent,
});
