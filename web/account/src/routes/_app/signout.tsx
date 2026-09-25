import { createFileRoute, redirect } from '@tanstack/react-router';
import { clearAuth } from '#/pairql/auth';

export const Route = createFileRoute(`/_app/signout`)({
  beforeLoad: ({ cause, context }) => {
    if (cause === `preload`) return;
    clearAuth();
    sessionStorage.removeItem(`pairingReturnPath`);
    context.queryClient.clear();
    throw redirect({ to: `/login` });
  },
});
