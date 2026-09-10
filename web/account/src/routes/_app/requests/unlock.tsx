import { Outlet, createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute(`/_app/requests/unlock`)({
  component: Outlet,
});
