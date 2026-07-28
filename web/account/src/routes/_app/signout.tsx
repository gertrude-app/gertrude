import { createFileRoute, redirect } from '@tanstack/react-router';
import { clearAuth } from '#/pairql/auth';

export const Route = createFileRoute(`/_app/signout`)({
  beforeLoad: ({ context }) => {
    clearAuth();
    context.queryClient.clear();
    throw redirect({ to: `/login` });
  },
});
