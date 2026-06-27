import { createFileRoute, redirect } from '@tanstack/react-router';
import { clearAuth } from '#/pairql/auth';

export const Route = createFileRoute(`/_app/signout`)({
  beforeLoad: () => {
    clearAuth();
    throw redirect({ to: `/login` });
  },
});
