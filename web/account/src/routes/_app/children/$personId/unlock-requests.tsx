import { createFileRoute, redirect } from '@tanstack/react-router';

export const Route = createFileRoute(`/_app/children/$personId/unlock-requests`)({
  beforeLoad: ({ params }) => {
    throw redirect({ to: `/requests/unlock/$personId`, params });
  },
});
